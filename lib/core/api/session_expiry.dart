import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The channel the network layer uses to say "the server has stopped
/// accepting this device's session".
///
/// It exists because the two halves of that sentence live in layers that are
/// not allowed to know about each other. `AuthInterceptor` is the only code
/// that sees a 401 it could not refresh, and `AuthNotifier` is the only code
/// that can end a session — but `core/api` must not import the auth feature
/// (see `TokenRefresher`, which exists for exactly the same reason). So the
/// interceptor pushes a signal here and the notifier listens for it.
///
/// Without this, an expired token was a dead end. The interceptor cleared the
/// tokens and forwarded the 401 to whichever repository asked, so every screen
/// rendered an error view, every retry failed the same way, and the app stayed
/// inside the signed-in shell with no route back to the login screen. The only
/// way out was to delete the app.
class SessionExpiry {
  const SessionExpiry({
    this.tick = 0,
    this.noticePending = false,
    this.reason,
  });

  /// What the refresh endpoint actually said when it ended the session — see
  /// `TokenRefresher.lastRefusal`. Null when nothing was recorded.
  final String? reason;

  /// Bumped on every signal.
  ///
  /// A counter rather than a flag, because a flag that is already true
  /// notifies nobody the second time. Two expiries in one session — sign in,
  /// let it lapse again — have to be two events.
  final int tick;

  /// True from the moment a session expires until a screen has told the
  /// person why they are looking at the login form.
  ///
  /// Separate from [tick] so that acknowledging the message does not read as
  /// another expiry.
  final bool noticePending;

  SessionExpiry expired([String? why]) =>
      SessionExpiry(tick: tick + 1, noticePending: true, reason: why);

  SessionExpiry get acknowledged =>
      SessionExpiry(tick: tick, noticePending: false, reason: reason);
}

class SessionExpiryNotifier extends Notifier<SessionExpiry> {
  @override
  SessionExpiry build() => const SessionExpiry();

  /// Called from the network layer when a 401 could not be refreshed.
  ///
  /// Safe to call from a burst: a screenful of parallel reads all fail at
  /// once, and each one lands here. The listener side is what collapses them
  /// into a single sign-out.
  void signal([String? reason]) => state = state.expired(reason);

  /// Called once the person has been told. See [SessionExpiry.noticePending].
  void acknowledge() {
    if (state.noticePending) state = state.acknowledged;
  }
}

final sessionExpiryProvider =
    NotifierProvider<SessionExpiryNotifier, SessionExpiry>(
      SessionExpiryNotifier.new,
    );
