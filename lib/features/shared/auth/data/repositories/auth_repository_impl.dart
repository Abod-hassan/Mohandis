import 'package:dio/dio.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/storage/token_storage.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';
import 'package:mohandis/features/profile/domain/repositories/profile_repository.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/registration.dart';
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

  /// Step 2 of registration — see [AuthRepository.createWithContact].
  ///
  /// Replaces the old `POST /api/Contact` → `Register` → `Login` sequence,
  /// which could not work against this backend at all: `ContactController` is
  /// `[Authorize]`d, so the very first call of a registration answered 401 for
  /// a caller who by definition has no session yet.
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
    final tenant = await _resolveTenantId();

    final result = await apiCall(
      EndPoints.authCreateWithContact,
      () => _api.dio.post<dynamic>(
        EndPoints.authCreateWithContact,
        data: {
          'name': fullName,
          'userName': userName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'password': password,
          // In the BODY: this is where the client says which partition the
          // new account belongs to. Null falls back to the server's
          // Auth:DefaultTenantId. It also goes in the HEADER below — see
          // there for why both.
          if (tenant != null) 'tenantId': tenant,
          // By NAME, never the ordinal — the Kernel's GenderEnum leads with
          // `Unspecified`, so ordinals shifted when it moved out of Auth.
          if (gender != null) 'gender': gender.wireName,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        // The registration token IS the authorisation for this call, and it is
        // not in storage — nothing has signed in yet — so it is set here by
        // hand. `AuthInterceptor` leaves an Authorization header alone once it
        // is set, which is what makes this survive the pipeline.
        //
        // `X-Tenant-Id` rides along even though the body already carries the
        // tenant, and the two are not redundant — they are read at different
        // moments by different code. The body's `tenantId` is read by the
        // ACTION, which assigns `AmbientContext.TenantId` before creating
        // anything; the header is read by the Kernel's middleware, which is
        // what makes a tenant "resolved for the request" in the sense the
        // strict-write check means when it refuses with *No tenant in scope
        // while persisting tenant-scoped entity 'ContactModel'* and names the
        // JWT claim and this header as the two ways to satisfy it.
        //
        // The usual objection — that a client-supplied header must not sit in
        // front of a JWT claim — does not apply on this ONE call: the bearer
        // is a registration token, which carries no tenant claim at all, so
        // there is nothing here for the header to override.
        options: Options(
          headers: {
            'Authorization': 'Bearer $registrationToken',
            if (tenant != null) 'X-Tenant-Id': tenant,
          },
        ),
      ),
      (envelope) => MobileAuthResultDto.fromJson(envelope.object).toDomain(),
    );

    return result.flatMapAsync((session) async {
      if (session.accessToken.isEmpty) {
        return const Result.failure(
          UnknownException('لم يُصدر الخادم رمز دخول بعد إنشاء الحساب'),
        );
      }
      await _persist(session);
      // The account type lives on the social profile, not on the auth contact,
      // so it is stamped once the session exists. Deliberately not allowed to
      // fail the registration: the account is created and the person is signed
      // in, and this is one editable field they can fix later.
      //
      // The photo is stamped in the SAME write, and for a reason worth
      // knowing: `CreateWithContact` stores it on the kernel contact
      // (`ContactModel.ImageUrl`), while every avatar the app renders comes
      // from the social profile's own `AvatarUrl`. Nothing copies one to the
      // other at the moment the profile is provisioned, so a photo chosen at
      // sign-up was written, kept, and never shown — it looked like the
      // upload had been dropped. This is the client half of that fix; the
      // module's provisioner now seeds `AvatarUrl` from the contact too, so a
      // profile created by any other route gets the photo as well.
      //
      // `patchMe`, not `updateMe`: nothing here reads the result, and
      // `updateMe` would follow the write with a full profile re-read —
      // the profile plus its experience, education and skills, four
      // requests — immediately before `_dropSessionCaches` invalidates
      // them and the first screen fetches them again anyway.
      await _profiles.patchMe({
        'accountType': accountType,
        if (imageUrl != null && imageUrl.isNotEmpty) 'avatarUrl': imageUrl,
      });
      return Result.success(session);
    });
  }

  @override
  Future<Result<IdentityAvailability, AppException>> checkIdentity({
    String? userName,
    String? phone,
    String? email,
  }) async {
    final query = <String, dynamic>{
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    // The server refuses an empty query with a 400. Answering locally keeps a
    // form that has not been filled in yet from generating traffic at all.
    if (query.isEmpty) {
      return const Result.success(IdentityAvailability());
    }

    final options = await _tenantHeader();
    return apiCall(
      EndPoints.authExists,
      () => _api.dio.get<dynamic>(
        EndPoints.authExists,
        queryParameters: query,
        options: options,
      ),
      // Bare object, not a ResultViewModel envelope.
      (envelope) => IdentityAvailability.fromJson(envelope.object),
    );
  }

  @override
  Future<Result<void, AppException>> sendPhoneCode(
    String phone, {
    bool isSms = false,
  }) async {
    final options = await _tenantHeader();
    final result = await apiCall(
      EndPoints.authGenerateOtp,
      // QUERY parameters, not a body — the action signature takes them
      // positionally and a JSON body binds to nothing.
      () => _api.dio.post<dynamic>(
        EndPoints.authGenerateOtp,
        queryParameters: {'phone': phone, 'isSms': isSms},
        options: options,
      ),
      (_) {},
    );
    return result.map<void>((_) {});
  }

  @override
  Future<Result<VerificationOutcome, AppException>> verifyPhoneCode({
    required String phone,
    required String otp,
  }) async {
    final options = await _tenantHeader();
    return _verify(
      EndPoints.authValidateOtp,
      () => _api.dio.post<dynamic>(
        EndPoints.authValidateOtp,
        // `sid` is accepted for wire compatibility and ignored server-side —
        // the code is keyed by phone, not by a provider session. It still has
        // to be NON-EMPTY: the action signature is
        // `ValidateOTP(string sid, string phone, string otp)` with nullable
        // reference types enabled, so `[ApiController]` synthesises a
        // `[Required]` on it, and `Required` rejects an empty string as well
        // as a missing one. Sending `sid=` answered
        // `400 {"errors":{"sid":["The sid field is required."]}}` — a
        // validation failure before any of our code ran, on a value nothing
        // reads. A single character satisfies the binder and changes nothing.
        queryParameters: {'phone': phone, 'otp': otp, 'sid': '-'},
        options: options,
      ),
    );
  }

  @override
  Future<Result<void, AppException>> sendEmailCode(String email) async {
    // The header goes on even when there IS a session, which is the opposite
    // of the rule everywhere else — and it is right here for one reason:
    // this path is in `ApiClient`'s `unauthenticatedPaths`, so `AuthInterceptor`
    // never attaches a bearer to it. With no bearer there is no tenant claim
    // either, so without the header the server would fall back to
    // `Auth:DefaultTenantId` and write the code row under the wrong tenant for
    // anyone signed in to a different one. There is no claim to override.
    final options = await _tenantHeader();
    final result = await apiCall(
      EndPoints.authEmailSendCode,
      () => _api.dio.post<dynamic>(
        EndPoints.authEmailSendCode,
        data: {'email': email},
        options: options,
      ),
      (_) {},
    );
    return result.map<void>((_) {});
  }

  @override
  Future<Result<VerificationOutcome, AppException>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final options = await _tenantHeader();
    return _verify(
      EndPoints.authEmailVerifyCode,
      () => _api.dio.post<dynamic>(
        EndPoints.authEmailVerifyCode,
        data: {'email': email, 'code': code},
        options: options,
      ),
    );
  }

  @override
  Future<Result<void, AppException>> confirmEmail({
    required String email,
    required String code,
  }) async {
    // No tenant header: this call carries a real bearer, and the Kernel reads
    // the tenant off the JWT claim. A client-supplied header would override a
    // claim the server already trusts — the same rule `storageZoneProvider`
    // and the login calls follow, from the other side of it.
    final result = await apiCall(
      EndPoints.authEmailChange,
      () => _api.dio.post<dynamic>(
        EndPoints.authEmailChange,
        data: {'email': email, 'code': code},
      ),
      (_) {},
    );
    return result.map<void>((_) {});
  }

  @override
  Future<Result<void, AppException>> resetPassword({
    required String password,
  }) async {
    // No tenant header — the bearer is a real session and the Kernel reads the
    // tenant off its claim.
    final result = await apiCall(
      EndPoints.authResetPassword,
      () => _api.dio.post<dynamic>(
        EndPoints.authResetPassword,
        // `confirmPassword` is compared server-side and the call is refused on
        // a mismatch, so it is sent rather than trusted to the form alone.
        data: {'password': password, 'confirmPassword': password},
      ),
      (_) {},
    );
    return result.map<void>((_) {});
  }

  /// Reads the one boolean that decides what a verification response MEANS.
  ///
  /// A registration token and a real session come back in the same
  /// `LoginResultDto` shape; `isNewUser` is the only thing separating them.
  /// Persisting a registration token as a session would leave the app holding
  /// a bearer that every endpoint except `CreateWithContact` rejects — so the
  /// session branch persists and the token branch deliberately does not.
  Future<Result<VerificationOutcome, AppException>> _verify(
    String path,
    Future<Response<dynamic>> Function() send,
  ) async {
    final result = await apiCall(path, send, (envelope) {
      final dto = MobileAuthResultDto.fromJson(envelope.object);
      return dto.isNewUser
          ? RegistrationToken(token: dto.accessToken, email: dto.email)
              as VerificationOutcome
          : VerifiedSession(dto.toDomain());
    });

    // Persist ONLY a real session. `apiCall`'s parser is synchronous, so the
    // write happens here rather than inside it.
    return result.flatMapAsync((outcome) async {
      if (outcome is VerifiedSession) await _persist(outcome.session);
      return Result.success(outcome);
    });
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
    final stored = await _tokens.readAccessToken();
    if (stored == null || stored.isEmpty) {
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

    // **Read the tokens AFTER the probe, not before.** On a cold start with an
    // expired access token, that probe is exactly what triggers the refresh:
    // it 401s, `AuthInterceptor` refreshes, stores a NEW pair and replays it.
    // Reading the pair beforehand built the session from the dead access
    // token and — because the backend rotates — a refresh token the server
    // had already spent. Nothing reads those two fields off the session today
    // (requests and logout both go to storage), so this was latent rather than
    // live; but a session object that disagrees with storage is the bug that
    // bites the first piece of code to trust it.
    final access = await _tokens.readAccessToken() ?? stored;
    final refreshToken = await _tokens.readRefreshToken();

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
  Future<Result<void, AppException>> logout({
    String? refreshToken,
    String? accessToken,
  }) async {
    final stored = refreshToken ?? await _tokens.readRefreshToken();
    final bearer = accessToken ?? await _tokens.readAccessToken();
    try {
      if (stored != null && stored.isNotEmpty) {
        await _api.dio.post<dynamic>(
          EndPoints.authLogout,
          // `[FromForm] string refreshToken` — a JSON body does not bind.
          data: FormData.fromMap({'refreshToken': stored}),
          // Set by hand because storage is already empty by the time this
          // runs. An explicit header is also one `AuthInterceptor` will not
          // try to refresh on a 401 — refreshing the session being ended is
          // the opposite of what this call is for.
          options: bearer == null || bearer.isEmpty
              ? null
              : Options(headers: {'Authorization': 'Bearer $bearer'}),
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
  Future<Result<void, AppException>> deleteAccount() async {
    final social = await apiCall(
      EndPoints.profilesMe,
      () => _api.dio.delete<dynamic>(EndPoints.profilesMe),
      (_) {},
    );
    if (social.isFailure) return social;
    return apiCall(
      EndPoints.authAccount,
      () => _api.dio.delete<dynamic>(EndPoints.authAccount),
      (_) {},
    );
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
