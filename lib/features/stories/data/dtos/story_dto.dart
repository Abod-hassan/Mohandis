import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/story.dart';

/// Wire model for the backend's `StoryDto` (`POST /api/social/Stories`,
/// `Stories/Publish`).
///
/// Field names follow the C# DTO, not the mobile entity: the text is
/// `caption`, the seen flag is `viewedByMe`, and the image/video
/// discriminator is `kind`.
class StoryDto implements BaseDto<Story> {
  const StoryDto({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.expiresAt,
    this.authorName = '',
    this.authorAvatarUrl,
    this.isVideo = false,
    this.mediaUrl,
    this.caption = '',
    this.viewCount = 0,
    this.viewedByMe = false,
  });

  factory StoryDto.fromJson(Map<String, dynamic> json) {
    // `MediaUrl` is a non-nullable C# string, so an absent value arrives as ""
    // rather than null — normalise it to null so the viewer's `mediaUrl !=
    // null` check means "there is something to load".
    final media = '${json['mediaUrl'] ?? ''}';
    return StoryDto(
      id: '${json['id'] ?? ''}',
      authorId: '${json['authorId'] ?? ''}',
      authorName: '${json['authorName'] ?? ''}',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      isVideo: PostDto.isVideoKind(json['kind']),
      mediaUrl: media.isEmpty ? null : media,
      caption: '${json['caption'] ?? ''}',
      createdAt: PostDto.parseDate(json['createdAt']),
      expiresAt: _parseExpiry(json['expiresAt']),
      viewCount: PostDto.asInt(json['viewCount']),
      viewedByMe: json['viewedByMe'] == true,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isVideo;
  final String? mediaUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int viewCount;
  final bool viewedByMe;

  @override
  Story toDomain() => Story(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    createdAt: createdAt,
    expiresAt: expiresAt,
    mediaUrl: mediaUrl,
    isVideo: isVideo,
    caption: caption,
    viewCount: viewCount,
    seen: viewedByMe,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'kind': kindToWire(isVideo),
    'mediaUrl': mediaUrl,
    'caption': caption,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'viewCount': viewCount,
    'viewedByMe': viewedByMe,
  };

  /// `ExpiresAt` is non-nullable server-side, but `PostDto.parseDate` answers
  /// *now* for anything it cannot read — and on an expiry that reads as a
  /// story that died the instant it arrived. A null instead lets
  /// `Story.expired` fall back to `createdAt + 24h`, which is the lifetime the
  /// server applied anyway.
  static DateTime? _parseExpiry(Object? raw) =>
      DateTime.tryParse('$raw') == null ? null : PostDto.parseDate(raw);

  /// `PublishStoryDto.kind` — `MediaKindEnum` is `0` image / `1` video.
  ///
  /// Names come back in (the host registers `StringEnumConverter`) but the
  /// ordinal is still accepted on the way out, and it is the one spelling the
  /// model binder cannot get wrong.
  static int kindToWire(bool isVideo) => isVideo ? 1 : 0;
}
