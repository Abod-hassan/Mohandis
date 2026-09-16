import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'app.theme_mode';

/// App-wide light/dark selection. The design ships full parity between the
/// two themes, so this is a user preference rather than a system follow.
///
/// Persisted in plain `SharedPreferences` — it is not a secret, so it does
/// not belong in `TokenStorage`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // ignore: unawaited_futures
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kThemeModeKey);
      if (stored == null) return;
      state = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.light,
      );
    } catch (e) {
      debugPrint('[theme] restore failed: $e');
    }
  }

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, mode.name);
    } catch (e) {
      debugPrint('[theme] persist failed: $e');
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
