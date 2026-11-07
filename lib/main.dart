// Default entrypoint, used whenever no `--target` is given — including
// `flutter build appbundle` / `flutter build apk` for the Play Store.
//
// A RELEASE build always runs the prod flavor; anything else runs dev. It used
// to re-export dev unconditionally, so a release built without `-t` shipped
// pointing at https://localhost:7199.
//
// Run a specific flavor with `--target`:
//   flutter run --target lib/flavors/main_dev.dart
//   flutter run --target lib/flavors/main_staging.dart
//   flutter run --target lib/flavors/main_prod.dart
// (On iOS the xcconfig pins win over `--target`: see ios/Flutter/Flavor*.xcconfig.)
import 'package:flutter/foundation.dart';

import 'flavors/main_dev.dart' as dev;
import 'flavors/main_prod.dart' as prod;

Future<void> main() => kReleaseMode ? prod.main() : dev.main();
