import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../entities/auth_session.dart';
import '../entities/registration.dart';
import '../entities/user.dart';

/// Auth surface. See `EndPoints` for the corresponding backend routes.
abstract class AuthRepository {
  /// `POST /api/Auth/Login` — sign in with credentials.
  Future<Result<AuthSession, AppException>> login({
    required String userName,
    required String password,
  });

  /// Step 2 of registration: spends a [RegistrationToken] to create the
  /// account, and returns a real session.
  ///
  /// `POST /api/Auth/CreateWithContact`. There is no one-shot sign-up on this
  /// backend, and `POST /api/Contact` is `[Authorize]`d — so an identity has
  /// to be proved first, which is what produces the token this call spends.
  ///
  /// [registrationToken] rides as this one call's bearer — it IS the proof,
  /// and the endpoint is the only one that accepts it. The channel it came
  /// from is applied server-side: a phone-proved token marks the phone
  /// confirmed, an e-mail-proved one confirms the address, so neither is
  /// re-sent here.
  ///
  /// [accountType] is the individual/company distinction. It belongs to the
  /// social profile rather than to auth, so it is applied after the session
  /// exists; a failure to apply it does NOT fail the registration.
  ///
  /// [gender] and [imageUrl] ride on the contact. [imageUrl] is the host-less
  /// storage path produced by `MediaUploadService` — `avatars/<uuid>.jpg` —
  /// not a full URL, so the CDN host stays deployment configuration.
  Future<Result<AuthSession, AppException>> createWithContact({
    required String registrationToken,
    required String fullName,
    required String userName,
    String? phone,
    required String password,
    required AccountType accountType,
    required Gender? gender,
    String? imageUrl,
  });

  /// `GET /api/Auth/Exists` — is any of these already taken?
  ///
  /// Anonymous, and called from the sign-up form as the person types. Pass
  /// only the fields you are asking about: a flag for an omitted parameter
  /// comes back false, which would read as "free" rather than "unknown".
  ///
  /// A transport failure is a failure, NOT a set of falses: the form treats
  /// "we could not ask" as "carry on", because blocking submit on an
  /// unreachable probe would make a flaky network look like every username
  /// being taken.
  Future<Result<IdentityAvailability, AppException>> checkIdentity({
    String? userName,
    String? phone,
    String? email,
  });

  /// Sends a one-time code to [phone] (E.164).
  ///
  /// [isSms] false is the provider's WhatsApp→SMS cascade, which is the
  /// default and the cheaper path; true forces plain SMS.
  Future<Result<void, AppException>> sendPhoneCode(
    String phone, {
    bool isSms = false,
  });

  /// Redeems a phone code. See [VerificationOutcome] — this answers either a
  /// signed-in session or a registration token, and they share a wire shape.
  Future<Result<VerificationOutcome, AppException>> verifyPhoneCode({
    required String phone,
    required String otp,
  });

  /// Sends a one-time code to [email].
  Future<Result<void, AppException>> sendEmailCode(String email);

  /// Redeems an e-mail code. See [verifyPhoneCode].
  Future<Result<VerificationOutcome, AppException>> verifyEmailCode({
    required String email,
    required String code,
  });

  /// Attaches [email] to the SIGNED-IN account and marks it confirmed.
  ///
  /// The optional second factor. [code] is one from [sendEmailCode], so the
  /// send is shared with the sign-in flow; only the redemption differs.
  /// Deliberately not [verifyEmailCode]: that one is anonymous and, for an
  /// address no account owns, answers a registration token — it would offer
  /// to build a SECOND account around the address instead of adding it to the
  /// one already signed in.
  ///
  /// Requires a session. The server refuses an address another confirmed
  /// account already holds (`email_already_in_use`).
  Future<Result<void, AppException>> confirmEmail({
    required String email,
    required String code,
  });

  /// Replaces the signed-in account's password without the old one.
  ///
  /// The last step of forgot-password. Only a session carrying the
  /// `RecoveryVerified` role — one issued by `verifyPhoneCode` or
  /// `verifyEmailCode`, not by `login` — is allowed to do this, and only to
  /// its own account. An ordinary session gets `current password is required`.
  Future<Result<void, AppException>> resetPassword({required String password});

  /// `PUT /api/Auth/Refresh-Token` — rotate the access token. Callers
  /// MUST persist the returned pair.
  Future<Result<AuthSession, AppException>> refresh({
    required String refreshToken,
  });

  /// Validates the stored access token and rebuilds the session from local
  /// storage. Used on cold start.
  ///
  /// There is no `/api/auth/me` on this backend, so the check is a real
  /// authenticated call — `GET /api/social/Profiles/Me` — which needs a valid
  /// bearer token and nothing else.
  Future<Result<AuthSession, AppException>> currentSession();

  /// `POST /api/Auth/Logout` — revokes the supplied refresh token
  /// server-side. Local token storage is cleared regardless of the server's
  /// response so a flaky network doesn't trap the user.
  /// Revokes the session server-side and releases this device's slot.
  ///
  /// Pass [refreshToken] and [accessToken] when the caller has ALREADY cleared
  /// local storage — which `AuthNotifier.logout` now does first, so that no
  /// request in flight during sign-out can use or refresh the old session.
  /// They are the snapshot taken just before the clear.
  Future<Result<void, AppException>> logout({
    String? refreshToken,
    String? accessToken,
  });

  /// Permanently deletes the signed-in account: first the social data
  /// (`DELETE Profiles/Me`), then the login (`DELETE Auth/Account`). Stops at
  /// the first failure — a login without its profile is recoverable by trying
  /// again, a profile whose login is already gone is not. Does NOT clear local
  /// storage; `AuthNotifier.deleteAccount` signs out afterwards.
  Future<Result<void, AppException>> deleteAccount();

  /// No-op against this backend — there is no signing-bootstrap endpoint, so
  /// no per-device secret is ever provisioned and `RequestSigningInterceptor`
  /// correctly omits `X-Request-Key`.
  ///
  /// Kept on the interface (and still called from splash) so that standing a
  /// signing endpoint up later is a one-file change here, not a hunt through
  /// the startup path.
  Future<Result<void, AppException>> ensureSigningSecret();
}
