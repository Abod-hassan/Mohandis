import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';

/// Talks to the backend's device-token register/unregister endpoints
/// so push notifications can be targeted at this specific install.
///
/// Auth is JWT-required on register/unregister; the backend keys the row on
/// the JWT's `ContactId` claim plus this device's `X-Device-SN`, so the client
/// never passes an id of its own.
class DeviceTokenRepository {
  DeviceTokenRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Register / refresh the device's FCM token.
  ///
  /// Idempotent — calling with the same value twice is a no-op on the
  /// backend. The mobile side dedupes anyway via the
  /// `FcmLocalStorage.lastRegisteredToken` check before posting.
  Future<Result<bool, AppException>> register(String fcmToken) async {
    if (fcmToken.isEmpty) {
      return const Result.failure(
        ValidationException('Empty FCM token cannot be registered.'),
      );
    }
    try {
      // `POST api/Notification/UpdateNID(string nid)` — a bare simple type, so
      // ASP.NET binds it from the QUERY STRING. No body: this used to send the
      // token as a JSON string as well, in case the parameter turned out to be
      // [FromBody], and the module's source says it is not.
      //
      // The row is keyed by (ContactId, DeviceSn): the contact comes from the
      // JWT's `ContactId` claim and the device from the `X-Device-SN` header
      // that `DeviceHeaderInterceptor` puts on every call — which is how one
      // person on two phones keeps two tokens instead of overwriting one.
      final res = await _api.dio.post<dynamic>(
        EndPoints.deviceRegisterToken,
        queryParameters: {'nid': fcmToken},
      );
      // Envelope shape: { data: true } / { Data: true }. Treat any
      // 2xx with non-error envelope as success — the actual boolean
      // doesn't carry meaning beyond "the row was written".
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final err = body['error'] ?? body['Error'];
        if (err == true) {
          final msg = (body['message'] ?? body['Message']) as String?;
          return Result.failure(ValidationException(
            msg?.isNotEmpty == true ? msg! : 'Token registration failed',
          ));
        }
      }
      return const Result.success(true);
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  /// Clear the device token on logout. Best-effort — failure here
  /// doesn't block the logout flow (the local session is wiped
  /// regardless; worst case the backend still thinks this device is
  /// addressable until the next login of any user on it).
  /// [bearer] is the access token of the session being ended. Sign-out now
  /// clears storage BEFORE this runs, so the interceptor has nothing to attach
  /// — and this call is JWT-keyed: without the bearer the server cannot tell
  /// whose registration to drop, and the phone keeps receiving the previous
  /// account's notifications.
  Future<Result<bool, AppException>> unregister({String? bearer}) async {
    try {
      // GET, not POST: `RemoveNID` is declared `[HttpGet("[action]")]` on the
      // module's NotificationController. A POST here answered 405 and the
      // token was never cleared, so a signed-out phone kept receiving the
      // previous account's notifications until somebody signed in again.
      await _api.dio.get<dynamic>(
        EndPoints.deviceUnregisterToken,
        options: bearer == null || bearer.isEmpty
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      return const Result.success(true);
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  AppException _asAppException(DioException e) {
    final mapped = e.error;
    if (mapped is AppException) return mapped;
    final body = e.response?.data;
    if (body is String && body.isNotEmpty) return ValidationException(body);
    if (body is Map && body['message'] is String) {
      return ValidationException(body['message'] as String);
    }
    return UnknownException(e.message ?? 'Device-token request failed',
        cause: e);
  }
}

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(apiClient: ref.watch(apiClientProvider));
});
