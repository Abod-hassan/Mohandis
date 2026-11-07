import 'package:mohandis/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/reel_comment.dart';

/// `ReelCommentDto` off the wire.
abstract final class ReelCommentDto {
  static ReelComment fromJson(Map<String, dynamic> json) {
    final parent = '${json['parentCommentId'] ?? ''}';
    return ReelComment(
      id: '${json['id'] ?? ''}',
      reelId: '${json['reelId'] ?? ''}',
      authorId: '${json['authorId'] ?? ''}',
      authorName: '${json['authorName'] ?? ''}',
      authorUsername: json['authorUsername'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorVerified: json['authorIsVerified'] == true,
      text: '${json['content'] ?? ''}',
      // Empty and the all-zero guid both mean "top level".
      parentCommentId:
          parent.isEmpty || parent == '00000000-0000-0000-0000-000000000000'
          ? null
          : parent,
      createdAt: PostDto.parseDate(json['createdAt']),
    );
  }
}
