import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/base/base_list_notifier.dart';
import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

/// The home feed. Engagement toggles apply optimistically and roll back on
/// failure so a tap never feels laggy but never lies either.
class FeedNotifier extends BaseListNotifier<Post> {
  @override
  BaseRepository<Post> get repository => ref.read(postRepositoryProvider);

  PostRepository get _posts => ref.read(postRepositoryProvider);

  /// Where the next page starts. The home feed is cursor-paged, not
  /// page-numbered — see [FeedCursor].
  FeedCursor _cursor = FeedCursor.first;
  bool _hasMore = true;
  bool _loadingMore = false;

  /// Bumped by every (re)load of page one, so a [loadMore] that was in flight
  /// across a refresh drops its now-stale page instead of appending rows from
  /// the old order onto the new one.
  int _generation = 0;

  /// While page one is loading, [loadMore] waits: the cursor it would page
  /// from belongs to the order being replaced.
  bool _loadingFirstPage = false;

  static final _random = math.Random();

  /// A new shuffle seed — see [FeedCursor.seed].
  static int _newSeed() => _random.nextInt(1 << 31);

  /// Page one under a fresh seed. The cursor it returns is what [loadMore]
  /// continues from — it used to stay at [FeedCursor.first], so the first
  /// scroll re-downloaded page one and de-duplication hid the waste.
  Future<List<Post>> _loadFirstPage() async {
    final generation = ++_generation;
    _loadingFirstPage = true;
    final Result<FeedPage, AppException> result;
    try {
      result =
          await _posts.homeFeed(cursor: FeedCursor.firstWithSeed(_newSeed()));
    } finally {
      if (generation == _generation) _loadingFirstPage = false;
    }
    return result.when(
      success: (page) {
        if (generation == _generation) {
          _cursor = page.next;
          _hasMore = page.hasMore;
        }
        return page.posts;
      },
      failure: (e) => throw e,
    );
  }

  @override
  Future<List<Post>> build() {
    _cursor = FeedCursor.first;
    _hasMore = true;
    return _loadFirstPage();
  }

  /// Pull-to-refresh: a new seed, so the feed comes back in a new order.
  ///
  /// The current list stays on screen while the new one loads — the
  /// RefreshIndicator is the progress signal, and blanking the feed to a
  /// skeleton under the user's thumb is what the base class would do. A
  /// failed refresh keeps the old list rather than replacing it with an error.
  @override
  Future<void> refresh() async {
    final hadData = state.hasValue;
    // From an error screen there is no list to keep; show the skeleton.
    if (!hadData) state = const AsyncValue.loading();
    try {
      final previous = state.valueOrNull ?? const <Post>[];
      final posts = await _loadFirstPage();
      state = AsyncValue.data(_reshuffleIfUnchanged(previous, posts));
    } catch (e, st) {
      if (!hadData) state = AsyncValue.error(e, st);
    }
  }

  /// Re-orders the refreshed page when the server handed back the SAME posts
  /// in the SAME order.
  ///
  /// The server reshuffles a seeded refresh itself, which is the version that
  /// knows what is worth reading. This is the safety net for when it cannot:
  /// a deployment that predates the seed, or a feed so small that ranking has
  /// only one sensible order for it. A refresh that visibly does nothing reads
  /// as a refresh that failed.
  ///
  /// Posts only ever move into a slot held by a post of the SAME kind: the
  /// page arrives alternating suggested / followed / suggested / followed, and
  /// a plain neighbour swap would break that pattern on every refresh. So the
  /// two kinds are shuffled among their own slots and the pattern survives.
  static List<Post> _reshuffleIfUnchanged(List<Post> previous, List<Post> next) {
    if (next.length < 2) return next;
    // The previous list may be longer (pages appended by loadMore); it is the
    // FIRST page that just came back, so compare that much of it.
    if (previous.length < next.length) return next;
    for (var i = 0; i < next.length; i++) {
      if (previous[i].id != next[i].id) return next;
    }

    final shuffled = [...next];
    for (final suggested in const [true, false]) {
      final slots = [
        for (var i = 0; i < shuffled.length; i++)
          if (shuffled[i].suggested == suggested) i,
      ];
      if (slots.length < 2) continue;
      final picked = [for (final i in slots) shuffled[i]]..shuffle(_random);
      // A shuffle may hand back the order it was given, and with two rows of a
      // kind that is a one-in-two chance of a refresh that moves nothing — the
      // very thing this method exists to avoid. Rotate instead of re-rolling:
      // it always changes, and cannot loop.
      if (picked[0].id == shuffled[slots.first].id) {
        picked.add(picked.removeAt(0));
      }
      for (var k = 0; k < slots.length; k++) {
        shuffled[slots[k]] = picked[k];
      }
    }
    return shuffled;
  }

