import 'dart:convert';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/storage/token_storage.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/registration.dart';
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
  Future<Result<AuthSession, AppException>> createWithContact({
    required String registrationToken,
    required String fullName,
    required String userName,
    String? phone,
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
  Future<Result<void, AppException>> deleteAccount() async {
    await _wait();
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> logout({
    String? refreshToken,
    String? accessToken,
  }) async {
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

  /// Identifiers the mock backend pretends are already registered, so the
  /// sign-up form's "taken" state can be seen without a server.
  static const _takenUserNames = {'obeida', 'admin', 'test'};
  static const _takenPhoneTails = {'7701827031'};
  static const _takenEmails = {'taken@example.com'};

  /// The code the mock accepts from either channel.
  static const _mockCode = '123456';

  @override
  Future<Result<IdentityAvailability, AppException>> checkIdentity({
    String? userName,
    String? phone,
    String? email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return Result.success(
      IdentityAvailability(
        userNameTaken:
            userName != null &&
            _takenUserNames.contains(userName.trim().toLowerCase()),
        phoneTaken:
            digits.isNotEmpty && _takenPhoneTails.any(digits.endsWith),
        emailTaken:
            email != null && _takenEmails.contains(email.trim().toLowerCase()),
      ),
    );
  }

  @override
  Future<Result<void, AppException>> sendPhoneCode(
    String phone, {
    bool isSms = false,
  }) async {
    await Future<void>.delayed(latency);
    return const Result.success(null);
  }

  @override
  Future<Result<VerificationOutcome, AppException>> verifyPhoneCode({
    required String phone,
    required String otp,
  }) => _verifyMock(otp);

  @override
  Future<Result<void, AppException>> sendEmailCode(String email) async {
    await Future<void>.delayed(latency);
    return const Result.success(null);
  }

  @override
  Future<Result<VerificationOutcome, AppException>> verifyEmailCode({
    required String email,
    required String code,
  }) => _verifyMock(code, email: email);

  @override
  Future<Result<void, AppException>> confirmEmail({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(latency);
    if (code.trim() != _mockCode) {
      return const Result.failure(UnauthorizedException('email_code_invalid'));
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> resetPassword({
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    return const Result.success(null);
  }

  /// Always a registration token — the mock's purpose is exercising the
  /// sign-up path, and a session here would skip the screens under test.
  Future<Result<VerificationOutcome, AppException>> _verifyMock(
    String code, {
    String? email,
  }) async {
    await Future<void>.delayed(latency);
    if (code.trim() != _mockCode) {
      // Exactly what OTPService returns. It used to say `invalid_otp` here to
      // match a client rule that had the words the wrong way round — which
      // made the mock the only place the bug could not be seen.
      return const Result.failure(UnauthorizedException('otp_invalid'));
    }
    return Result.success(
      RegistrationToken(token: 'mock-registration-token', email: email),
    );
  }
}
