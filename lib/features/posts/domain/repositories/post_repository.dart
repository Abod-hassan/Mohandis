import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/comment.dart';
import '../entities/feed_page.dart';
import '../entities/post.dart';

/// Why a post is being reported — `ReportReasonEnum` on the server, sent as its
/// integer value.
enum PostReportReason {
  spam(0),
  harassment(1),
  hateSpeech(2),
  violence(3),
  nudity(4),
  misinformation(5),
  selfHarm(6),
  impersonation(7),
  intellectualProperty(8),
  other(9);

  const PostReportReason(this.wire);

  final int wire;
}

abstract class PostRepository extends BaseRepository<Post> {
  /// One page of the ranked home feed. Pass [FeedCursor.first] to start, then
  /// the [FeedPage.next] of the previous page.
  Future<Result<FeedPage, AppException>> homeFeed({
    FeedCursor cursor,
    int pageSize,
  });

  /// Toggles the caller's like. Returns the post as the server sees it, so an
  /// optimistic UI update can be reconciled rather than trusted.
  Future<Result<Post, AppException>> toggleLike(String postId);

  /// **Not supported by the backend.** The module has a saved-reels table but
  /// no saved-posts one, so this always fails with a [ForbiddenException]
  /// rather than pretending to succeed. Kept on the interface so the card's
  /// bookmark control has something to call until the backend grows the
  /// feature (or the control is removed).
  /// Posts the caller has bookmarked, newest first.
  ///
  /// A save is private, so this is only ever the caller's own list — the
  /// server ignores `onlySaved` without a resolved viewer rather than
  /// answering with everybody's.
  Future<Result<List<Post>, AppException>> saved({int page, int size});

  /// Posts carrying [tag] (with or without the leading `#`), newest first —
  /// what a hashtag page lists. `PostFilter.Hashtag` on the server.
  Future<Result<List<Post>, AppException>> byHashtag(
    String tag, {
    int page,
    int size,
  });

  Future<Result<Post, AppException>> toggleSave(String postId);

  /// Reposts [postId] with no added text. A repost IS a share server-side, and
  /// it is **not** a toggle: every call creates another post. Un-reposting
  /// means deleting the share, which needs its id — so the optimistic
  /// "unrepost" path in the feed reconciles against whatever comes back.
  Future<Result<Post, AppException>> toggleRepost(String postId);

  /// Publishes a post.
  ///
  /// Hashtags and @mentions are parsed out of [text] by the backend and stored
  /// in their own tables — there is deliberately no tags argument.
  Future<Result<Post, AppException>> publish({
    required String text,
    required PostVisibility visibility,
    List<PostMedia> media,
    PollDraft? poll,
  });

  /// Votes in a post's poll, moves the vote, or — the same option again —
  /// takes it back. Returns the poll as the server now counts it.
  Future<Result<Poll, AppException>> votePoll(String pollId, String optionId);

  /// Shares an existing post, optionally quoting it with [text].
  Future<Result<Post, AppException>> share({
    required String postId,
    String? text,
    PostVisibility visibility,
  });

  /// Records an explicit view and marks the viewer's fanned-out feed copy as
  /// seen, so it stops being re-served. Fire-and-forget from the UI's side.
  Future<Result<bool, AppException>> markViewed(String postId);

  /// A post's comments, folded into one level of replies.
  Future<Result<List<Comment>, AppException>> comments(
    String postId, {
    int page,
    int size,
  });

  Future<Result<Comment, AppException>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  });

  Future<Result<Comment, AppException>> toggleCommentLike(String commentId);

  /// Posts authored by [personId] — backs the profile's activity section.
  Future<Result<List<Post>, AppException>> byAuthor(
    String personId, {
    int page,
    int size,
  });

  /// Comments written BY [personId] — the activity section's Comments tab.
  ///
  /// Flat, not a tree: these are one person's comments scattered across other
  /// people's posts, so there are no parents to nest them under.
  Future<Result<List<Comment>, AppException>> commentsByAuthor(
    String personId, {
    int page,
    int size,
  });

  /// Edits the caller's own post: its text, and optionally who may see it.
  ///
  /// Text only. The media a post was published with stays as it is — the
  /// fanned-out copies in the feed store carry the attachments, and swapping
  /// them after delivery would leave rows pointing at something the post no
  /// longer contains.
  Future<Result<Post, AppException>> edit(
    String postId, {
    required String text,
    PostVisibility? visibility,
  });

  /// Reports a post for moderation. Anyone may report anything once they are
  /// signed in; what happens next is a moderator's surface, not this app's.
  Future<Result<bool, AppException>> report(
    String postId, {
    required PostReportReason reason,
    String? details,
  });

  /// "Not interested": hides one item, or everything from its author, in this
  /// viewer's feed.
  Future<Result<bool, AppException>> hideFromFeed(
    String postId, {
    bool wholeAuthor,
  });
}
