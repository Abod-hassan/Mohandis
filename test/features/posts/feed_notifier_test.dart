import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/posts/data/repositories/post_mock_repository.dart';
import 'package:mohandis/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mohandis/features/posts/domain/entities/comment.dart';
import 'package:mohandis/features/posts/domain/entities/feed_page.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';
import 'package:mohandis/features/posts/domain/repositories/post_repository.dart';
import 'package:mohandis/features/posts/presentation/notifiers/feed_notifier.dart';

/// Repository that loads fine but rejects every engagement toggle — lets the
/// tests drive the optimistic-rollback path.
class _FailingEngagementRepository implements PostRepository {
  _FailingEngagementRepository(this.seed);

  final List<Post> seed;

  @override
  Future<Result<List<Post>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async =>
      Result.success(seed);

  @override
  Future<Result<Post, AppException>> toggleLike(String postId) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Post, AppException>> toggleSave(String postId) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<List<Post>, AppException>> byHashtag(
    String tag, {
    int page = 1,
    int size = 20,
  }) async =>
      const Result.success(<Post>[]);

  @override
  Future<Result<List<Post>, AppException>> saved({
    int page = 1,
    int size = 20,
  }) async =>
      Result.success(seed.where((p) => p.saved).toList(growable: false));

  @override
  Future<Result<List<Comment>, AppException>> commentsByAuthor(
    String personId, {
    int page = 1,
    int size = 20,
  }) async =>
      const Result.success(<Comment>[]);

  @override
  Future<Result<Post, AppException>> toggleRepost(String postId) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<List<Post>, AppException>> byAuthor(
    String personId, {
    int page = 1,
    int size = 20,
  }) => getAll();

  @override
  Future<Result<FeedPage, AppException>> homeFeed({
    FeedCursor cursor = FeedCursor.first,
    int pageSize = 10,
  }) async =>
      Result.success(FeedPage(posts: seed, next: FeedCursor.first, hasMore: false));

  @override
  Future<Result<Post, AppException>> share({
    required String postId,
    String? text,
    PostVisibility visibility = PostVisibility.public,
  }) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<bool, AppException>> markViewed(String postId) async =>
      const Result.success(true);

  @override
  Future<Result<bool, AppException>> hideFromFeed(
    String postId, {
    bool wholeAuthor = false,
  }) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Post, AppException>> edit(
    String postId, {
    required String text,
    PostVisibility? visibility,
  }) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<bool, AppException>> report(
    String postId, {
    required PostReportReason reason,
    String? details,
  }) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Comment, AppException>> toggleCommentLike(
    String commentId,
  ) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Post, AppException>> getById(String id) async =>
      Result.success(seed.firstWhere((p) => p.id == id));

  @override
  Future<Result<Post, AppException>> publish({
    required String text,
    required PostVisibility visibility,
    List<PostMedia> media = const [],
    PollDraft? poll,
  }) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Poll, AppException>> votePoll(
    String pollId,
    String optionId,
  ) async => const Result.failure(NetworkException('offline'));

  @override
  Future<Result<List<Comment>, AppException>> comments(
    String postId, {
    int page = 1,
    int size = 50,
  }) async => const Result.success([]);

  @override
  Future<Result<Comment, AppException>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Post, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<Post, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(NetworkException('offline'));

  @override
  Future<Result<void, AppException>> delete(String id) async =>
      const Result.failure(NetworkException('offline'));
}

ProviderContainer containerWith(PostRepository repository) {
  final container = ProviderContainer(
    overrides: [postRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('FeedNotifier', () {
    test('loads the feed on first read', () async {
      final container = containerWith(
        PostMockRepository(latency: Duration.zero),
      );

      final posts = await container.read(feedNotifierProvider.future);

      expect(posts, isNotEmpty);
      expect(posts.first.id, 'p1');
    });

    test('toggleLike updates the count and keeps the server value', () async {
      final container = containerWith(
        PostMockRepository(latency: Duration.zero),
      );
      final before = await container.read(feedNotifierProvider.future);
      final target = before.first;

      await container.read(feedNotifierProvider.notifier).toggleLike(target.id);

      final after = container.read(feedNotifierProvider).valueOrNull!;
      final updated = after.firstWhere((p) => p.id == target.id);
      expect(updated.liked, isTrue);
      expect(updated.likeCount, target.likeCount + 1);
    });

    test('rolls the optimistic like back when the server rejects it', () async {
      final seed = [
        Post(
          id: 'p1',
          authorId: 'amal',
          createdAt: DateTime(2026, 8, 12),
          visibility: PostVisibility.public,
          text: 'نص',
          likeCount: 10,
        ),
      ];
      final container = containerWith(_FailingEngagementRepository(seed));
      await container.read(feedNotifierProvider.future);

      final result =
          await container.read(feedNotifierProvider.notifier).toggleLike('p1');

      expect(result.isFailure, isTrue);
      final after = container.read(feedNotifierProvider).valueOrNull!;
      expect(after.single.liked, isFalse);
      expect(after.single.likeCount, 10);
    });

    test('publish prepends the new post to the feed', () async {
      final container = containerWith(
        PostMockRepository(latency: Duration.zero),
      );
      await container.read(feedNotifierProvider.future);

      final result = await container.read(feedNotifierProvider.notifier).publish(
            text: 'منشور جديد',
            visibility: PostVisibility.public,
          );

      expect(result.isSuccess, isTrue);
      final after = container.read(feedNotifierProvider).valueOrNull!;
      expect(after.first.text, 'منشور جديد');
      expect(after.first.authorId, 'me');
    });

    test('publish surfaces a validation failure for empty text', () async {
      final container = containerWith(
        PostMockRepository(latency: Duration.zero),
      );
      await container.read(feedNotifierProvider.future);

      final result = await container.read(feedNotifierProvider.notifier).publish(
            text: '   ',
            visibility: PostVisibility.public,
          );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ValidationException>());
    });
  });
}
