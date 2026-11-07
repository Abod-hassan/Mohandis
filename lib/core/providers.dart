import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/session_expiry.dart';
import 'api/token_refresher.dart';
import 'config/app_config.dart';
import 'services/device_info_service.dart';
import 'services/logger.dart';
import 'services/storage_zone.dart';
import 'services/stream_library.dart';
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


/// Resolves a path that may belong to EITHER Bunny product.
///
/// Reels are the only thing in the app with two possible homes. A reel
/// published since Stream arrived stores `<guid>/playlist.m3u8`, served by the
/// Stream library's own CDN; one published before it — and every seeded row —
/// stores `reels/<uuid>.mp4` in the storage zone. Both have to keep playing,
/// so the path itself says which it is.
///
/// A Stream path is recognised by its FIRST SEGMENT being a UUID, which is what
/// a Bunny video guid is. A storage path's first segment is a folder name
/// (`reels`, `avatars`, `courses`), and a folder named like a UUID is not
/// something this app ever creates.
final streamAwareUrlResolverProvider = Provider<String? Function(String?)>((
  ref,
) {
  final library = ref.watch(streamLibraryProvider).valueOrNull;
  final storage = ref.watch(imageUrlResolverProvider);

  return (path) {
    final raw = path?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    if (library != null && _looksLikeStreamPath(raw)) {
      // Falls through to storage when the library has no CDN hostname — a
      // half-configured library should not blank a reel that may still be
      // readable the old way.
      final resolved = library.publicUrl(raw);
      if (resolved != null) return resolved;
    }
    return storage(raw);
  };
});

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _looksLikeStreamPath(String path) {
  final clean = path.startsWith('/') ? path.substring(1) : path;
  final slash = clean.indexOf('/');
  if (slash <= 0) return false;
  return _uuid.hasMatch(clean.substring(0, slash));
}

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
    // `read`, not `watch`: this is an outbound signal, and watching the
    // notifier would rebuild the Dio — throwing away its connection pool and
    // every in-flight request — each time a session expired.
    //
    // Carries WHY: read off the refresher at the moment it gave up, which is
    // exactly when the interceptor calls this.
    onSessionExpired: () => ref
        .read(sessionExpiryProvider.notifier)
        .signal(refresher.lastRefusal),
  );
});
