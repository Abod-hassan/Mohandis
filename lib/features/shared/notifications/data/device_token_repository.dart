import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

/// Talks to the backend's device-token register/unregister endpoints
/// so push notifications can be targeted at this specific install.
///
/// Auth is JWT-required on register/unregister; the backend keys the
/// row on the JWT's user claim, the client never passes a userId.
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
      final res = await _api.dio.post<dynamic>(
        EndPoints.deviceRegisterToken,
        data: {
          'fcmToken': fcmToken,
          'platform': _platformName(),
        },
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
  Future<Result<bool, AppException>> unregister() async {
    try {
      await _api.dio.post<dynamic>(EndPoints.deviceUnregisterToken);
      return const Result.success(true);
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  /// Wire-side platform tag — kept as a stable lowercase string so the
  /// backend doesn't have to parse `Platform.operatingSystem` quirks
  /// (e.g. macOS surfaces as `"macos"`, unhelpful for FCM).
  String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
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
