import 'package:flutter_mobile_template/core/base/base_dto.dart';

import '../../domain/entities/post.dart';

/// Wire model for the backend's `PostDto` (`POST /api/social/Posts`,
/// `Posts/Publish`, `Posts/Share`, `Posts/Like`).
///
/// Field names follow the C# DTO, not the mobile entity: the text is
/// `content`, the like flag is `isLiked`, and `visibility` is an **integer**
/// ordinal rather than a string.
class PostDto implements BaseDto<Post> {
  const PostDto({
    required this.id,
    required this.authorId,
    required this.createdAt,
    required this.visibility,
    required this.content,
    this.authorName = '',
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.media = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isShared = false,
    this.sharedPostId,
    this.sharedPost,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    final shared = json['sharedPost'];
    return PostDto(
      id: '${json['id'] ?? ''}',
      authorId: '${json['authorId'] ?? ''}',
      authorName: '${json['authorName'] ?? ''}',
      authorUsername: json['authorUsername'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorIsVerified: json['authorIsVerified'] == true,
      createdAt: parseDate(json['createdAt']),
      visibility: visibilityFromWire(json['visibility']),
      content: '${json['content'] ?? ''}',
      media: mediaFrom(json['media']),
      likeCount: asInt(json['likeCount']),
      commentCount: asInt(json['commentCount']),
      viewCount: asInt(json['viewCount']),
      shareCount: asInt(json['shareCount']),
      isLiked: json['isLiked'] == true,
      isSaved: json['isSaved'] == true,
      isShared: json['isShared'] == true,
      sharedPostId: json['sharedPostId'] as String?,
      sharedPost: shared is Map<String, dynamic> ? quotedFrom(shared) : null,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final DateTime createdAt;
  final PostVisibility visibility;
  final String content;
  final List<PostMedia> media;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int shareCount;
  final bool isLiked;

  /// Whether the viewer has bookmarked this post.
  final bool isSaved;

  /// Whether the viewer has already reposted this post — a repost of theirs
  /// points at it. One repost per person, so this also disables the control.
  final bool isShared;

  final String? sharedPostId;
  final QuotedPost? sharedPost;

  @override
  Post toDomain() => Post(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    authorVerified: authorIsVerified,
    createdAt: createdAt,
    visibility: visibility,
    text: content,
    tags: hashtagsIn(content),
    media: media,
    likeCount: likeCount,
    liked: isLiked,
    commentCount: commentCount,
    repostCount: shareCount,
    viewCount: viewCount,
    saved: isSaved,
    reposted: isShared,
    quoted: sharedPost,
    repostedById: sharedPost != null ? authorId : null,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'visibility': visibilityToWire(visibility),
    'content': content,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'viewCount': viewCount,
    'shareCount': shareCount,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'isShared': isShared,
    'sharedPostId': sharedPostId,
  };

  // ── Wire helpers, shared with FeedItemDto ────────────────────────────────

  /// `PostVisibilityEnum` — `0` public, `1` followers, `2` private.
  ///
  /// Accepts the string form too: a host that registers
  /// `JsonStringEnumConverter` serialises these as names. An unknown value
  /// falls back to public rather than throwing — a new server-side visibility
  /// must never crash an old client.
  static PostVisibility visibilityFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < PostVisibility.values.length
          ? PostVisibility.values[i]
          : PostVisibility.public;
    }
    return switch ('$raw'.toLowerCase()) {
      'followers' || '1' => PostVisibility.followers,
      'private' || '2' => PostVisibility.private,
      _ => PostVisibility.public,
    };
  }

  /// Publish/Share send the ordinal — `PostVisibilityEnum` is a plain int enum
  /// on the wire.
  static int visibilityToWire(PostVisibility v) => v.index;

  /// `MediaKindEnum` is `0` image / `1` video. Sorted by `position`, which is
  /// the order the author arranged, not the order the rows came back in.
  static List<PostMedia> mediaFrom(Object? raw) {
    if (raw is! List) return const [];
    final items = raw.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) => asInt(a['position']).compareTo(asInt(b['position'])));
    return items.map((m) {
      final w = (m['width'] as num?)?.toDouble();
      final h = (m['height'] as num?)?.toDouble();
      return PostMedia(
        // Post media rows are int-keyed; feed rows carry no id at all, so fall
        // back to the URL — it only has to be stable within one post.
        id: '${m['id'] ?? m['url'] ?? ''}',
        url: m['url'] as String?,
        thumbnailUrl: m['thumbnailUrl'] as String?,
        aspectRatio: (w != null && h != null && h > 0) ? w / h : 1,
        kind: mediaKindFrom(m['kind']),
        durationSeconds: (m['durationSeconds'] as num?)?.toDouble(),
        width: w?.round(),
        height: h?.round(),
        fileName: m['fileName'] as String?,
        sizeBytes: (m['sizeBytes'] as num?)?.toInt(),
      );
    }).toList(growable: false);
  }

