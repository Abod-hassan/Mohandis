import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An address the person gave at sign-up that no account has confirmed yet.
///
/// Registration proves the phone and nothing else — see `VerifyScreen` for
/// why both cannot be proved before the account exists. The address they
/// typed would otherwise be dropped on the floor: `CreateWithContact` only
/// takes an e-mail off a registration token's claims, and a phone-proved
/// token carries none. So it is parked here for the length of the session
/// and offered once, on the profile step, as the optional second factor.
///
/// In memory on purpose. This is a nudge, not a task: it is worth carrying
/// from the verify screen to the next screen, and not worth resurrecting a
/// week later on a device the person has been using happily without it. The
/// permanent way in is Settings, which needs no state at all.
class PendingEmailNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Park an address to offer. Trimmed; blank is the same as none.
  void offer(String email) {
    final trimmed = email.trim();
    state = trimmed.isEmpty ? null : trimmed;
  }

  /// Stop offering it — confirmed, declined, or the account it belonged to
  /// is gone.
  void dismiss() => state = null;
}

final pendingEmailProvider =
    NotifierProvider<PendingEmailNotifier, String?>(PendingEmailNotifier.new);
