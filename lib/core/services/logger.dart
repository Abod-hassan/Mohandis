import 'package:flutter/foundation.dart';

/// Thin wrapper around `debugPrint` so call sites never reach for `print`.
/// Swap the implementation for a real logger (e.g. logger package, Sentry,
/// Crashlytics) without touching call sites.
class AppLogger {
  const AppLogger({this.tag});

  final String? tag;

  void d(Object? message) => _log('D', message);
  void i(Object? message) => _log('I', message);
  void w(Object? message) => _log('W', message);

  void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    _log('E', message);
    if (error != null) _log('E', error);
    if (stackTrace != null) _log('E', stackTrace);
  }

  void _log(String level, Object? message) {
    if (!kDebugMode) return;
    final prefix = tag == null ? '[$level]' : '[$level][$tag]';
    debugPrint('$prefix $message');
  }
}
