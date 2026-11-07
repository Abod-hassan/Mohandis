import '../bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';

Future<void> main() => bootstrap(
      AppConfig(
        environment: Environment.prod,
        appName: 'مهندس',
        apiBaseUrl: 'http://192.248.191.138:2028',
        enableLogging: false,
        useMockData: false,
      ),
    );
