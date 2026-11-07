import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/interceptors/client_key_interceptor.dart';
import 'package:mohandis/core/api/interceptors/device_header_interceptor.dart';
import 'package:mohandis/core/api/token_refresher.dart';
import 'package:mohandis/core/config/app_config.dart';
import 'package:mohandis/core/services/device_info_service.dart';
import 'package:mohandis/core/storage/token_storage.dart';

import '../domain/entities/auth_session.dart';
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
/// **The backend ROTATES the refresh token.** `PUT Auth/Refresh-Token` marks
/// the presented value used and hands back a new one, so the pair must be
/// persisted before anything else runs, and two refreshes must never race —
/// the loser would present a value that no longer exists and be told
/// "Refresh Token not found", which reads exactly like a dead session.
/// `AuthInterceptor` single-flights for that reason.
///
/// "Bare" means no auth interceptor — not no headers. This call has to look
/// like every other request from this device, or the server cannot do its
/// part of the job; see the constructor.
class AuthTokenRefresher implements TokenRefresher {
  AuthTokenRefresher({
    required AppConfig config,
    required String refreshPath,
    required TokenStorage tokenStorage,
    required DeviceInfoService deviceInfo,
    Dio? dio,
  }) : _refreshPath = refreshPath,
       _tokens = tokenStorage,
       _dio = dio ?? _build(config, deviceInfo);

  static Dio _build(AppConfig config, DeviceInfoService deviceInfo) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // The dev API's self-signed certificate. Without this the refresh failed
    // its TLS handshake on every attempt against localhost — and the old
    // code called that "refresh failed" and signed the person out. On the
    // dev flavour an expired access token was a guaranteed logout.
    final adapter = loopbackDevAdapter(config);
    if (adapter != null) dio.httpClientAdapter = adapter;

