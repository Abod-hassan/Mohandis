import 'package:dio/dio.dart';

import 'package:flutter_mobile_template/core/api/interceptors/client_key_interceptor.dart';
import 'package:flutter_mobile_template/core/api/token_refresher.dart';
import 'package:flutter_mobile_template/core/storage/token_storage.dart';

import 'dtos/mobile_auth_result_dto.dart';

/// Concrete [TokenRefresher] for the mobile auth flow.
///
/// **Why a bare Dio instead of going through `AuthRepository`:** the main
/// `ApiClient` depends on this refresher via `tokenRefresherProvider`. If
/// the refresher then talked through the main `ApiClient`, we'd have
/// `apiClient → tokenRefresher → authRepository → apiClient` — a
/// Riverpod circular dependency. The bare Dio owns its own pipeline (no
/// `AuthInterceptor` — important so a 401 inside refresh doesn't recurse).
///
/// This backend does NOT rotate the refresh token — `Refresh-Token` re-mints
/// the access token and echoes the same refresh value back. The pair is
/// persisted either way via [TokenStorage], so the next outgoing request picks
/// it up through [AuthInterceptor].
class AuthTokenRefresher implements TokenRefresher {
  AuthTokenRefresher({
    required String baseUrl,
    required String refreshPath,
    required TokenStorage tokenStorage,
    Dio? dio,
  })  : _refreshPath = refreshPath,
        _tokens = tokenStorage,
        _dio = dio ??
            (Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                contentType: 'application/json',
                responseType: ResponseType.json,
              ),
            )
              // The bare Dio skips AuthInterceptor to avoid recursion,
              // but it MUST still carry X-KEY — the backend rejects any
              // request without it, including unauthenticated refresh
              // calls. RequestSigning isn't added here because the
              // per-device secret is bootstrap-provisioned via the main
              // ApiClient pipeline; refresh paths fall in the
              // unauthenticatedPaths set, and the backend treats
              // missing X-Request-Key on those paths as acceptable.
              ..interceptors.add(ClientKeyInterceptor()));

  final String _refreshPath;
  final TokenStorage _tokens;
  final Dio _dio;

  @override
  Future<bool> refresh() async {
    final stored = await _tokens.readRefreshToken();
    if (stored == null || stored.isEmpty) return false;

    // Bail early if the refresh token itself is already expired — no
    // point hitting the network only to receive a 401.
    final exp = await _tokens.readRefreshTokenExpiresAt();
    if (exp != null && DateTime.now().toUtc().isAfter(exp.toUtc())) {
      await _tokens.clear();
      return false;
    }

    try {
      // PUT with the token in the QUERY STRING — the endpoint signature is
      // `RefreshToken(string refreshToken)` with no [FromBody], so a JSON body
      // binds to nothing and the server answers 404 "Refresh Token not found".
      final res = await _dio.put<Map<String, dynamic>>(
        _refreshPath,
        queryParameters: {'refreshToken': stored},
      );
      final session =
          MobileAuthResultDto.fromJson(res.data ?? const {}).toDomain();
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        return false;
      }
      await _tokens.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        accessTokenExpiresAt: session.accessTokenExpiresAt,
        refreshTokenExpiresAt: session.refreshTokenExpiresAt,
        // Refresh may not re-issue user profile fields. Pass null so
        // TokenStorage leaves previously-stored values untouched.
        userId: session.user.id.isNotEmpty ? session.user.id : null,
        userName: session.user.userName,
        displayName:
            session.user.name.isNotEmpty ? session.user.name : null,
      );
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
