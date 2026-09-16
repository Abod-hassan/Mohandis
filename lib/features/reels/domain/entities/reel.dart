import 'package:flutter_mobile_template/core/base/base_entity.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

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
    avatarUrl: authorAvatarUrl,
  );

  Reel copyWith({bool? liked, bool? saved, int? likeCount, int? saveCount}) =>
      Reel(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        authorVerified: authorVerified,
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
      );

  /// Applies a like toggle locally so the notifier can update optimistically
  /// before the server round-trip lands.
  Reel toggleLike() =>
      copyWith(liked: !liked, likeCount: likeCount + (liked ? -1 : 1));

  Reel toggleSave() =>
      copyWith(saved: !saved, saveCount: saveCount + (saved ? -1 : 1));
}
