import 'package:flutter_mobile_template/core/base/base_entity.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import 'comment.dart';

/// Who can see a post. Mirrors the composer's three-way visibility cycle, and
/// the wire values are the backend's `PostVisibilityEnum` ordinals — the
/// declaration order below IS the contract, do not reorder.
enum PostVisibility { public, followers, private }

/// A single media attachment. The backend's `MediaKindEnum` is `0` image /
/// `1` video; [isVideo] carries that so the grid can badge a video without a
/// second enum.
/// What an attachment IS — the server's `MediaKindEnum`, in its order.
///
/// `document` is last because the server numbers it 2: the values are
/// persisted, so the order here is not cosmetic.
enum MediaKind { image, video, document }

class PostMedia {
  const PostMedia({
    required this.id,
    this.url,
    this.thumbnailUrl,
    this.aspectRatio = 1,
    this.kind = MediaKind.image,
    this.durationSeconds,
    this.width,
    this.height,
    this.fileName,
    this.sizeBytes,
  });

  final String id;
  final String? url;
  final String? thumbnailUrl;

  final MediaKind kind;

  /// The name the file had when it was picked, for a [MediaKind.document].
  ///
  /// A document attachment is unusable without it: [url] is a generated path
  /// (`posts/<uuid>.pdf`) so one upload cannot overwrite another's, which means
  /// the name a person recognises survives nowhere else.
  final String? fileName;

  /// Size in bytes, for a document. Shown beside the name so somebody on a
  /// phone connection knows what a tap is about to cost before it starts.
  final int? sizeBytes;

  bool get isVideo => kind == MediaKind.video;
  bool get isDocument => kind == MediaKind.document;

  /// What the tile labels itself. Falls back to the stored path's last segment
  /// rather than showing nothing — an older row has no [fileName].
  String get displayName {
    final name = fileName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final path = (url ?? '').split('/').where((p) => p.isNotEmpty);
    return path.isEmpty ? '' : path.last;
  }

  /// `2.4 MB`, or null when the size is unknown. Latin digits and unit on
  /// purpose — the caller wraps it for RTL.
  String? get readableSize {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return null;
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final rounded = value >= 10 || unit == 0
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$rounded ${units[unit]}';
  }

  /// Derived from the server's `width`/`height` when both are present, else 1.
  final double aspectRatio;
  final double? durationSeconds;

  /// Pixel dimensions, when they are known.
  ///
  /// Carried separately from [aspectRatio] because they travel in both
  /// directions: the server sends them so the ratio can be recomputed, and the
  /// composer sends them back on publish. Without that second half every
  /// uploaded photo is stored dimensionless and comes back as a 1:1 tile —
  /// a portrait shot centre-cropped to a square in the feed.
  final int? width;
  final int? height;
}

/// A post quoted inside another post (the "share with comment" embed).
///
/// Built from the backend's `sharedPost` — a `PostSimplifiedDto`, so it
/// carries the original author's name inline and needs no directory lookup.
class QuotedPost {
  const QuotedPost({
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.id = '',
    this.authorName = '',
    this.authorAvatarUrl,
    this.firstMediaUrl,
  });

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String authorName;

  /// The original's first attachment — `PostSimplifiedDto.firstMediaUrl`.
  ///
  /// One image, not the grid: the embed is a preview of another post, and the
  /// projection the backend sends with a share carries exactly this much.
  /// Stored host-less like every other upload, so it needs resolving.
  final String? firstMediaUrl;
  final String? authorAvatarUrl;
}

class Post extends BaseEntity {
  const Post({
    required this.id,
    required this.authorId,
    required this.createdAt,
    required this.visibility,
    required this.text,
    this.authorName = '',
    this.authorAvatarUrl,
    this.authorVerified = false,
    this.tags = const [],
    this.media = const [],
    this.likeCount = 0,
    this.liked = false,
    this.commentCount = 0,
    this.comments = const [],
    this.repostCount = 0,
    this.reposted = false,
    this.saved = false,
    this.viewCount = 0,
    this.repostedById,
    this.quoted,
    this.jobId,
    this.suggested = false,
  });

