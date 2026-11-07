import 'package:mohandis/core/base/base_dto.dart';
import 'package:mohandis/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/reel.dart';

/// Wire model for the backend's `ReelDto` (`POST /api/social/Reels`,
/// `Reels/{id}`, `Reels/saved`, `Reels/Publish`, `Reels/Like`, `Reels/Save`).
///
/// Field names follow the C# DTO, not the mobile entity: the flags are
/// `isLiked` / `isSaved`, the text is `caption`, and there is **no comment
/// count** — comments in this module hang off a post, and a reel is not one.
class ReelDto implements BaseDto<Reel> {
  const ReelDto({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.authorName = '',
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.authorIsSubscribed = false,
    this.videoUrl,
    this.thumbnailUrl,
    this.caption = '',
    this.durationSeconds,
    this.likeCount = 0,
    this.viewCount = 0,
    this.playCount = 0,
    this.saveCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.shareCount = 0,
    this.commentCount = 0,
    this.isShared = false,
    this.sharedReelId,
    this.sharedAuthorId,
    this.sharedAuthorName,
  });

  factory ReelDto.fromJson(Map<String, dynamic> json) {
    // `VideoUrl` is a non-nullable C# string, so an absent value arrives as ""
    // rather than null — normalise it so a null check means "nothing to play".
    final video = '${json['videoUrl'] ?? ''}';
    return ReelDto(
      id: '${json['id'] ?? ''}',
      authorId: '${json['authorId'] ?? ''}',
      authorName: '${json['authorName'] ?? ''}',
      authorUsername: json['authorUsername'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorIsVerified: json['authorIsVerified'] == true,
      authorIsSubscribed: json['authorIsSubscribed'] == true,
      videoUrl: video.isEmpty ? null : video,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: '${json['caption'] ?? ''}',
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      likeCount: PostDto.asInt(json['likeCount']),
      viewCount: PostDto.asInt(json['viewCount']),
      playCount: PostDto.asInt(json['playCount']),
      saveCount: PostDto.asInt(json['saveCount']),
      isLiked: json['isLiked'] == true,
      isSaved: json['isSaved'] == true,
      shareCount: PostDto.asInt(json['shareCount']),
      commentCount: PostDto.asInt(json['commentCount']),
      isShared: json['isShared'] == true,
      sharedReelId: _optionalId(json['sharedReelId']),
      sharedAuthorId: _optionalId(json['sharedAuthorId']),
      sharedAuthorName: json['sharedAuthorName'] as String?,
      createdAt: PostDto.parseDate(json['createdAt']),
    );
  }

  /// A nullable guid off the wire. Empty and the all-zero guid both mean "not
  /// set" — a repost field is absent on an ordinary reel, and some serialisers
  /// write the default rather than omitting it.
  static String? _optionalId(Object? raw) {
    if (raw == null) return null;
    final value = '$raw'.trim();
    if (value.isEmpty) return null;
    if (value == '00000000-0000-0000-0000-000000000000') return null;
    return value;
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final bool authorIsSubscribed;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final double? durationSeconds;
  final int likeCount;
  final int viewCount;
  final int playCount;
  final int saveCount;
  final bool isLiked;
  final bool isSaved;
  final int shareCount;
  final int commentCount;
  final bool isShared;
  final String? sharedReelId;
  final String? sharedAuthorId;
  final String? sharedAuthorName;
  final DateTime createdAt;

  @override
  Reel toDomain() => Reel(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorUsername: authorUsername,
    authorAvatarUrl: authorAvatarUrl,
    authorVerified: authorIsVerified,
    authorSubscribed: authorIsSubscribed,
    createdAt: createdAt,
    caption: caption,
    // The module keeps hashtags in a table fed by post content only; a reel's
    // tags exist nowhere but its caption, so they are re-derived here the same
    // way `PostDto` re-derives a post's.
    tags: PostDto.hashtagsIn(caption),
    videoUrl: videoUrl,
    thumbnailUrl: thumbnailUrl,
    durationSeconds: durationSeconds,
    playCount: playCount,
    viewCount: viewCount,
    likeCount: likeCount,
    saveCount: saveCount,
    liked: isLiked,
    saved: isSaved,
    shareCount: shareCount,
    commentCount: commentCount,
    shared: isShared,
    sharedReelId: sharedReelId,
    sharedAuthorId: sharedAuthorId,
    sharedAuthorName: sharedAuthorName,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'videoUrl': videoUrl,
    'thumbnailUrl': thumbnailUrl,
    'caption': caption,
    'durationSeconds': durationSeconds,
    'likeCount': likeCount,
    'viewCount': viewCount,
    'playCount': playCount,
    'saveCount': saveCount,
    'shareCount': shareCount,
    'commentCount': commentCount,
    'isShared': isShared,
    'sharedReelId': sharedReelId,
    'sharedAuthorId': sharedAuthorId,
    'sharedAuthorName': sharedAuthorName,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
