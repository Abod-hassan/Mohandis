import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/endpoints.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
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
    await Firebase.initializeApp();
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
          // AuthTokenRefresher owns its own bare Dio (no AuthInterceptor)
          // so refreshing the access token can't loop back through the
          // main ApiClient and form an `apiClient → refresher → apiClient`
          // cycle. It only needs the base URL, the refresh path, and
          // TokenStorage.
          return AuthTokenRefresher(
            baseUrl: config.apiBaseUrl,
            refreshPath: EndPoints.authRefresh,
            tokenStorage: ref.read(tokenStorageProvider),
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
