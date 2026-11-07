import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// False for the first moment of the app's life; true forever after.
///
/// Secondary counters — the nav-bar connection badge, the top-bar unread dot —
/// gate their reads on this. They are correct and cheap, but they are NOT what
/// the person opened the app to see, and firing them alongside the feed put six
/// or seven sockets on the wire in the same instant. A host that refuses one of
/// those connections turns a cosmetic dot into a full-screen error, because a
/// failed build latches on a provider nobody re-runs.
///
/// Gating, not deleting: the badge and the dot still load, a moment later, off
/// the critical path. Because the gate returns early, their providers are not
/// even CONSTRUCTED while it is false — so nothing is fetched and discarded.
///
/// **A plain timer, deliberately.** The obvious alternative is to settle when
/// the feed finishes, but reading `feedNotifierProvider` to find that out
/// *creates* it — and on a deep link that lands on another branch of the shell,
/// where the feed was never mounted, the gate would fire a `POST /Feed` that
/// nothing asked for. A stagger is all this needs to be; it does not need to
/// know what it is staggering behind.
class StartupSettled extends Notifier<bool> {
  /// How long the secondary reads wait. Long enough for the feed's own requests
  /// to get out first on a healthy connection, short enough that a badge
  /// appearing late reads as part of the launch rather than as a glitch.
  static const Duration _stagger = Duration(milliseconds: 1200);

  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // `_timer ??=` and no reset: Riverpod re-runs `build` on the same instance,
    // and restarting the clock on every rebuild could hold the gate shut
    // indefinitely.
    _timer ??= Timer(_stagger, () {
      _timer = null;
      state = true;
    });
    return false;
  }
}

final startupSettledProvider = NotifierProvider<StartupSettled, bool>(
  StartupSettled.new,
);
