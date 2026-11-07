import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';

/// What the button beside a suggested post's author name is currently showing.
enum SuggestedActionState {
  /// Nothing sent yet — the button invites the action.
  idle,

  /// In flight. The button is disabled so a double tap cannot raise two edges.
  busy,

  /// Done. A connection request is pending, or the follow now exists.
  done,
}

/// Tracks, per author, whether this session has already acted on a suggestion.
///
/// Feed rows carry no viewer-relative relationship flags — `FeedItemDto` has no
/// `isFollowing` or `isConnected`, and adding them would mean a per-author join
/// on every feed read. So the button's state after a tap is remembered here
/// instead, keyed by ProfileId.
///
/// Session-scoped by design: a reload re-reads the feed but not the graph, so
/// the honest reset point is sign-out. It is on `_dropSessionCaches`, since a
/// second account on the same device must not inherit the first one's "sent".
class SuggestedActions extends Notifier<Map<String, SuggestedActionState>> {
  @override
  Map<String, SuggestedActionState> build() => const {};

  SuggestedActionState stateFor(String personId) =>
      state[personId] ?? SuggestedActionState.idle;

  /// Follows somebody from a suggested-person card.
  ///
  /// [isCompany] no longer changes the call — it used to pick between a
  /// connection request and a follow, and connections were withdrawn from the
  /// app — but the card still passes it, and the label it chooses ("متابعة"
  /// either way) is the caller's business.
  Future<Result<void, AppException>> act({
    required String personId,
    // ignore: avoid_unused_constructor_parameters
    required bool isCompany,
  }) async {
    if (stateFor(personId) != SuggestedActionState.idle) {
      return const Result.success(null);
    }
    state = {...state, personId: SuggestedActionState.busy};

    final repo = ref.read(profileRepositoryProvider);
    // Follow, whoever they are. This used to send a connection request to a
    // person and follow only companies; connections were withdrawn from the
    // app, and following is the one relationship it has.
    //
    // `isFollowing: false` says which way the toggle is going, so the
    // repository does not have to read the profile first to find out.
    final result = await repo.toggleFollow(personId, isFollowing: false);

    state = {
      ...state,
      personId: result.isSuccess
          ? SuggestedActionState.done
          // Back to idle, not stuck on busy: a failed tap has to be retryable.
          : SuggestedActionState.idle,
    };
    return result.map<void>((_) {});
  }
}

final suggestedActionsProvider =
    NotifierProvider<SuggestedActions, Map<String, SuggestedActionState>>(
      SuggestedActions.new,
    );
