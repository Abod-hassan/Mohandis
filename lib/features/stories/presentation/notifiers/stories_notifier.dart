import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/base/base_list_notifier.dart';
import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../data/repositories/story_repository_impl.dart';
import '../../domain/entities/story.dart';

class StoriesNotifier extends BaseListNotifier<Story> {
  @override
  BaseRepository<Story> get repository => ref.read(storyRepositoryProvider);

  /// Publishes a story and puts it at the head of the rail.
  ///
  /// Not [createOptimistic]: that appends a placeholder, and the rail is
  /// ordered — an optimistic story would appear at the far end, away from the
  /// "your story" position it lands in a moment later. A story publishes in
  /// one request against a file that is already on the CDN, so the wait is
  /// short enough to simply wait.
  ///
  /// [caption] is trimmed and dropped when empty; the endpoint treats a blank
  /// caption and no caption the same way, and sending `""` only writes an
  /// empty string into a nullable column.
  Future<Result<Story, AppException>> publish({
    required String mediaUrl,
    required bool isVideo,
    String caption = '',
  }) async {
    final result = await ref.read(storyRepositoryProvider).create({
      'mediaUrl': mediaUrl,
      'isVideo': isVideo,
      'caption': caption.trim(),
    });

    result.when(
      success: (story) {
        // Never a one-item list over a loading or failed state: that would
        // show a rail the read never returned, and hide the error that is the
        // reason it is empty.
        final current = state.valueOrNull;
        if (current == null) {
          // Still loading, or failed. The read that is in flight was ISSUED
          // BEFORE this publish committed, so its page cannot contain the new
          // row — and letting it land would publish a list that silently omits
          // what was just posted. Re-running it is the only honest answer.
          //
          // This is the common case, not the edge one: reading `.notifier` to
          // call this method is itself what starts the first load.
          ref.invalidateSelf();
          return;
        }
        state = AsyncValue.data([story, ...current]);
      },
      failure: (_) {},
    );
    return result;
  }

  /// Flips the ring to "seen" immediately, then reconciles with the server.
  /// A failure is intentionally silent — a lost read-receipt must not throw an
  /// error banner over a story the user is already watching — but the
  /// optimistic flip is rolled back, so the ring never claims a view the
  /// server did not record.
  ///
  /// The view is sent whether or not the rail has loaded: the viewer opens
  /// straight from a link or a notification too, and a view withheld until
  /// there is a list to flip is a view that is never counted.
  Future<void> markSeen(String storyId) async {
    // The row as it was, not the LIST as it was. A group of stories is watched
    // one after another, so several of these overlap — and restoring a
    // whole-list snapshot on one failure would un-see the stories that
    // succeeded either side of it, and throw away a publish that landed in the
    // same window.
    Story? previous;
    final before = state.valueOrNull;
    if (before != null) {
      for (final s in before) {
        if (s.id == storyId) previous = s;
      }
      state = AsyncValue.data([
        for (final s in before) s.id == storyId ? s.copyWith(seen: true) : s,
      ]);
    }

    final result = await ref.read(storyRepositoryProvider).markSeen(storyId);
    result.when(
      success: (server) {
        // Still loading, or failed — there is no list to reconcile, and
        // publishing one here would show a rail the read never returned.
        final current = state.valueOrNull;
        if (current == null) return;
        state = AsyncValue.data([
          for (final s in current) s.id == server.id ? server : s,
        ]);
      },
      failure: (_) {
        final rollback = previous;
        final current = state.valueOrNull;
        if (rollback == null || current == null) return;
        state = AsyncValue.data([
          for (final s in current) s.id == rollback.id ? rollback : s,
        ]);
      },
    );
  }

  /// Writes a like the viewer just made (or the server just confirmed) into
  /// the rail, so leaving the viewer and opening the story again shows the
  /// same heart. A story that is not on the rail is left alone.
  void applyLike(String storyId, {required bool liked, required int likeCount}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final s in current)
        s.id == storyId ? s.copyWith(liked: liked, likeCount: likeCount) : s,
    ]);
  }
}

/// One story by id, for a viewer opened outside the rail — a push
/// notification, a shared link, an author the viewer does not follow. The
/// rail's read is `followedOnly`, so it is not a superset of what the viewer
/// can be asked to show.
final storyByIdProvider = FutureProvider.family<Story, String>((ref, id) async {
  final result = await ref.watch(storyRepositoryProvider).getById(id);
  return result.when(success: (story) => story, failure: (e) => throw e);
});

final storiesNotifierProvider =
    AsyncNotifierProvider<StoriesNotifier, List<Story>>(StoriesNotifier.new);