  @override
  final String id;

  final String authorId;

  /// Denormalized by the backend onto every post and feed row, so a feed page
  /// renders without a second round-trip per author. May be empty on payloads
  /// that predate the denormalization — fall back to the people directory.
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorVerified;

  final DateTime createdAt;
  final PostVisibility visibility;
  final String text;

  /// Hashtags found in [text]. The backend parses these out of the content
  /// itself and does not accept a tags array on publish — this is a read-side
  /// convenience only.
  final List<String> tags;

  final List<PostMedia> media;

  final int likeCount;
  final bool liked;

  /// Server-side total. [comments] may hold only the first page, so the card
  /// renders this rather than `comments.length`.
  final int commentCount;
  final List<Comment> comments;

  /// The backend calls this the share count — a repost IS a share there.
  final int repostCount;
  final bool reposted;

  /// The viewer's own bookmark, from `PostDto.isSaved`. Private to them — a
  /// save moves no counter and notifies nobody.
  final bool saved;

  final int viewCount;

  /// Set when this post appears in the feed because someone reposted it.
  final String? repostedById;

  final QuotedPost? quoted;

  /// A job posting shared into the feed, rendered as a tappable embed.
  final String? jobId;

  /// This row came from the server's recommender, not from anyone the viewer
  /// follows or is connected to.
  ///
  /// Carried onto the card as a badge rather than dropped: an account that
  /// follows nobody gets a page made entirely of these, and without the badge
  /// a wall of strangers is indistinguishable from a network the viewer built
  /// themselves — which is exactly how it read before.
  final bool suggested;

  bool get hasMedia => media.isNotEmpty;

  /// Whether there is anything for the media GRID to draw.
  ///
  /// Distinct from [hasMedia] because a post can carry only documents, which
  /// render as their own rows: keyed on hasMedia the grid would be built,
  /// filter itself to nothing, and leave the padding above it as a gap nobody
  /// can explain.
  bool get hasPictures => media.any((m) => !m.isDocument);
  bool get hasTags => tags.isNotEmpty;
  bool get isRepost => repostedById != null;

  /// The author as a [Person], assembled from the fields the backend inlines.
  ///
  /// Thinner than a directory entry — there is no headline or location on a
  /// post payload — so prefer a directory hit when one exists and use this as
  /// the fallback that keeps the card from rendering blank.
  Person get author => Person(
    id: authorId,
    name: authorName,
    firstName: authorName.split(RegExp(r'\s+')).first,
    headline: '',
    location: '',
    verified: authorVerified,
    avatarUrl: authorAvatarUrl,
  );

  Post copyWith({
    String? text,
    PostVisibility? visibility,
    List<String>? tags,
    List<PostMedia>? media,
    int? likeCount,
    bool? liked,
    int? commentCount,
    List<Comment>? comments,
    int? repostCount,
    bool? reposted,
    bool? saved,
    int? viewCount,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorVerified: authorVerified,
      createdAt: createdAt,
      visibility: visibility ?? this.visibility,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      media: media ?? this.media,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
      repostCount: repostCount ?? this.repostCount,
      reposted: reposted ?? this.reposted,
      saved: saved ?? this.saved,
      viewCount: viewCount ?? this.viewCount,
      repostedById: repostedById,
      quoted: quoted,
      jobId: jobId,
      suggested: suggested,
    );
  }

  /// Applies a like toggle locally so the notifier can update optimistically
  /// before the server round-trip lands.
  Post toggleLike() =>
      copyWith(liked: !liked, likeCount: likeCount + (liked ? -1 : 1));

  Post toggleRepost() => copyWith(
    reposted: !reposted,
    repostCount: repostCount + (reposted ? -1 : 1),
  );

  Post toggleSave() => copyWith(saved: !saved);
}