  /// Builds the quote embed from a `PostSimplifiedDto` (`sharedPost`).
  static QuotedPost quotedFrom(Map<String, dynamic> json) => QuotedPost(
    id: '${json['id'] ?? ''}',
    authorId: '${json['authorId'] ?? ''}',
    authorName: '${json['authorName'] ?? ''}',
    authorAvatarUrl: json['authorAvatarUrl'] as String?,
    text: '${json['content'] ?? ''}',
    // `PostSimplifiedDto` collapses the media list to its first url — enough
    // for the embed, and the reason a shared post can show a picture at all.
    firstMediaUrl: json['firstMediaUrl'] as String?,
    createdAt: parseDate(json['createdAt']),
  );

  /// The backend keeps hashtags in their own table, parsed out of the content —
  /// they are not a field on the post — so the client re-derives them.
  ///
  /// The `#` is kept: `RungHashtag` renders the string verbatim.
  static List<String> hashtagsIn(String content) => RegExp(
    r'#[\p{L}\p{N}_]+',
    unicode: true,
  ).allMatches(content).map((m) => m.group(0)!).toSet().toList(growable: false);

  /// Reads an ASP.NET timestamp.
  ///
  /// `DateTime` columns come back as UTC (`DateTime.UtcNow`) but serialise
  /// WITHOUT a `Z`, so an unmarked value is interpreted as UTC rather than as
  /// device-local — otherwise every timestamp is off by the device's offset,
  /// which in Baghdad reads as "3 hours ago" on a post made seconds ago.
  /// `DateTimeOffset` fields do carry an offset and are honoured as sent.
  static DateTime parseDate(Object? raw) {
    final text = '$raw';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return DateTime.now();
    final hasZone =
        text.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);
    if (hasZone) return parsed.toLocal();
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
    ).toLocal();
  }

  static int asInt(Object? raw) => (raw as num?)?.toInt() ?? 0;

  /// `MediaKindEnum` — image or video.
  ///
  /// The host registers Newtonsoft's `StringEnumConverter`, so a C# enum comes
  /// back as its NAME (`"Video"`), while the feed store's media rows type the
  /// same field as `sbyte` and send `1`. Both spellings have to be read, or
  /// every video in the feed renders as a still image.
  static bool isVideoKind(Object? raw) => mediaKindFrom(raw) == MediaKind.video;

  /// The full kind. Anything unrecognised reads as an image — the safe default
  /// for a renderer, since an image tile shows whatever is at the URL, where a
  /// document tile would promise a download that may not be one.
  static MediaKind mediaKindFrom(Object? raw) {
    if (raw is num) {
      return switch (raw.toInt()) {
        1 => MediaKind.video,
        2 => MediaKind.document,
        _ => MediaKind.image,
      };
    }
    return switch ('$raw'.toLowerCase()) {
      'video' => MediaKind.video,
      'document' => MediaKind.document,
      _ => MediaKind.image,
    };
  }

  /// The integer the server persists. Sent as a number rather than a name
  /// because the publish input binds it either way and a number cannot be
  /// mis-cased.
  static int mediaKindToWire(MediaKind kind) => switch (kind) {
    MediaKind.image => 0,
    MediaKind.video => 1,
    MediaKind.document => 2,
  };
}

/// Wire model for `FeedItemDto` — one row of the ranked home feed
/// (`POST /api/social/Feed`).
///
/// Deliberately not the same shape as [PostDto]: a feed row is a denormalized
/// snapshot from the Cassandra fan-out store (or the Postgres recommendation
/// pool, or an ad), so it is keyed by `itemId` rather than `id` and the
/// author's avatar arrives as `authorAvatar`. Engagement counts and
/// `isLiked`/`isSaved` are NOT stored in the feed store — the backend fills
/// them per page from Postgres, so they are live.
class FeedItemDto {
  const FeedItemDto({
    required this.itemId,
    required this.itemType,
    required this.authorId,
    required this.source,
    this.authorName = '',
    this.authorAvatar,
    this.content = '',
    this.media = const [],
    this.visibility = PostVisibility.public,
    this.sharedPostId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isShared = false,
    this.sharedPost,
    this.seen = false,
    this.createdAt,
    this.title,
    this.companyName,
    this.boostId,
  });

