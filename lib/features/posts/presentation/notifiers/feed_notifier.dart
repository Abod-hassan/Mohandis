import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/base/base_list_notifier.dart';
import 'package:flutter_mobile_template/core/base/base_repository.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

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

  /// False once the server says there is nothing after the current page.
  bool get hasMore => _hasMore;

  /// Appends the next page. Safe to call on every scroll tick: overlapping and
  /// past-the-end calls return without a request.
  ///
  /// A failure leaves the loaded feed alone and keeps the cursor where it was,
  /// so the next call retries the same page rather than skipping it.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final result = await _posts.homeFeed(cursor: _cursor);
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
  }) async {
    final result = await _posts.publish(
      text: text,
      visibility: visibility,
      media: media,
    );
    result.when(
      success: (created) {
        state = AsyncValue.data([created, ...state.valueOrNull ?? const []]);
      },
      failure: (_) {},
    );
    return result;
  }

  /// Keeps the feed row in step with a change made on the detail screen.
  void applyServerPost(Post updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == updated.id ? updated : p,
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
