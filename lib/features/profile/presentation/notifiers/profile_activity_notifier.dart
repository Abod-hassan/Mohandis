import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/posts/data/repositories/post_repository_impl.dart';
import 'package:flutter_mobile_template/features/posts/domain/repositories/post_repository.dart';
import 'package:flutter_mobile_template/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:flutter_mobile_template/features/posts/domain/entities/comment.dart';
import 'package:flutter_mobile_template/features/posts/domain/entities/post.dart';

/// A profile's own posts and comments — what the activity section shows.
class ProfileActivity {
  const ProfileActivity({required this.posts, required this.comments});

  static const ProfileActivity empty = ProfileActivity(
    posts: [],
    comments: [],
  );

  final List<Post> posts;
  final List<Comment> comments;

  bool get isEmpty => posts.isEmpty && comments.isEmpty;
}

/// One page of each, keyed by person id.
///
/// autoDispose: this is someone else's profile most of the time, and holding
/// every profile visited for the life of the app is a lot of posts to keep for
/// screens nobody is looking at.
final profileActivityProvider =
    FutureProvider.autoDispose.family<ProfileActivity, String>((
  ref,
  personId,
) async {
  final repository = ref.watch(postRepositoryProvider);

  // Both in flight at once — the section renders as one card, and asking in
  // series would make the tab that happens to be second wait for the first.
  final postsRequest = repository.byAuthor(personId, size: 10);
  final commentsRequest = repository.commentsByAuthor(personId, size: 10);

  // A failure on either side degrades to an empty tab rather than erroring the
  // whole profile: the CV below it is worth showing regardless.
  final posts = (await postsRequest).valueOrNull ?? const <Post>[];
  final comments = (await commentsRequest).valueOrNull ?? const <Comment>[];

  return ProfileActivity(posts: posts, comments: comments);
});

/// How many rows each page of the full activity screen asks for.
const int kActivityPageSize = 20;

/// The full, paged activity list behind "show all".
///
/// Separate from [profileActivityProvider], which is the section's fixed
/// preview: this one grows, and the two would fight over a shared cache entry.
class ProfileActivityFeed extends AutoDisposeFamilyAsyncNotifier<
    ProfileActivity, String> {
  int _postsPage = 1;
  int _commentsPage = 1;
  bool _morePosts = true;
  bool _moreComments = true;
  bool _loading = false;

  bool get hasMorePosts => _morePosts;
  bool get hasMoreComments => _moreComments;

  @override
  Future<ProfileActivity> build(String personId) async {
    final repository = ref.watch(postRepositoryProvider);
    final postsRequest =
        repository.byAuthor(personId, size: kActivityPageSize);
    final commentsRequest =
        repository.commentsByAuthor(personId, size: kActivityPageSize);

    final posts = (await postsRequest).valueOrNull ?? const <Post>[];
    final comments = (await commentsRequest).valueOrNull ?? const <Comment>[];

    _postsPage = 1;
    _commentsPage = 1;
    // A short page means the end. The list reads lose `hasMore` — `apiCall`
    // decodes `data` and the flag rides on the envelope — so this is inferred
    // rather than read. Worst case is one extra request that returns nothing.
    _morePosts = posts.length >= kActivityPageSize;
    _moreComments = comments.length >= kActivityPageSize;

    return ProfileActivity(posts: posts, comments: comments);
  }

  Future<void> loadMorePosts() async {
    if (_loading || !_morePosts) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _loading = true;
    final next = _postsPage + 1;
    final result = await ref
        .read(postRepositoryProvider)
        .byAuthor(arg, page: next, size: kActivityPageSize);
    _loading = false;

    final rows = result.valueOrNull;
    if (rows == null) return;
    _postsPage = next;
    _morePosts = rows.length >= kActivityPageSize;
    if (rows.isEmpty) return;

    // Posts can repeat across pages when one is published mid-scroll and
    // shifts the offsets; appending blind would duplicate a card.
    final seen = {for (final p in current.posts) p.id};
    final fresh = rows.where((p) => !seen.contains(p.id)).toList(growable: false);
    if (fresh.isEmpty) return;
    state = AsyncValue.data(
      ProfileActivity(
        posts: [...current.posts, ...fresh],
        comments: current.comments,
      ),
    );
  }

  Future<void> loadMoreComments() async {
    if (_loading || !_moreComments) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _loading = true;
    final next = _commentsPage + 1;
    final result = await ref
        .read(postRepositoryProvider)
        .commentsByAuthor(arg, page: next, size: kActivityPageSize);
    _loading = false;

    final rows = result.valueOrNull;
    if (rows == null) return;
    _commentsPage = next;
    _moreComments = rows.length >= kActivityPageSize;
    if (rows.isEmpty) return;

    final seen = {for (final c in current.comments) c.id};
    final fresh = rows.where((c) => !seen.contains(c.id)).toList(growable: false);
    if (fresh.isEmpty) return;
    state = AsyncValue.data(
      ProfileActivity(
        posts: current.posts,
        comments: [...current.comments, ...fresh],
      ),
    );
  }

  /// Likes a post from the activity list.
  ///
  /// These have to live here rather than being borrowed from `FeedNotifier`:
  /// that one owns the home feed's list, and its optimistic patch would land on
  /// a list this screen is not showing. The feed is still told, so backing out
  /// to it doesn't show a stale count.
  /// Each answers whether the write actually landed.
  ///
  /// The card toasts off these, and a `Future<void>` gave it nothing to check —
  /// so "تم إعادة النشر" was shown for a repost that had failed, and for one
  /// that never left the device at all.
  Future<bool> toggleLike(String postId) =>
      _mutate(postId, (r) => r.toggleLike(postId));

  Future<bool> toggleRepost(String postId) =>
      _mutate(postId, (r) => r.toggleRepost(postId));

  Future<bool> toggleSave(String postId) =>
      _mutate(postId, (r) => r.toggleSave(postId));

  Future<bool> _mutate(
    String postId,
    Future<Result<Post, AppException>> Function(PostRepository) call,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    final result = await call(ref.read(postRepositoryProvider));
    return result.when(
      success: (server) {
        state = AsyncValue.data(
          ProfileActivity(
            posts: [
              for (final p in current.posts) p.id == server.id ? server : p,
            ],
            comments: current.comments,
          ),
        );
        ref.read(feedNotifierProvider.notifier).applyServerPost(server);
        return true;
      },
      failure: (_) => false,
    );
  }
}

final profileActivityFeedProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileActivityFeed, ProfileActivity, String>(
  ProfileActivityFeed.new,
);

/// Which tab the activity section is showing, per profile.
final profileActivityTabProvider =
    StateProvider.autoDispose.family<ProfileActivityTab, String>(
  (ref, personId) => ProfileActivityTab.posts,
);

enum ProfileActivityTab { posts, comments }
