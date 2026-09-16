import '../bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';

Future<void> main() => bootstrap(
      AppConfig(
        environment: Environment.prod,
        appName: 'رنق',
        apiBaseUrl: 'https://api.rung.app',
        enableLogging: false,
        useMockData: false,
      ),
    );
