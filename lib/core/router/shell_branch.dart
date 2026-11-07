import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which branch of the shell is on screen right now.
///
/// `StatefulShellRoute.indexedStack` keeps every branch BUILT and mounted so
/// each tab holds its own stack and scroll position. That is the right
/// behaviour for a list and the wrong one for a video: a reel left playing
/// behind the feed keeps its audio running, which is how a social app ends up
/// talking to somebody who has already swiped away.
///
/// Nothing else can answer this. `ModalRoute.isCurrent` is true for every
/// branch's own route, and `TickerMode` is not disabled for the inactive
/// children of an IndexedStack — so the reels screen has no way to know it is
/// hidden without the shell telling it.
///
/// -1 until the shell has built, which no screen should treat as "I am
/// visible": the reels screen only plays on an exact match.
final shellBranchProvider = StateProvider<int>((ref) => -1);

/// The shell's branch indices, by name.
///
/// Public and shared because three files need them and the two that had their
/// own copy drifted: the reels screen carried `const int _reelsBranch = 1` with
/// a comment asking whoever reordered the tabs to remember this file too, which
/// is the kind of request a comment cannot enforce.
abstract final class ShellBranch {
  static const int feed = 0;
  static const int reels = 1;
  static const int dashboard = 2;
  static const int jobs = 3;
  static const int network = 4;
  static const int companyJobs = 5;
  static const int companyApplicants = 6;
  static const int companyProfile = 7;
  static const int companyDashboard = 8;
}

/// Bumped when a tab is tapped while it is ALREADY the tab on screen.
///
/// The shell answers a re-tap by popping that branch to its root, which is
/// right and is not what people expect from the gesture. On every app with a
/// feed, tapping the tab you are on means "take me back to the top and get me
/// the new things" — so the shell publishes the event and the screen decides
/// what its own top is: the first post for the feed, the first reel for reels.
///
/// A counter rather than a flag, because two taps in a row are two requests and
/// a bool would swallow the second. Keyed by branch so a re-tap on Home cannot
/// wake the reels player, which would start a video on a screen nobody is
/// looking at.
final shellRetapProvider = StateProvider.family<int, int>((ref, branch) => 0);