  /// False once the server says there is nothing after the current page.
  bool get hasMore => _hasMore;

  /// Appends the next page. Safe to call on every scroll tick: overlapping and
  /// past-the-end calls return without a request.
  ///
  /// A failure leaves the loaded feed alone and keeps the cursor where it was,
  /// so the next call retries the same page rather than skipping it.
  Future<void> loadMore() async {
    if (_loadingMore || _loadingFirstPage || !_hasMore) return;
    _loadingMore = true;
    final generation = _generation;
    try {
      final result = await _posts.homeFeed(cursor: _cursor);
      // Refreshed meanwhile: this page belongs to the old order.
      if (generation != _generation) return;
      result.when(
        success: (page) {
          _cursor = page.next;
          _hasMore = page.hasMore;
          final existing = state.valueOrNull ?? const <Post>[];
          // The two feed sources can overlap — a recommended post may also
          // have been fanned out — so de-duplicate on id rather than trusting
          // the pages to be disjoint.
          final seen = {for (final p in existing) p.id};
          state = AsyncValue.data([
            ...existing,
            ...page.posts.where((p) => seen.add(p.id)),
          ]);
        },
        failure: (_) {},
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<Result<Post, AppException>> toggleLike(String postId) =>
      _optimistic(postId, (p) => p.toggleLike(), _posts.toggleLike);

  Future<Result<Post, AppException>> toggleSave(String postId) =>
      _optimistic(postId, (p) => p.toggleSave(), _posts.toggleSave);

  /// Reposts a post. Not really a toggle: the module has no un-share, and a
  /// second `Posts/Share` is refused server-side, so an already-reposted post
  /// short-circuits instead of optimistically flipping back.
  Future<Result<Post, AppException>> toggleRepost(String postId) {
    final existing = state.valueOrNull?.where((p) => p.id == postId);
    if (existing != null && existing.isNotEmpty && existing.first.reposted) {
      return Future.value(
        const Result.failure(
          ValidationException('لقد أعدت نشر هذا المنشور من قبل'),
        ),
      );
    }
    return _optimistic(postId, (p) => p.toggleRepost(), _posts.toggleRepost);
  }

  /// Publishes a post and prepends it so the author sees it immediately.
  ///
  /// Hashtags are parsed from [text] by the backend — there is no tags
  /// argument to pass through.
  Future<Result<Post, AppException>> publish({
    required String text,
    required PostVisibility visibility,
    List<PostMedia> media = const [],
    PollDraft? poll,
  }) async {
    final result = await _posts.publish(
      text: text,
      visibility: visibility,
      media: media,
      poll: poll,
    );
    result.when(
      success: (created) {
        state = AsyncValue.data([created, ...state.valueOrNull ?? const []]);
      },
      failure: (_) {},
    );
    return result;
  }

  /// Keeps the feed row in step with a change made on the detail screen — or
  /// with an edit made from the card's own options sheet.
  void applyServerPost(Post updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == updated.id ? updated : p,
    ]);
  }

  /// Writes a poll's new counts into its row, leaving everything else on the
  /// row as the feed has it.
  void applyPoll(String postId, Poll poll) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == postId ? p.copyWith(poll: poll) : p,
    ]);
  }

  /// Drops a row whose post no longer exists.
  ///
  /// No refetch: the author just deleted it, and re-reading the page to prove
  /// it is gone would replace the whole feed under them.
  void removePost(String postId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current)
        if (p.id != postId) p,
    ]);
  }

  Future<Result<Post, AppException>> _optimistic(
    String postId,
    Post Function(Post) transform,
    Future<Result<Post, AppException>> Function(String) call,
  ) async {
    final previous = state.valueOrNull;
    if (previous == null) return call(postId);

    state = AsyncValue.data([
      for (final p in previous) p.id == postId ? transform(p) : p,
    ]);

    final result = await call(postId);
    return result.when(
      success: (server) {
        applyServerPost(server);
        return Result<Post, AppException>.success(server);
      },
      failure: (e) {
        state = AsyncValue.data(previous);
        return Result<Post, AppException>.failure(e);
      },
    );
  }
}

final feedNotifierProvider =
    AsyncNotifierProvider<FeedNotifier, List<Post>>(FeedNotifier.new);
