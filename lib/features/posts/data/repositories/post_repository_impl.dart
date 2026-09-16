import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/comment.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../dtos/comment_dto.dart';
import '../dtos/post_dto.dart';

/// Posts against the RoboByte.SocialMedia module.
///
/// Two things about this API shape drive the whole class:
///
///   * **Reads are POSTs with a filter body.** `POST /api/social/Posts` takes a
///     `PostFilter` and `?detailed&page&size`; there is no query-string list
///     endpoint. `viewerProfileId` is set server-side from the bearer token,
///     so it is never sent from here.
///   * **Every response is a `ResultViewModel` envelope**, unwrapped by
///     [apiCall]. A 200 can still carry `error: true`.
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const int _defaultPageSize = 20;

  // ── Feed ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<FeedPage, AppException>> homeFeed({
    FeedCursor cursor = FeedCursor.first,
    int pageSize = 10,
  }) {
    return apiCall(EndPoints.feed, () {
      return _api.dio.post<dynamic>(
        EndPoints.feed,
        data: cursor.toRequest(pageSize),
      );
    }, (envelope) => _feedPage(envelope, cursor));
  }

  FeedPage _feedPage(ApiEnvelope envelope, FeedCursor sent) {
    final page = FeedPageDto.fromJson(envelope.object);
    return FeedPage(
      posts: page.items
          .where((i) => i.isPostLike)
          .map((i) => i.toDomain())
          .toList(growable: false),
      next: FeedCursor(
        // The server echoes the bucket it actually read; falling back to the
        // one we sent keeps paging alive if a page comes back empty.
        bucket: page.bucket.isEmpty ? sent.bucket : page.bucket,
        beforeEventTime: page.nextBeforeEventTime,
        recommendationOffset: page.nextRecommendationOffset,
      ),
      hasMore: page.hasMore,
    );
  }

  /// The home feed's first page — this is what `BaseListNotifier` calls on
  /// build, so `FeedNotifier` gets a feed without knowing about cursors.
  /// Pagination beyond page one goes through [homeFeed].
  @override
  Future<Result<List<Post>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    final result = await homeFeed();
    return result.map((page) => page.posts);
  }

  @override
  Future<Result<bool, AppException>> hideFromFeed(
    String postId, {
    bool wholeAuthor = false,
  }) {
    return apiCall(
      EndPoints.feedHide,
      () => _api.dio.post<dynamic>(
        EndPoints.feedHide,
        queryParameters: {'itemId': postId, 'scope': wholeAuthor ? 1 : 0},
      ),
      (envelope) => envelope.data != false,
    );
  }

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Post>, AppException>> byAuthor(
    String personId, {
    int page = 1,
    int size = _defaultPageSize,
  }) {
    return _list({
      'authorIds': [personId],
      // Authored-only, spelled out. `PostFilter.OnlyLiked` is a separate
      // predicate the server ANDs in when true, and sending false pins it so a
      // change to its default can never widen this into "posts they engaged
      // with". Reposts still appear — a repost is a post they authored.
      'onlyLiked': false,
    }, page: page, size: size);
  }

  @override
  Future<Result<List<Post>, AppException>> saved({
    int page = 1,
    int size = _defaultPageSize,
  }) {
    return _list({'onlySaved': true}, page: page, size: size);
  }

  @override
  Future<Result<List<Comment>, AppException>> commentsByAuthor(
    String personId, {
    int page = 1,
    int size = 20,
  }) {
    return apiCall(
      EndPoints.comments,
      () => _api.dio.post<dynamic>(
        EndPoints.comments,
        // `authorId` is who WROTE them; `viewerProfileId` is who is looking and
        // is never sent by the client. Not tree-built: each of these hangs
        // under a different post.
        data: {'authorId': personId, 'topLevelOnly': false},
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) => envelope.list
          .map((j) => CommentDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  /// Filtered read. [filter] is a `PostFilter` — omitted keys keep their
  /// server-side defaults, so only send what you mean to constrain.
  Future<Result<List<Post>, AppException>> _list(
    Map<String, dynamic> filter, {
    int page = 1,
    int size = _defaultPageSize,
  }) {
    return apiCall(
      EndPoints.posts,
      () => _api.dio.post<dynamic>(
        EndPoints.posts,
        data: filter,
        queryParameters: {'detailed': true, 'page': page, 'size': size},
      ),
      (envelope) => envelope.list
          .map((j) => PostDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<Post, AppException>> getById(String id) {
    final path = EndPoints.postById(id);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      // `GET Posts/{id}` returns the envelope with a single-element list —
      // the controller pulls the row out of a paged read.
      _firstPost,
    );
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  @override
  Future<Result<Post, AppException>> publish({
    required String text,
    required PostVisibility visibility,
    List<PostMedia> media = const [],
  }) {
    return apiCall(
      EndPoints.postsPublish,
      () => _api.dio.post<dynamic>(
        EndPoints.postsPublish,
        data: {
          'content': text,
          'visibility': PostDto.visibilityToWire(visibility),
          if (media.isNotEmpty) 'media': _mediaInput(media),
        },
      ),
      _post,
    );
  }

  @override
  Future<Result<Post, AppException>> share({
    required String postId,
    String? text,
    PostVisibility visibility = PostVisibility.public,
  }) {
    return apiCall(
      EndPoints.postsShare,
      () => _api.dio.post<dynamic>(
        EndPoints.postsShare,
        data: {
          'sharedPostId': postId,
          if (text != null && text.trim().isNotEmpty) 'content': text,
          'visibility': PostDto.visibilityToWire(visibility),
        },
      ),
      _post,
    );
  }

  @override
  Future<Result<Post, AppException>> toggleLike(String postId) {
    return apiCall(
      EndPoints.postsLike,
      () => _api.dio.post<dynamic>(
        EndPoints.postsLike,
        queryParameters: {'postId': postId},
      ),
      _post,
    );
  }

  /// Reposting returns the ORIGINAL post, not the share that was just created.
  ///
  /// `Posts/Share` responds with the new share — but every caller here is a
  /// feed or detail row for the post being shared, and handing back a
  /// different post would swap that row for the repost. So the share is
  /// created and the original re-read for its authoritative share count.
  @override
  Future<Result<Post, AppException>> toggleRepost(String postId) async {
    final shared = await share(postId: postId);
    if (shared.isFailure) return Result.failure(_shareFailure(shared.errorOrNull!));
    return shared.flatMapAsync((_) => getById(postId));
  }

  /// The service refuses a second repost in plain English inside the envelope.
  /// Rewritten here because `arabicErrorFor` has no row for it and would fall
  /// back to a generic "something went wrong" for a perfectly ordinary answer.
  AppException _shareFailure(AppException e) {
    if (e.message.toLowerCase().contains('already shared')) {
      return const ValidationException('لقد أعدت نشر هذا المنشور من قبل');
    }
    return e;
  }

  @override
  Future<Result<Post, AppException>> toggleSave(String postId) {
    return apiCall(
      EndPoints.postsSave,
      () => _api.dio.post<dynamic>(
        EndPoints.postsSave,
        queryParameters: {'postId': postId},
      ),
      // Answers the whole post with `isSaved` flipped, the same shape Like
      // uses — so the optimistic toggle is reconciled, not trusted.
      _post,
    );
  }

  @override
  Future<Result<bool, AppException>> markViewed(String postId) {
    return apiCall(
      EndPoints.postsView,
      () => _api.dio.post<dynamic>(
        EndPoints.postsView,
        queryParameters: {'postId': postId},
      ),
      (envelope) => envelope.data != false,
    );
  }

  @override
  Future<Result<void, AppException>> delete(String id) {
    final path = EndPoints.postById(id);
    return apiCall(path, () => _api.dio.delete<dynamic>(path), (_) {});
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Comment>, AppException>> comments(
    String postId, {
    int page = 1,
    int size = 50,
  }) {
    return apiCall(
      EndPoints.comments,
      () => _api.dio.post<dynamic>(
        EndPoints.comments,
        // Replies are wanted in the same page — `topLevelOnly` would strip
        // them and there is no per-comment replies endpoint to fill them in.
        data: {'postId': postId, 'topLevelOnly': false},
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) => CommentDto.treeFrom(envelope.list.map(CommentDto.fromJson)),
    );
  }

  @override
  Future<Result<Comment, AppException>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) {
    return apiCall(
      EndPoints.commentsAdd,
      () => _api.dio.post<dynamic>(
        EndPoints.commentsAdd,
        queryParameters: {'postId': postId},
        data: {
          'content': text,
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
        },
      ),
      _comment,
    );
  }

  @override
  Future<Result<Comment, AppException>> toggleCommentLike(String commentId) {
    return apiCall(
      EndPoints.commentsLike,
      () => _api.dio.post<dynamic>(
        EndPoints.commentsLike,
        queryParameters: {'commentId': commentId},
      ),
      _comment,
    );
  }

  // ── BaseRepository plumbing ──────────────────────────────────────────────

  @override
  Future<Result<Post, AppException>> create(Map<String, dynamic> body) => publish(
    text: '${body['text'] ?? body['content'] ?? ''}',
    visibility: PostDto.visibilityFromWire(body['visibility']),
  );

  /// The module has no post-edit endpoint — a published post is immutable.
  @override
  Future<Result<Post, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    return const Result.failure(
      ForbiddenException('Posts cannot be edited after publishing'),
    );
  }

  // ── Decoders ─────────────────────────────────────────────────────────────

  Post _post(ApiEnvelope envelope) =>
      PostDto.fromJson(envelope.object).toDomain();

  Post _firstPost(ApiEnvelope envelope) {
    final rows = envelope.list;
    if (rows.isEmpty) throw const NotFoundException('Post not found');
    return PostDto.fromJson(rows.first).toDomain();
  }

  Comment _comment(ApiEnvelope envelope) =>
      CommentDto.fromJson(envelope.object).toDomain();

  List<Map<String, dynamic>> _mediaInput(List<PostMedia> media) => [
    for (var i = 0; i < media.length; i++)
      {
        'url': media[i].url ?? '',
        'kind': PostDto.mediaKindToWire(media[i].kind),
        if (media[i].thumbnailUrl != null)
          'thumbnailUrl': media[i].thumbnailUrl,
        'position': i,
        if (media[i].durationSeconds != null)
          'durationSeconds': media[i].durationSeconds,
        // Omitted rather than zeroed when unknown: the reader treats a missing
        // pair as "no ratio available" and falls back to 1:1, whereas a 0
        // height would be a division waiting to happen.
        if (media[i].width != null) 'width': media[i].width,
        if (media[i].height != null) 'height': media[i].height,
        // A document's name and size. The server ignores both on any other
        // kind, and without the name the attachment arrives back labelled with
        // a uuid — Url is a generated path, so nothing else carries it.
        if (media[i].fileName != null) 'fileName': media[i].fileName,
        if (media[i].sizeBytes != null) 'sizeBytes': media[i].sizeBytes,
      },
  ];
}

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
