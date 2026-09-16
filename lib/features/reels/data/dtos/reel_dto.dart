import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

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
      createdAt: PostDto.parseDate(json['createdAt']),
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
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
  final DateTime createdAt;

  @override
  Reel toDomain() => Reel(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorUsername: authorUsername,
    authorAvatarUrl: authorAvatarUrl,
    authorVerified: authorIsVerified,
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
    'isLiked': isLiked,
    'isSaved': isSaved,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
