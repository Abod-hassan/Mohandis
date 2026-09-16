import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import 'feed_notifier.dart';

/// Single-post screen state. Mutations here are mirrored into the feed so
/// backing out of the detail screen shows the same counts.
///
/// The post and its comments are two separate endpoints on the backend
/// (`GET Posts/{id}` and `POST Comments`), fetched together and merged into
/// `Post.comments` so the screen still reads one object.
class PostDetailNotifier extends FamilyAsyncNotifier<Post, String> {
  @override
  Future<Post> build(String postId) => _load(postId);

  Future<Post> _load(String postId) async {
    final repository = ref.read(postRepositoryProvider);
    // Both in flight at once — the thread is the point of this screen, so
    // waiting for the post before even asking for comments doubles the wait.
    final postRequest = repository.getById(postId);
    final commentsRequest = repository.comments(postId);

    final post = (await postRequest).when(
      success: (p) => p,
      failure: (e) => throw e,
    );
    // A comment failure must not blank the post — the thread degrades to
    // empty and the counter still shows the server-side total.
    final comments = (await commentsRequest).when(
      success: (List<Comment> c) => c,
      failure: (_) => const <Comment>[],
    );

    // Fire-and-forget: marks the viewer's fanned-out feed copy seen so the
    // feed stops re-serving it. Failure here is not worth surfacing.
    unawaited(repository.markViewed(postId));

    return post.copyWith(comments: comments);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(arg));
  }

  Future<Result<Post, AppException>> toggleLike() async {
    final current = state.valueOrNull;
    if (current == null) {
      return const Result.failure(NotFoundException('لم يُحمّل المنشور بعد'));
    }
    state = AsyncValue.data(current.toggleLike());

    final result = await ref.read(postRepositoryProvider).toggleLike(arg);
    result.when(
      success: _sync,
      failure: (_) => state = AsyncValue.data(current),
    );
    return result;
  }

  /// Reposts the post. Not really a toggle — see `FeedNotifier.toggleRepost`.
  Future<Result<Post, AppException>> toggleRepost() async {
    final current = state.valueOrNull;
    if (current == null) {
      return const Result.failure(NotFoundException('لم يُحمّل المنشور بعد'));
    }
    if (current.reposted) {
      return const Result.failure(
        ValidationException('لقد أعدت نشر هذا المنشور من قبل'),
      );
    }
    state = AsyncValue.data(current.toggleRepost());

    final result = await ref.read(postRepositoryProvider).toggleRepost(arg);
    result.when(
      success: _sync,
      failure: (_) => state = AsyncValue.data(current),
    );
    return result;
  }

  /// Toggles a like on one comment or reply in the loaded thread.
  ///
  /// Optimistic like the post's own like, but the swap has to reach into the
  /// tree: a reply lives under its parent's `replies`, and rebuilding only the
  /// top level would leave a tapped reply unchanged on screen.
  Future<Result<Comment, AppException>> toggleCommentLike(
    String commentId,
  ) async {
    final current = state.valueOrNull;
    if (current == null) {
      return const Result.failure(NotFoundException('لم يُحمّل المنشور بعد'));
    }

    state = AsyncValue.data(
      current.copyWith(
        comments: _mapComment(
          current.comments,
          commentId,
          (c) => c.copyWith(
            liked: !c.liked,
            likeCount: c.likeCount + (c.liked ? -1 : 1),
          ),
        ),
      ),
    );

    final result =
        await ref.read(postRepositoryProvider).toggleCommentLike(commentId);
    return result.when(
      success: (server) {
        final latest = state.valueOrNull ?? current;
        // Reconciled against the server's own counts rather than trusted:
        // `Comments/Like` answers with the whole comment.
        state = AsyncValue.data(
          latest.copyWith(
            comments: _mapComment(
              latest.comments,
              commentId,
              (c) => c.copyWith(
                liked: server.liked,
                likeCount: server.likeCount,
              ),
            ),
          ),
        );
        return Result<Comment, AppException>.success(server);
      },
      failure: (e) {
        state = AsyncValue.data(current);
        return Result<Comment, AppException>.failure(e);
      },
    );
  }

  /// Rewrites one comment anywhere in the two-level thread, leaving the rest
  /// of the tree identical.
  static List<Comment> _mapComment(
    List<Comment> comments,
    String commentId,
    Comment Function(Comment) transform,
  ) {
    return [
      for (final comment in comments)
        if (comment.id == commentId)
          transform(comment)
        else
          comment.copyWith(
            replies: [
              for (final reply in comment.replies)
                if (reply.id == commentId) transform(reply) else reply,
            ],
          ),
    ];
  }

  Future<Result<void, AppException>> addComment(String text) async {
    final result = await ref
        .read(postRepositoryProvider)
        .addComment(postId: arg, text: text);
    return result.flatMapAsync((_) async {
      // Reload rather than appending locally: the server owns the comment
      // count, and a reply has to land under the right parent.
      state = await AsyncValue.guard(() => _load(arg));
      final reloaded = state.valueOrNull;
      if (reloaded != null) {
        ref.read(feedNotifierProvider.notifier).applyServerPost(reloaded);
      }
      return const Result<void, AppException>.success(null);
    });
  }

  /// Applies a server-returned post while keeping the comments already loaded —
  /// the post endpoints don't return the thread.
  void _sync(Post server) {
    final merged = server.copyWith(
      comments: state.valueOrNull?.comments ?? const [],
    );
    state = AsyncValue.data(merged);
    ref.read(feedNotifierProvider.notifier).applyServerPost(merged);
  }
}

final postDetailNotifierProvider =
    AsyncNotifierProvider.family<PostDetailNotifier, Post, String>(
      PostDetailNotifier.new,
    );
