import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/endpoints.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'firebase_options.dart';
import 'features/shared/auth/data/auth_token_refresher.dart';
import 'mocks/mock_overrides.dart';

/// Shared entrypoint called from every flavor. See docs/ARCHITECTURE.md §4.
///
/// Each `lib/flavors/main_<env>.dart` builds a flavor-specific [AppConfig]
/// and hands it here. This function:
///
///   1. Ensures Flutter bindings are initialised.
///   2. Initialises Firebase (skip the try/catch when your Firebase config
///      files are wired — the guard here just keeps the template running
///      without google-services.json for smoke tests).
///   3. Runs the app inside a `ProviderScope` with the two mandatory
///      overrides: `appConfigProvider` and `tokenRefresherProvider`.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // `DefaultFirebaseOptions`, not the platform files alone: `flutterfire
    // configure` writes `lib/firebase_options.dart` as the one source both
    // platforms read, and passing it is what makes a misconfigured build fail
    // loudly here instead of silently producing no FCM token later.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[bootstrap] Firebase.initializeApp skipped: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        tokenRefresherProvider.overrideWith((ref) {
          // AuthTokenRefresher owns its own Dio (no AuthInterceptor) so
          // refreshing the access token can't loop back through the main
          // ApiClient and form an `apiClient → refresher → apiClient` cycle.
          // It still needs the config and device info: the refresh has to
          // look like every other call from this device.
          return AuthTokenRefresher(
            config: config,
            refreshPath: EndPoints.authRefresh,
            tokenStorage: ref.read(tokenStorageProvider),
            // The refresh has to identify the device like every other call
            // does — see AuthTokenRefresher._build.
            deviceInfo: ref.read(deviceInfoServiceProvider),
          );
        }),
        // Demo / design-preview builds run entirely on seeded in-memory
        // repositories. Prod leaves `useMockData` false and hits the API.
        if (config.useMockData) ...mockOverrides(),
      ],
      child: const App(),
    ),
  );
}
