import 'package:dio/dio.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/storage/token_storage.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';
import 'package:flutter_mobile_template/features/profile/domain/repositories/profile_repository.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dtos/mobile_auth_result_dto.dart';

/// Auth against the RoboByte.Auth module.
///
/// Its conventions differ from the social module's on every axis, and each
/// difference is load-bearing here: routes live under `api/Auth` with no
/// module prefix, the responses are bare DTOs rather than `ResultViewModel`
/// envelopes, refresh is a PUT with a query parameter, and logout takes form
/// data.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required ProfileRepository profileRepository,
    required Future<int?> Function() resolveTenantId,
  }) : _api = apiClient,
       _tokens = tokenStorage,
       _profiles = profileRepository,
       _resolveTenantId = resolveTenantId;

  final ApiClient _api;
  final TokenStorage _tokens;

  /// Resolved — and awaited — at call time.
  ///
  /// The auth screen warms this up as it opens, so it is normally already
  /// there; awaiting closes the gap when it isn't, which is otherwise a
  /// request with no tenant and a flat server-side refusal to write.
  final Future<int?> Function() _resolveTenantId;

  /// Only used to stamp the account type after sign-up — that field lives on
  /// the social profile, not on the auth contact.
  final ProfileRepository _profiles;

  /// Stamps the tenant on an anonymous request.
  ///
  /// Only these: sign-up and login happen before a JWT exists, and Kernel
  /// `StrictTenantWrites` refuses a write with no tenant in scope. After
  /// login the claim carries it, and a header would override the claim.
  Future<Options?> _tenantHeader() async {
    final tenant = await _resolveTenantId();
    if (tenant == null) return null;
    return Options(headers: {'X-Tenant-Id': tenant});
  }

  @override
  Future<Result<AuthSession, AppException>> login({
    required String userName,
    required String password,
  }) async {
    final options = await _tenantHeader();
    final result = await apiCall(
      EndPoints.authLogin,
      () => _api.dio.post<dynamic>(
        EndPoints.authLogin,
        data: {'userName': userName, 'password': password},
        options: options,
      ),
      (envelope) => MobileAuthResultDto.fromJson(envelope.object).toDomain(),
    );

    return result.flatMapAsync((session) async {
      if (session.accessToken.isEmpty) {
        return const Result.failure(
          UnauthorizedException('لم يُصدر الخادم رمز دخول'),
        );
      }
      await _persist(session);
      return Result.success(session);
    });
  }

  /// Creates the account and signs into it.
  ///
  /// Prefers `POST /api/Auth/SignUp`, which does the whole thing in one
  /// server-side transaction and hands back tokens. That endpoint was added
  /// to the Auth module after the 1.11.1 package, so a host still running the
  /// older build answers 404 — and this falls back to the three-call sequence
  /// it replaced. **Delete [_registerInSteps] once every environment is on the
  /// newer Auth**: it is the path that can strand a contact with no login
  /// behind it, which is the whole reason the endpoint exists.
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
    final session =
        await _signUpInOneCall(
          fullName: fullName,
          userName: userName,
          phone: phone,
          password: password,
          gender: gender,
          imageUrl: imageUrl,
        ) ??
        await _registerInSteps(
          fullName: fullName,
          userName: userName,
          phone: phone,
          password: password,
          gender: gender,
          imageUrl: imageUrl,
        );

    // The account type lives on the social profile, not on the auth contact,
    // so it is stamped once the session exists. Deliberately not allowed to
    // fail the registration: the account is created and the person is signed
    // in, and this is one editable field they can fix later.
    if (session.isSuccess) {
      await _profiles.updateMe({'accountType': accountType});
    }
    return session;
  }

  /// The one-call path. Returns null — and only null — when the endpoint is
  /// absent, so the caller knows to fall back rather than reporting a failure.
  Future<Result<AuthSession, AppException>?> _signUpInOneCall({
    required String fullName,
    required String userName,
    required String phone,
    required String password,
    required Gender? gender,
    String? imageUrl,
  }) async {
    try {
      final options = await _tenantHeader();
      final res = await _api.dio.post<dynamic>(
        EndPoints.authSignUp,
        data: {
          'name': fullName,
          'userName': userName,
          'password': password,
          'phone': phone,
          // By NAME, never the ordinal: the Kernel's GenderEnum leads with
          // `Unspecified`, so ordinals shifted when it moved out of Auth.
          // Omitted, not sent as an empty string: the contact form takes
          // gender as optional, and a company has none to state.
          if (gender != null) 'gender': gender.wireName,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        options: options,
      );

      final envelope = ApiEnvelope.from(res.data);
      final session = MobileAuthResultDto.fromJson(envelope.object).toDomain();
      if (session.accessToken.isEmpty) {
        return const Result.failure(
          UnknownException('لم يُصدر الخادم رمز دخول بعد إنشاء الحساب'),
        );
      }
      await _persist(session);
      return Result.success(session);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 404/405 mean this build of the Auth module doesn't have the endpoint.
      // Anything else is a real answer — a taken username, a rejected
      // password — and must reach the user rather than triggering a retry
      // through the old path, which would then create a duplicate contact.
      if (status == 404 || status == 405) return null;
      return Result.failure(apiException(e, EndPoints.authSignUp));
    }
  }

  /// Legacy three-call path: contact, then user, then login.
  ///
  /// Registration issues no tokens of its own here, hence the third call. If
  /// the second step fails the contact from the first is already committed and
  /// orphaned — there is no endpoint to undo it, which is exactly what
  /// `SignUp` fixes server-side.
  Future<Result<AuthSession, AppException>> _registerInSteps({
    required String fullName,
    required String userName,
    required String phone,
    required String password,
    required Gender? gender,
    String? imageUrl,
  }) async {
    final options = await _tenantHeader();

    final contact = await apiCall(
      EndPoints.contacts,
      () => _api.dio.post<dynamic>(
        EndPoints.contacts,
        data: {
          'name': fullName,
          'phone': phone,
          'address': '',
          'secondaryPhone': '',
          // Identity's permission role, not the kind of account — everyone
          // registering from the app is a plain user.
          'userType': 'User',
          // Omitted, not sent as an empty string: the contact form takes
          // gender as optional, and a company has none to state.
          if (gender != null) 'gender': gender.wireName,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        options: options,
      ),
      // This one IS enveloped: `ResultViewModel<Guid>` with the new id.
      (envelope) => '${envelope.data ?? ''}',
    );

    if (contact.isFailure) return Result.failure(contact.errorOrNull!);
    final contactId = contact.valueOrNull!;
    if (contactId.isEmpty) {
      return const Result.failure(
        UnknownException('لم يُنشئ الخادم سجل جهة الاتصال'),
      );
    }

    final created = await apiCall(
      EndPoints.authRegister,
      () => _api.dio.post<dynamic>(
        EndPoints.authRegister,
        data: {
          'userName': userName,
          'password': password,
          'contactId': contactId,
        },
        options: options,
      ),
      (_) {},
    );

    if (created.isFailure) return Result.failure(created.errorOrNull!);

    return login(userName: userName, password: password);
  }

  @override
  Future<Result<AuthSession, AppException>> refresh({
    required String refreshToken,
  }) async {
    final result = await apiCall(
      EndPoints.authRefresh,
      // PUT, and the token rides in the query string — not the body.
      () => _api.dio.put<dynamic>(
        EndPoints.authRefresh,
        queryParameters: {'refreshToken': refreshToken},
      ),
      (envelope) => MobileAuthResultDto.fromJson(envelope.object).toDomain(),
    );

    return result.flatMapAsync((session) async {
      if (session.accessToken.isEmpty) {
        return const Result.failure(
          UnauthorizedException('انتهت صلاحية الجلسة'),
        );
      }
      await _persist(session);
      return Result.success(session);
    });
  }

  @override
  Future<Result<AuthSession, AppException>> currentSession() async {
    final access = await _tokens.readAccessToken();
    final refreshToken = await _tokens.readRefreshToken();
    if (access == null || access.isEmpty) {
      return const Result.failure(
        UnauthorizedException('No stored credentials.'),
      );
    }

    // No `/me` on this backend. `Profiles/Me` needs a valid bearer token and
    // nothing else, so a 200 is exactly the signal we want — and it also
    // provisions the social profile on a freshly registered account.
    final probe = await apiCall(
      EndPoints.profilesMe,
      () => _api.dio.get<dynamic>(EndPoints.profilesMe),
      (envelope) => envelope.list,
    );

    if (probe.isFailure) return Result.failure(probe.errorOrNull!);

    return Result.success(
      AuthSession(
        user: User(
          id: await _tokens.readUserId() ?? '',
          name: await _tokens.readDisplayName() ?? '',
          userName: await _tokens.readUserName(),
        ),
        accessToken: access,
        refreshToken: refreshToken ?? '',
        accessTokenExpiresAt: await _tokens.readAccessTokenExpiresAt(),
        refreshTokenExpiresAt: await _tokens.readRefreshTokenExpiresAt(),
      ),
    );
  }

  @override
  Future<Result<void, AppException>> logout({String? refreshToken}) async {
    final stored = refreshToken ?? await _tokens.readRefreshToken();
    try {
      if (stored != null && stored.isNotEmpty) {
        await _api.dio.post<dynamic>(
          EndPoints.authLogout,
          // `[FromForm] string refreshToken` — a JSON body does not bind.
          data: FormData.fromMap({'refreshToken': stored}),
        );
      }
      return const Result.success(null);
    } on DioException catch (e) {
      // Reported, but the local clear below still happens: a failed
      // server-side revoke must not strand someone in a session they asked to
      // leave.
      return Result.failure(apiException(e, EndPoints.authLogout));
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<Result<void, AppException>> ensureSigningSecret() async {
    // No signing-bootstrap endpoint exists on this backend. Returning success
    // rather than an error keeps splash quiet; `RequestSigningInterceptor`
    // omits `X-Request-Key` when no secret is stored, which is correct here.
    return const Result.success(null);
  }

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
