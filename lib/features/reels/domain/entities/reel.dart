import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

/// A short vertical video. Its own entity server-side, not a kind of post —
/// which is why it has a play count and a saved list where a post has neither.
///
/// [videoUrl] is null on the design's fixtures; the player falls back to the
/// gradient card, and against the live backend it is the reel's video, which
/// nothing plays yet.
class Reel extends BaseEntity {
  const Reel({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.createdAt,
    this.authorName = '',
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorVerified = false,
    this.authorSubscribed = false,
    this.tags = const [],
    this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.playCount = 0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.saveCount = 0,
    this.liked = false,
    this.saved = false,
    this.shareCount = 0,
    this.shared = false,
    this.commentCount = 0,
    this.sharedReelId,
    this.sharedAuthorId,
    this.sharedAuthorName,
  });

  @override
  final String id;

  final String authorId;

  /// Denormalized onto every reel row, exactly as on a post, so a full-screen
  /// page renders without a lookup per author.
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorVerified;

  /// The author holds a live subscription. Kept apart from [authorVerified] —
  /// see `Person.subscribed`.
  final bool authorSubscribed;

  final DateTime createdAt;
  final String caption;

  /// Hashtags found in [caption]. Reels have no hashtag table — the module
  /// only full-text-searches the caption — so this is derived client-side and
  /// is a read-side convenience only.
  final List<String> tags;

  final String? videoUrl;
  final String? thumbnailUrl;
  final double? durationSeconds;

  /// Playbacks. Counted separately from [viewCount] — starting playback bumps
  /// both, scrolling past bumps neither.
  final int playCount;
  final int viewCount;

  final int likeCount;
  final int saveCount;
  final bool liked;
  final bool saved;

  /// How many people have reposted this reel.
  final int shareCount;

  /// Whether THIS viewer has reposted it — the rail button's own state.
  final bool shared;

  /// How many comments (replies included) the reel has.
  final int commentCount;

  /// Set when this reel IS a repost: the original it was made from.
  ///
  /// A repost carries its own copy of the video, so it plays like any other
  /// reel; these three fields are what let the player say whose work it is
  /// instead of passing it off as the reposter's.
  final String? sharedReelId;
  final String? sharedAuthorId;
  final String? sharedAuthorName;

  /// True when this row is somebody's repost of another person's reel.
  bool get isRepost => sharedReelId != null;

  /// The author as a [Person], assembled from the fields the backend inlines.
  ///
  /// Thinner than a directory entry — a reel payload has no headline — so
  /// prefer a directory hit and use this as the fallback that keeps the page
  /// from rendering blank.
  Person get author => Person(
    id: authorId,
    name: authorName,
    firstName: authorName.split(RegExp(r'\s+')).first,
    headline: '',
    location: '',
    verified: authorVerified,
    subscribed: authorSubscribed,
    avatarUrl: authorAvatarUrl,
  );

  Reel copyWith({
    bool? liked,
    bool? saved,
    int? likeCount,
    int? saveCount,
    bool? shared,
    int? shareCount,
    int? commentCount,
  }) =>
      Reel(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        authorVerified: authorVerified,
        authorSubscribed: authorSubscribed,
        createdAt: createdAt,
        caption: caption,
        tags: tags,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        playCount: playCount,
        viewCount: viewCount,
        likeCount: likeCount ?? this.likeCount,
        saveCount: saveCount ?? this.saveCount,
        liked: liked ?? this.liked,
        saved: saved ?? this.saved,
        shareCount: shareCount ?? this.shareCount,
        shared: shared ?? this.shared,
        commentCount: commentCount ?? this.commentCount,
        sharedReelId: sharedReelId,
        sharedAuthorId: sharedAuthorId,
        sharedAuthorName: sharedAuthorName,
      );

  /// The poster to draw before the video is ready — the stored path, host-less
  /// like every other asset, for whichever resolver the caller uses.
  ///
  /// Falls back to DERIVING it from the video. Bunny Stream keeps a reel's
  /// playlist and its generated poster side by side under the video's guid,
  /// and the poster does not exist yet at the moment a reel is published: the
  /// library is still transcoding, so a row can be written with no
  /// [thumbnailUrl] at all, and every reel published before the poster path
  /// was stamped has none either. Those rows still have a poster on the CDN —
  /// there is simply nobody to ask for it but this.
  ///
  /// Null for a storage-zone reel (`reels/<uuid>.mp4`) with no thumbnail: that
  /// one really has no poster anywhere, and guessing a path for it would trade
  /// a gradient for a 404.
  String? get posterPath {
    final stored = thumbnailUrl?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final video = videoUrl?.trim();
    if (video == null || video.isEmpty) return null;
    if (video.startsWith('http://') || video.startsWith('https://')) return null;

    final first = video.split('/').first;
    return _guid.hasMatch(first) ? '$first/thumbnail.jpg' : null;
  }

  /// A Bunny video guid: the first segment of a Stream path, and never the
  /// name of a storage folder (`reels`, `avatars`, `covers`).
  static final RegExp _guid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Applies a like toggle locally so the notifier can update optimistically
  /// before the server round-trip lands.
  Reel toggleLike() =>
      copyWith(liked: !liked, likeCount: likeCount + (liked ? -1 : 1));

  Reel toggleSave() =>
      copyWith(saved: !saved, saveCount: saveCount + (saved ? -1 : 1));

  /// Applies a repost toggle locally. Unlike a post's share — which is not a
  /// toggle, because its sheet lets you quote it and a second one is a
  /// different thing — a reel repost is one tap on the player's rail, and a
  /// one-tap action that cannot be undone is a trap.
  Reel toggleShare() =>
      copyWith(shared: !shared, shareCount: shareCount + (shared ? -1 : 1));
}