    dio.interceptors.addAll([
      // X-KEY: the backend rejects any request without it, refresh included.
      ClientKeyInterceptor(),
      // X-Device-SN and friends. The server's refresh checks whether THIS
      // device was released or revoked — that is the whole mechanism behind
      // "remove device" on the devices screen — and it identifies the device
      // by this header. Without it the check short-circuits to "no device,
      // nothing to enforce", and a removed device could go on refreshing
      // indefinitely.
      DeviceHeaderInterceptor(config: config, deviceInfo: deviceInfo),
    ]);
    return dio;
  }

  final String _refreshPath;
  final TokenStorage _tokens;
  final Dio _dio;

  /// Refreshes in a row that got an ANSWER, but not a verdict — a 500, a
  /// 400, a rate limit. Reset by any success or any definite refusal.
  ///
  /// These are held as [RefreshOutcome.unavailable] so one bad moment on the
  /// server does not sign anybody out. But a server that answers 500 to every
  /// refresh is not having a bad moment, and treating it as a blip forever is
  /// the stuck-in-the-shell bug by another route: every request 401s, every
  /// refresh fails, and the person is never told. After this many, the answer
  /// is taken as a refusal. Requests that never reached the server — no
  /// connection, a timeout — never count: those really are the network.
  int _answeredFailures = 0;
  static const _answeredFailureLimit = 3;

  /// The last answer that was not a success, kept so a refusal can report it.
  /// See [TokenRefresher.lastRefusal].
  String? _lastAnswer;

  @override
  String? lastRefusal;

  RefreshOutcome _refuse(String why) {
    lastRefusal = why;
    return RefreshOutcome.rejected;
  }

  @override
  Future<RefreshOutcome> refresh() async {
    try {
      return await _attempt();
    } catch (_) {
      // Storage threw — the keychain refuses reads while the device is
      // locked, which is when background refreshes tend to fire. Nothing
      // about that says the session is dead.
      return RefreshOutcome.unavailable;
    }
  }

  Future<RefreshOutcome> _attempt() async {
    final stored = await _tokens.readRefreshToken();
    if (stored == null || stored.isEmpty) {
      // Signs out without ever reaching the network, so it leaves no trace in
      // any HTTP log — and it means login never stored a refresh token, not
      // that the server refused one.
      if (kDebugMode) debugPrint('[refresh] no refresh token in storage');
      return _refuse('no refresh token in storage — login never saved one');
    }

    // Bail early if the refresh token itself is already expired — no point
    // hitting the network only to be refused. (This backend does not send an
    // expiry today, so this only fires if a future one does.)
    final exp = await _tokens.readRefreshTokenExpiresAt();
    if (exp != null && DateTime.now().toUtc().isAfter(exp.toUtc())) {
      return _refuse('stored refresh token expired at ${exp.toUtc()}');
    }

    final Response<Map<String, dynamic>> res;
    try {
      // PUT with the token in the QUERY STRING — the endpoint signature is
      // `RefreshToken(string refreshToken)` with no [FromBody], so a JSON body
      // binds to nothing and the server answers 404 "Refresh Token not found".
      res = await _dio.put<Map<String, dynamic>>(
        _refreshPath,
        queryParameters: {'refreshToken': stored},
        options: Options(headers: await _tenantHeader()),
      );
    } on DioException catch (e) {
      _log(e);
      _lastAnswer = _describe(e);
      return _classify(e);
    }

    final AuthSession session;
    try {
      session = MobileAuthResultDto.fromJson(res.data ?? const {}).toDomain();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[refresh] 200 but undecodable · ${res.data}');
      }
      _lastAnswer = '200 but undecodable';
      return _answeredWithoutVerdict();
    }
    // No ACCESS token is a server fault — there is nothing to retry the
    // request with, so the refresh achieved nothing.
    if (session.accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('[refresh] 200 without an access token · keys=${res.data?.keys}');
      }
      _lastAnswer = '200 without an access token · keys=${res.data?.keys}';
      return _answeredWithoutVerdict();
    }

    // **A missing REFRESH token is not a failure.** The backend rotates, so
    // the normal reply carries a new one — but a reply that omits it means
    // "carry on with what you have", and the stored value is still the only
    // credential this device owns. Treating it as a fault was worse than
    // useless: three of them in a row is a forced sign-out, and this path
    // produces them in a row by construction, because every refresh after the
    // first hits the same server behaviour. Overwriting the stored value with
    // the empty string would be worse still — the next refresh would have
    // nothing to present and would sign the person out with no request sent.
    final rotated = session.refreshToken.isNotEmpty;
    if (!rotated && kDebugMode) {
      debugPrint('[refresh] 200 with no new refresh token · keeping the stored one');
    }

    // **Nothing is written if the stored token moved while this was in
    // flight.** A sign-out that landed meanwhile has already cleared storage,
    // and writing here would put a working session back on a device the
    // person just signed out of.
    final current = await _tokens.readRefreshToken();
    if (current != stored) {
      if (kDebugMode) {
        debugPrint('[refresh] dropped: storage changed mid-flight');
      }
      return RefreshOutcome.unavailable;
    }

    // Persisted BEFORE returning: the value just presented is already spent
    // server-side, so this pair is now the only one that works.
    await _tokens.saveSession(
      accessToken: session.accessToken,
      // Null, not empty: `TokenStorage` leaves a null field alone, which is
      // precisely "keep the one that still works".
      refreshToken: rotated ? session.refreshToken : null,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      refreshTokenExpiresAt: session.refreshTokenExpiresAt,
      // Refresh may not re-issue user profile fields. Pass null so
      // TokenStorage leaves previously-stored values untouched.
      userId: session.user.id.isNotEmpty ? session.user.id : null,
      userName: session.user.userName,
      displayName: session.user.name.isNotEmpty ? session.user.name : null,
    );
    _answeredFailures = 0;
    lastRefusal = null;
    return RefreshOutcome.refreshed;
  }

  /// Prints what the refresh endpoint actually said, in a debug build.
  ///
  /// **Nothing else on this path speaks.** The main `ApiClient` carries a
  /// `LogInterceptor`; this refresher deliberately runs on a bare Dio of its
  /// own — see the class comment — and that Dio had no logger, so a refusal
  /// here has always been silent. The only visible consequence was the person
  /// landing back on the login screen, which looks identical whichever of the
  /// server's refusals produced it.
  ///
  /// The server distinguishes several, and they are different problems with
  /// different fixes: `Refresh Token not found.`, `Refresh Token is expired.`,
  /// `User not found.`, `User Unauthorized`, and — added after the version
  /// this client was written against — `device_revoked` and `session_revoked`,
  /// which mean this install is no longer a device the account trusts rather
  /// than anything being wrong with the token.
  static void _log(DioException e) {
    if (!kDebugMode) return;
    final status = e.response?.statusCode;
    final body = '${e.response?.data ?? ''}';
    debugPrint(
      '[refresh] ${e.requestOptions.method} ${e.requestOptions.uri.path}'
      ' · ${status ?? e.type.name}'
      '${body.isEmpty ? '' : ' · ${body.length > 240 ? body.substring(0, 240) : body}'}',
    );
  }

  /// Did the server refuse, or did we never hear from it?
  ///
  /// Only the refresh endpoint's own refusals end the session, and it has
  /// exactly two: 404 "Refresh Token not found" / "User not found", and 401
  /// for an expired token, a locked-out user or a revoked device. Every other
  /// status is NOT a verdict on the session — 408 and 429 are the network and
  /// a rate limiter, and a 403 or 407 on a phone is usually a captive portal
  /// or a proxy — so treating the whole 4xx range as "signed out" would log
  /// people out for connecting to hotel wi-fi.
  RefreshOutcome _classify(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 404) {
      _answeredFailures = 0;
      return _refuse(_describe(e));
    }
    // No response at all: never reached the server. Does not count.
    if (status == null) return RefreshOutcome.unavailable;
    return _answeredWithoutVerdict();
  }

  /// See [_answeredFailures].
  RefreshOutcome _answeredWithoutVerdict() {
    _answeredFailures += 1;
    if (_answeredFailures >= _answeredFailureLimit) {
      _answeredFailures = 0;
      // Not a refusal the server made — three answers that were not a verdict
      // either way, taken as one. Said so, with the last of them attached,
      // because "the server kept failing" is a server bug and must not read
      // like "your session ended".
      return _refuse(
        '$_answeredFailureLimit refreshes in a row answered without tokens'
        ' — last: ${_lastAnswer ?? 'unknown'}',
      );
    }
    return RefreshOutcome.unavailable;
  }

  /// One line for [lastRefusal]: method, path, status and the body.
  static String _describe(DioException e) {
    final status = e.response?.statusCode;
    final body = '${e.response?.data ?? ''}';
    return '${e.requestOptions.method} ${e.requestOptions.uri.path}'
        ' · ${status ?? e.type.name}'
        '${body.isEmpty ? '' : ' · ${body.length > 240 ? body.substring(0, 240) : body}'}';
  }

  /// `X-Tenant-Id`, taken from the session being refreshed.
  ///
  /// This call is anonymous — no bearer — so the server has no tenant claim
  /// to read, and the refresh loads the user WITH their contact, which is a
  /// tenant-scoped row, and mints the new token's own `TenantId` claim from
  /// that contact. Whether an unscoped request can see the contact at all is
  /// up to the Kernel's query filter; sending the tenant takes the question
  /// off the table.
  ///
  /// Read from the old access token's `TenantId` claim rather than from the
  /// deployment's `/health`: this is the tenant this particular account lives
  /// in, which is the one that matters. Decoding the payload is safe here —
  /// nothing is trusted from it; it only chooses a header the server checks.
  Future<Map<String, dynamic>?> _tenantHeader() async {
    final token = await _tokens.readAccessToken();
    final tenant = _tenantClaim(token);
    return tenant == null ? null : {'X-Tenant-Id': tenant};
  }

  static int? _tenantClaim(String? jwt) {
    if (jwt == null) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      if (claims is! Map) return null;
      final raw = claims['TenantId'];
      final id = raw is num ? raw.toInt() : int.tryParse('$raw');
      // Same rule as TenantNotifier: zero is not a tenant.
      return (id != null && id > 0) ? id : null;
    } catch (_) {
      return null;
    }
  }
}
