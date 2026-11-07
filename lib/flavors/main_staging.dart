import '../bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';

// Const, so --dart-define is read at compile time (String.fromEnvironment
// only works in a constant context).
const String _stagingApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.248.191.138:2028',
);

Future<void> main() => bootstrap(
      AppConfig(
        environment: Environment.staging,
        appName: 'مهندس (Staging)',
        // No separate staging server exists yet; this flavour points at the
        // dev host until one does. Override per run with
        // --dart-define=API_BASE_URL=... if needed.
        apiBaseUrl: _stagingApiBaseUrl,
        enableLogging: true,
        useMockData: false,
      ),
    );
