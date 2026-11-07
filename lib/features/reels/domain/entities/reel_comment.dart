import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

/// A comment on a reel. Replies nest one level deep, as on a post: a reply to
/// a reply is filed under the top-level comment by the server.
class ReelComment extends BaseEntity {
  const ReelComment({
    required this.id,
    required this.reelId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.authorName = '',
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorVerified = false,
    this.parentCommentId,
  });

  @override
  final String id;

  final String reelId;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool authorVerified;
  final String text;
  final String? parentCommentId;
  final DateTime createdAt;

  bool get isReply => parentCommentId != null;

  Person get author => Person(
    id: authorId,
    name: authorName,
    firstName: authorName.split(RegExp(r'\s+')).first,
    headline: '',
    location: '',
    verified: authorVerified,
    avatarUrl: authorAvatarUrl,
  );
}
