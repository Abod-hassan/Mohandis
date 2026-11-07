import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/reel.dart';
import '../entities/reel_comment.dart';
import '../entities/reel_page.dart';

abstract class ReelRepository extends BaseRepository<Reel> {
  /// One page of the reel wall. [query] takes the same keys as [getAll] —
  /// `onlySaved`, `onlyLiked`, `followedOnly`, `authorIds`, `search`, `page`
  /// and `size` — and `getAll` is its first page, so a notifier can start
  /// from the base contract and page on from here.
  Future<Result<ReelPage, AppException>> wall({Map<String, dynamic>? query});

  /// Toggles the caller's like. Returns the reel as the server sees it, so an
  /// optimistic UI update can be reconciled rather than trusted.
  Future<Result<Reel, AppException>> toggleLike(String reelId);

  /// Toggles the caller's save, and returns the updated reel the same way
  /// [toggleLike] does. Reels are the only thing this module can save — a post
  /// has no equivalent.
  Future<Result<Reel, AppException>> toggleSave(String reelId);

  /// Reposts a reel to the caller's own followers, or undoes a repost they
  /// already made. The repost is a reel of its own, so it appears in the
  /// reposter's wall and on their profile like anything else they published.
  ///
  /// Returns the ORIGINAL as the server now sees it — not the repost — because
  /// what the rail that was tapped has to redraw is the original's count and
  /// its own on/off state.
  Future<Result<Reel, AppException>> toggleShare(String reelId);

  /// Counts one playback: a reel that actually started playing, not one that
  /// scrolled past. Fire-and-forget from the UI's side — the count comes back
  /// on the next read, not from this call.
  Future<Result<bool, AppException>> markPlayed(String reelId);

  /// One page of a reel's comments, oldest first. Replies come in the same
  /// list, each naming its parent.
  Future<Result<List<ReelComment>, AppException>> comments(
    String reelId, {
    int page = 1,
    int size = 50,
  });

  /// Adds a comment, or a reply when [parentCommentId] is set.
  Future<Result<ReelComment, AppException>> addComment(
    String reelId,
    String text, {
    String? parentCommentId,
  });

  /// Deletes a comment (and its replies). The comment's author or the reel's
  /// author only.
  Future<Result<void, AppException>> deleteComment(String commentId);
}
