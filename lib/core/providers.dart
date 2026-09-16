import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/token_refresher.dart';
import 'config/app_config.dart';
import 'services/device_info_service.dart';
import 'services/logger.dart';
import 'services/storage_zone.dart';
import 'storage/token_storage.dart';

/// Global providers only. Feature-specific providers live with the feature.
/// See docs/ARCHITECTURE.md §5.

/// The active flavor's AppConfig. Bootstrap SHALL override this with the
/// flavor-specific instance — the fallback here throws so a missing
/// override surfaces loudly during tests.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError(
    'appConfigProvider was read without an override. Bootstrap must set '
    'ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)]).',
  );
});

/// Turns a stored image path into something an `Image.network` can load.
///
/// Every uploaded photo is persisted host-less, so nothing renders one without
/// going through here. The CDN host comes from the zone the backend serves
/// (`storageZoneProvider`), which means two things worth knowing:
///
///   * An already-absolute URL is returned whatever the zone's state, so rows
///     written before the host-less convention (and any external avatar) keep
///     rendering everywhere.
///   * Until the zone answers — and forever on a deployment with no zone row —
///     `AppConfig.cdnBaseUrl` stands in. Reading is not the part that needs a
///     credential, and without a fallback every avatar already on a profile
///     would blank out during the fetch and stay blank on a host that has not
///     been configured yet. Uploading still requires the real zone.
final imageUrlResolverProvider = Provider<String? Function(String?)>((ref) {
  final zone = ref.watch(storageZoneProvider).valueOrNull;
  final fallbackBase = ref.watch(appConfigProvider).cdnBaseUrl;
  return (path) {
    final raw = path?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (zone != null) return zone.publicUrl(raw);
    if (fallbackBase == null || fallbackBase.isEmpty) return null;
    final base = fallbackBase.endsWith('/')
        ? fallbackBase.substring(0, fallbackBase.length - 1)
        : fallbackBase;
    return '$base/${raw.startsWith('/') ? raw.substring(1) : raw}';
  };
});


/// Secure token storage — Keychain (iOS) / EncryptedSharedPreferences (Android).
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Device info (install-stable serial, OS, app version, timezone). Attached
/// to every request via `DeviceHeaderInterceptor`.
final deviceInfoServiceProvider =
    Provider<DeviceInfoService>((ref) => DeviceInfoService());

/// Structured logger. Do NOT call `print(...)` — always go through this or
/// `debugPrint` guarded by `kDebugMode`. See ARCHITECTURE.md §17.
final loggerProvider = Provider<AppLogger>((ref) => AppLogger());

/// Token refresher wired into `AuthInterceptor`. Bootstrap SHALL override
/// this with a real `AuthTokenRefresher` bound to the current flavor's
/// refresh endpoint — see `lib/bootstrap.dart`.
final tokenRefresherProvider =
    Provider<TokenRefresher>((ref) => const NoopTokenRefresher());

/// The single Dio instance app-wide. Every repository reaches the network
/// through `ref.watch(apiClientProvider).dio` — there SHALL NOT be a
/// second Dio anywhere in the app (except `AuthTokenRefresher`'s bare
/// Dio, which is scoped and interceptor-free by design).
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  final refresher = ref.watch(tokenRefresherProvider);
  return ApiClient(
    config: config,
    tokenStorage: storage,
    deviceInfo: deviceInfo,
    refreshAccessToken: refresher.refresh,
  );
});
