import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mohandis/features/posts/domain/repositories/post_repository.dart';
import 'package:mohandis/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:mohandis/features/posts/domain/entities/comment.dart';
import 'package:mohandis/features/reels/data/repositories/reel_repository_impl.dart';
import 'package:mohandis/features/reels/domain/entities/reel.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';

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

  /// Replaces one row after an edit made from the card's options sheet.
  void applyServerPost(Post updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      ProfileActivity(
        posts: [
          for (final p in current.posts) p.id == updated.id ? updated : p,
        ],
        comments: current.comments,
      ),
    );
    ref.read(feedNotifierProvider.notifier).applyServerPost(updated);
  }

  /// Drops a deleted row, here and in the home feed.
  void removePost(String postId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      ProfileActivity(
        posts: [
          for (final p in current.posts)
            if (p.id != postId) p,
        ],
        comments: current.comments,
      ),
    );
    ref.read(feedNotifierProvider.notifier).removePost(postId);
  }

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

/// One page of a profile's reels, for the profile's Reels tab.
///
/// Keyed by the REAL ProfileId, not the `me` route alias: the filter is a
/// server-side `authorIds`, and the server has never heard of `me`.
///
/// **Filtered again on the way out, and that is not belt-and-braces.** This
/// grid is an assertion about one person — these are their reels — and the
/// only thing standing behind it is that a filter in a request body was
/// honoured. When it is not, the failure is silent and wrong in the worst
/// direction: the wall arrives, the grid renders it, and a profile shows
/// strangers' videos as that person's work. A row whose `authorId` is not this
/// profile has no business here no matter what produced it, so it is dropped
/// rather than drawn. An empty grid is a visible, reportable bug; somebody
/// else's reel under somebody's name is not.
///
/// autoDispose, like the activity above and for the same reason — this is
/// somebody else's profile most of the time.
final profileReelsProvider =
    FutureProvider.autoDispose.family<List<Reel>, String>((ref, profileId) async {
  final result = await ref.watch(reelRepositoryProvider).getAll(
    query: {'authorIds': [profileId]},
  );
  // Case-insensitive: both sides are the same Guid, but one travels as JSON
  // written by the server and the other through the profile payload, and a
  // casing difference between them would empty the grid rather than scope it.
  final mine = profileId.toLowerCase();
  return result.when(
    success: (rows) {
      final kept = [
        for (final reel in rows)
          if (reel.authorId.toLowerCase() == mine) reel,
      ];

      // Says out loud what the server did with `authorIds`, because the two
      // ways this goes wrong look identical on screen — an unfiltered wall and
      // a correctly filtered one both render as "reels I do not recognise" when
      // the posters fail to load. `asked` is what was sent; `authors` is what
      // came back. One line of log separates "the filter was ignored" from
      // "these really are this profile's reels".
      final authors = {for (final r in rows) r.authorId}.toList();
      ref.read(loggerProvider).d(
        '[profile] reels asked=$mine got=${rows.length} kept=${kept.length} '
        'authors=$authors '
        'firstVideo=${rows.isEmpty ? '-' : rows.first.videoUrl} '
        'firstPoster=${rows.isEmpty ? '-' : rows.first.posterPath}',
      );
      return kept;
    },
    failure: (e) => throw e,
  );
});
