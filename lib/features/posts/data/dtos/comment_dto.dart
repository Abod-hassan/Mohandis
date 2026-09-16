import 'package:flutter_mobile_template/core/base/base_dto.dart';

import '../../domain/entities/comment.dart';
import 'post_dto.dart';

/// Wire model for the backend's `CommentDto`
/// (`POST /api/social/Comments`, `Comments/Add`, `Comments/Like`).
///
/// The API returns comments **flat** — every row carries `parentCommentId` and
/// replies come back alongside their parents in the same page. [treeFrom]
/// folds a page into the nested shape the thread renders.
class CommentDto implements BaseDto<Comment> {
  const CommentDto({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorName = '',
    this.authorAvatarUrl,
    this.parentCommentId,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isLiked = false,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) => CommentDto(
    id: '${json['id'] ?? ''}',
    postId: '${json['postId'] ?? ''}',
    authorId: '${json['authorId'] ?? ''}',
    authorName: '${json['authorName'] ?? ''}',
    authorAvatarUrl: json['authorAvatarUrl'] as String?,
    parentCommentId: json['parentCommentId'] as String?,
    content: '${json['content'] ?? ''}',
    likeCount: PostDto.asInt(json['likeCount']),
    replyCount: PostDto.asInt(json['replyCount']),
    isLiked: json['isLiked'] == true,
    createdAt: PostDto.parseDate(json['createdAt']),
  );

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final String content;
  final int likeCount;
  final int replyCount;
  final bool isLiked;
  final DateTime createdAt;

  @override
  Comment toDomain({List<Comment> replies = const []}) => Comment(
    id: id,
    postId: postId,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    parentCommentId: parentCommentId,
    text: content,
    createdAt: createdAt,
    likeCount: likeCount,
    liked: isLiked,
    replyCount: replyCount,
    replies: replies,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'parentCommentId': parentCommentId,
    'content': content,
    'likeCount': likeCount,
    'replyCount': replyCount,
    'isLiked': isLiked,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// Folds a flat page of comments into top-level comments with their replies
  /// attached, oldest reply first.
  ///
  /// A reply whose parent is not in this page — the parent is on an earlier
  /// page, or was deleted — is promoted to top level rather than dropped:
  /// losing someone's comment is worse than showing it un-indented. Chains
  /// deeper than one level are flattened onto the top-level ancestor, which is
  /// exactly as deep as the thread renders.
  static List<Comment> treeFrom(Iterable<CommentDto> page) {
    final all = page.toList(growable: false);
    final byId = {for (final c in all) c.id: c};

    String? rootOf(CommentDto c) {
      var parentId = c.parentCommentId;
      final seen = <String>{c.id};
      while (parentId != null && byId.containsKey(parentId)) {
        if (!seen.add(parentId)) return null; // cycle guard
        final parent = byId[parentId]!;
        if (parent.parentCommentId == null) return parent.id;
        parentId = parent.parentCommentId;
      }
      return null;
    }

    final repliesByRoot = <String, List<Comment>>{};
    final roots = <CommentDto>[];
    for (final c in all) {
      final root = rootOf(c);
      if (root == null) {
        roots.add(c);
      } else {
        (repliesByRoot[root] ??= <Comment>[]).add(c.toDomain());
      }
    }

    return roots.map((c) {
      final replies = repliesByRoot[c.id] ?? const <Comment>[];
      return c.toDomain(
        replies: [...replies]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );
    }).toList(growable: false);
  }
}
