import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';

import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Auth surface. See `EndPoints` for the corresponding backend routes.
abstract class AuthRepository {
  /// `POST /api/Auth/Login` — sign in with credentials.
  Future<Result<AuthSession, AppException>> login({
    required String userName,
    required String password,
  });

  /// Creates an account and signs into it.
  ///
  /// One call — `POST /api/Auth/SignUp` — which creates the contact and its
  /// login in a single server-side transaction and returns tokens. Against a
  /// host still on RoboByte.Auth 1.11.1, where that endpoint does not exist,
  /// the implementation falls back to the older sequence: create the contact
  /// (`POST /api/Contact`), create the Identity user against that contact id
  /// (`POST /api/Auth/Register`), then log in.
  ///
  /// [accountType] is the individual/company distinction. It belongs to the
  /// social profile rather than to auth, so it is applied after the session
  /// exists; a failure to apply it does NOT fail the registration.
  ///
  /// [gender] and [imageUrl] ride on the contact. [imageUrl] is the host-less
  /// storage path produced by `MediaUploadService` — `avatars/<uuid>.jpg` —
  /// not a full URL, so the CDN host stays deployment configuration.
  Future<Result<AuthSession, AppException>> register({
    required String fullName,
    required String userName,
    required String phone,
    required String password,
    required AccountType accountType,
    required Gender? gender,
    String? imageUrl,
  });

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
  Future<Result<void, AppException>> logout({String? refreshToken});

  /// No-op against this backend — there is no signing-bootstrap endpoint, so
  /// no per-device secret is ever provisioned and `RequestSigningInterceptor`
  /// correctly omits `X-Request-Key`.
  ///
  /// Kept on the interface (and still called from splash) so that standing a
  /// signing endpoint up later is a one-file change here, not a hunt through
  /// the startup path.
  Future<Result<void, AppException>> ensureSigningSecret();
}
