import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kProfileSetupPendingKey = 'onboarding.profile_setup_pending';

/// Whether the signed-in user still owes us the profile-building step.
///
/// Set when registration succeeds and cleared when the person finishes or
/// skips that screen. Persisted in plain `SharedPreferences` — it is not a
/// secret, and it has to survive the app being killed mid-onboarding, which an
/// in-memory flag would not.
///
/// Deliberately NOT derived from "the profile looks empty on the server": that
/// would drag long-standing users with a sparse profile back into onboarding
/// every cold start. This flag means "this account was just created here", and
/// nothing else.
class ProfileSetupNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Starts false so the router never bounces an existing session into
    // onboarding during the async read; `_restore` corrects it, and the
    // router's refreshListenable re-evaluates when it does.
    // ignore: unawaited_futures
    _restore();
    return false;
  }

  /// Set once the flag has been written in this session, so a slow restore
  /// can never overwrite a decision the user has already made.
  bool _written = false;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getBool(_kProfileSetupPendingKey) ?? false;
      if (_written) return;
      if (pending != state) state = pending;
    } catch (e) {
      debugPrint('[onboarding] restore failed: $e');
    }
  }

  /// Called on a successful registration.
  Future<void> markPending() => _set(true);

  /// Called when the profile step is completed or skipped.
  Future<void> complete() => _set(false);

  Future<void> _set(bool pending) async {
    _written = true;
    state = pending;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kProfileSetupPendingKey, pending);
    } catch (e) {
      debugPrint('[onboarding] persist failed: $e');
    }
  }
}

final profileSetupPendingProvider =
    NotifierProvider<ProfileSetupNotifier, bool>(ProfileSetupNotifier.new);
