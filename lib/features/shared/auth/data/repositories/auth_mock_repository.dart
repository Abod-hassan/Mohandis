import 'dart:convert';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/storage/token_storage.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock auth for demo builds. Issues a local session and persists tokens
/// through the real [TokenStorage] so the cold-start hydration path, the
/// router redirect, and logout all behave exactly as they will in production.
class AuthMockRepository implements AuthRepository {
  AuthMockRepository({
    required TokenStorage tokenStorage,
    this.latency = const Duration(milliseconds: 400),
  }) : _tokens = tokenStorage;

  final TokenStorage _tokens;
  final Duration latency;

  static const _user = User(
    id: 'me',
    name: 'يوسف الحربي',
    userName: '+966500000000',
  );

  Future<void> _wait() => Future<void>.delayed(latency);

  /// A structurally valid (but unsigned) JWT.
  ///
  /// Cold start rejects any stored access token that isn't a readable JWT —
  /// that check is what stops a demo build's leftover token from being
  /// mistaken for a real session against the live API. A mock token therefore
  /// has to look like one, or demo builds would sign themselves out on every
  /// restart.
  static String _mockJwt() {
    String segment(Map<String, dynamic> claims) => base64Url
        .encode(utf8.encode(jsonEncode(claims)))
        .replaceAll('=', '');

    final exp =
        DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
        1000;
    return '${segment({'alg': 'none', 'typ': 'JWT'})}'
        '.${segment({'sub': 'me', 'exp': exp})}'
        '.mock-signature';
  }

  AuthSession _session() => AuthSession(
        user: _user,
        accessToken: _mockJwt(),
        refreshToken: 'mock-refresh-token',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 12)),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<Result<AuthSession, AppException>> login({
    required String userName,
    required String password,
  }) async {
    await _wait();
    final session = _session();
    await _persist(session);
    return Result.success(session);
  }

  @override
  Future<Result<AuthSession, AppException>> register({
    required String fullName,
    required String userName,
    required String phone,
    required String password,
    required AccountType accountType,
    required Gender? gender,
    String? imageUrl,
  }) async {
    await _wait();
    // Mirrors the real flow's outcome: registration ends signed in.
    final session = AuthSession(
      user: User(id: 'me', name: fullName, userName: userName),
      accessToken: _mockJwt(),
      refreshToken: 'mock-refresh-token',
      accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 12)),
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    await _persist(session);
    return Result.success(session);
  }

  @override
  Future<Result<AuthSession, AppException>> refresh({
    required String refreshToken,
  }) async {
    await _wait();
    final session = _session();
    await _persist(session);
    return Result.success(session);
  }

  @override
  Future<Result<AuthSession, AppException>> currentSession() async {
    await _wait();
    final access = await _tokens.readAccessToken();
    if (access == null || access.isEmpty) {
      return const Result.failure(UnauthorizedException('لا توجد جلسة محفوظة'));
    }
    return Result.success(_session());
  }

  @override
  Future<Result<void, AppException>> logout({String? refreshToken}) async {
    await _wait();
    await _tokens.clear();
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> ensureSigningSecret() async =>
      const Result.success(null);

  Future<void> _persist(AuthSession session) async {
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      refreshTokenExpiresAt: session.refreshTokenExpiresAt,
      userId: session.user.id,
      userName: session.user.userName,
      displayName: session.user.name,
    );
  }
}
