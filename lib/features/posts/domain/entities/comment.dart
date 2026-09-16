import 'package:flutter_mobile_template/core/base/base_entity.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

/// A comment on a post. Replies nest exactly one level deep — the design's
/// thread renders a reply indented under its parent and no further.
///
/// The backend returns comments FLAT, each carrying its `parentCommentId`;
/// `CommentDto.treeFrom` folds that list into this shape, attaching every
/// reply to its top-level ancestor so deeper chains stay one level deep.
class Comment extends BaseEntity {
  const Comment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.postId = '',
    this.parentCommentId,
    this.authorName = '',
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.liked = false,
    this.replyCount = 0,
    this.replies = const [],
  });

  @override
  final String id;

  final String authorId;

  /// Denormalized by the backend, same as on a post — a comment thread renders
  /// without a directory lookup per author.
  final String authorName;
  final String? authorAvatarUrl;

  final String postId;
  final String? parentCommentId;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool liked;

  /// Server-side reply total for this comment. [replies] may hold fewer.
  final int replyCount;
  final List<Comment> replies;

  bool get hasReplies => replies.isNotEmpty;
  bool get isReply => parentCommentId != null;

  Person get author => Person(
    id: authorId,
    name: authorName,
    firstName: authorName.split(RegExp(r'\s+')).first,
    headline: '',
    location: '',
    verified: false,
    avatarUrl: authorAvatarUrl,
  );

  Comment copyWith({
    int? likeCount,
    bool? liked,
    int? replyCount,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      postId: postId,
      parentCommentId: parentCommentId,
      text: text,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
    );
  }
}
