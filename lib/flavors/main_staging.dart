import '../bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';

Future<void> main() => bootstrap(
      AppConfig(
        environment: Environment.staging,
        appName: 'رنق (Staging)',
        apiBaseUrl: 'https://api-staging.rung.app',
        enableLogging: true,
        useMockData: false,
      ),
    );
