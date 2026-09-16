import 'post.dart';

/// Where the next home-feed page starts.
///
/// The feed blends two independently-paged sources — the Cassandra fan-out
/// inbox ([bucket] + [beforeEventTime]) and the Postgres recommendation pool
/// ([recommendationOffset]) — so all three values travel together. Dropping
/// any one of them re-serves rows the user has already seen.
class FeedCursor {
  const FeedCursor({
    this.bucket,
    this.beforeEventTime,
    this.recommendationOffset = 0,
  });

  /// The `yyyy-MM` Cassandra partition the previous page was read from.
  final String? bucket;

  /// Clustering-key cursor within [bucket]. Null once the inbox is exhausted —
  /// which does not mean the feed has ended, recommendations may continue.
  final String? beforeEventTime;

  final int recommendationOffset;

  /// The first page: no cursors at all.
  static const FeedCursor first = FeedCursor();

  bool get isFirstPage =>
      bucket == null && beforeEventTime == null && recommendationOffset == 0;

  Map<String, dynamic> toRequest(int pageSize) => {
    if (bucket != null) 'bucket': bucket,
    if (beforeEventTime != null) 'beforeEventTime': beforeEventTime,
    'recommendationOffset': recommendationOffset,
    'pageSize': pageSize,
  };
}

/// One page of the home feed.
class FeedPage {
  const FeedPage({
    required this.posts,
    required this.next,
    required this.hasMore,
  });

  static const FeedPage empty = FeedPage(
    posts: [],
    next: FeedCursor.first,
    hasMore: false,
  );

  /// Renderable rows only. Reels, job cards and ads are filtered out by the
  /// repository, so this can be shorter than the page size the server was
  /// asked for — [hasMore], not the length, is the end-of-feed signal.
  final List<Post> posts;

  final FeedCursor next;
  final bool hasMore;
}