  factory FeedItemDto.fromJson(Map<String, dynamic> json) => FeedItemDto(
    itemId: '${json['itemId'] ?? ''}',
    itemType: PostDto.asInt(json['itemType']),
    source: '${json['source'] ?? ''}',
    authorId: '${json['authorId'] ?? ''}',
    authorName: '${json['authorName'] ?? ''}',
    authorAvatar: json['authorAvatar'] as String?,
    content: '${json['content'] ?? ''}',
    media: PostDto.mediaFrom(json['media']),
    visibility: PostDto.visibilityFromWire(json['visibility']),
    sharedPostId: json['sharedPostId'] as String?,
    likeCount: PostDto.asInt(json['likeCount']),
    commentCount: PostDto.asInt(json['commentCount']),
    viewCount: PostDto.asInt(json['viewCount']),
    shareCount: PostDto.asInt(json['shareCount']),
    isLiked: json['isLiked'] == true,
    isSaved: json['isSaved'] == true,
    isShared: json['isShared'] == true,
    sharedPost: json['sharedPost'] is Map<String, dynamic>
        ? PostDto.quotedFrom(json['sharedPost'] as Map<String, dynamic>)
        : null,
    seen: json['seen'] == true,
    createdAt: json['createdAt'] == null
        ? null
        : PostDto.parseDate(json['createdAt']),
    title: json['title'] as String?,
    companyName: json['companyName'] as String?,
    boostId: (json['boostId'] as num?)?.toInt(),
  );

  /// `0` post, `1` repost, `2` reel, `3` job, `4` ad.
  final int itemType;
  final String itemId;

  /// `FanoutWrite` / `FanoutRead` / `Recommendation` / `Ad` — where the row
  /// came from. Informational; it does not change how the row renders.
  final String source;

  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<PostMedia> media;
  final PostVisibility visibility;
  final String? sharedPostId;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final bool isShared;

  /// The original, when this row is a repost. Filled server-side alongside the
  /// counters — the fanned-out Cassandra row itself carries only the id.
  final QuotedPost? sharedPost;

  final bool seen;
  final DateTime? createdAt;

  /// Job rows only.
  final String? title;
  final String? companyName;

  /// Ad rows only.
  final int? boostId;

  /// Whether this row can be rendered as a [Post].
  ///
  /// The feed also carries reels, job cards and ads. Those need their own
  /// widgets, so the repository drops them rather than forcing a reel into a
  /// post-shaped hole — revisit when the feed screen grows those cards.
  bool get isPostLike => itemType == 0 || itemType == 1;

  Post toDomain() => Post(
    id: itemId,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatar,
    createdAt: createdAt ?? DateTime.now(),
    visibility: visibility,
    text: content,
    tags: PostDto.hashtagsIn(content),
    media: media,
    likeCount: likeCount,
    liked: isLiked,
    commentCount: commentCount,
    repostCount: shareCount,
    saved: isSaved,
    reposted: isShared,
    viewCount: viewCount,
    quoted: sharedPost,
    repostedById: itemType == 1 ? authorId : null,
    // `FeedItemSource.Recommendation` on the wire. The other three values —
    // FanoutWrite, FanoutRead, Ad — all mean somebody the viewer chose, or an
    // ad, which carries its own labelling.
    suggested: source == 'Recommendation',
  );
}

/// One page of [FeedItemDto]s plus the three cursors the next page needs.
class FeedPageDto {
  const FeedPageDto({
    required this.items,
    required this.bucket,
    required this.nextBeforeEventTime,
    required this.nextRecommendationOffset,
    required this.hasMore,
  });

  factory FeedPageDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return FeedPageDto(
      items: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(FeedItemDto.fromJson)
                .toList(growable: false)
          : const [],
      bucket: '${json['bucket'] ?? ''}',
      nextBeforeEventTime: json['nextBeforeEventTime'] as String?,
      nextRecommendationOffset: PostDto.asInt(json['nextRecommendationOffset']),
      hasMore: json['hasMore'] == true,
    );
  }

  final List<FeedItemDto> items;

  /// The Cassandra partition this page was read from (`yyyy-MM`).
  final String bucket;

  /// Cursor into the fan-out inbox. Null once that source is exhausted —
  /// which does not mean the feed is over, recommendations may continue.
  final String? nextBeforeEventTime;

  /// Cursor into the Postgres recommendation pool. Paged independently of the
  /// inbox, so it must be echoed back even when the inbox cursor is null.
  final int nextRecommendationOffset;

  final bool hasMore;
}
