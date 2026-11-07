import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/features/posts/data/repositories/post_repository_impl.dart';
import 'package:mohandis/features/posts/domain/entities/feed_page.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';

import '../../support/test_api_client.dart';

void main() {
  /// A `PostDto` as the module serialises it — `content`, `isLiked`, and an
  /// integer `visibility`.
  Map<String, dynamic> postJson({String id = 'p1'}) => {
    'id': id,
    'authorId': 'amal',
    'authorName': 'أمل الراوي',
    'authorIsVerified': true,
    'createdAt': '2026-08-12T09:00:00Z',
    'visibility': 0,
    'content': 'نص المنشور #التوظيف',
    'media': const <Map<String, dynamic>>[],
    'likeCount': 12,
    'commentCount': 2,
    'shareCount': 3,
    'isLiked': false,
  };

  /// The `ResultViewModel` wrapper every module endpoint answers with.
  Map<String, dynamic> envelope(Object? data, {bool error = false}) => {
    'data': data,
    'error': error,
    'message': error ? 'حدث خطأ' : 'Success',
    'totalCount': data is List ? data.length : 1,
    'hasMore': false,
  };

  Map<String, dynamic> feedEnvelope(List<Map<String, dynamic>> items) =>
      envelope({
        'items': items,
        'bucket': '2026-08',
        'nextBeforeEventTime': 'ffff',
        'nextRecommendationOffset': 3,
        'hasMore': true,
      });

  Map<String, dynamic> feedItemJson({String id = 'f1', int itemType = 0}) => {
    'itemId': id,
    'itemType': itemType,
    'source': 'FanoutWrite',
    'authorId': 'amal',
    'authorName': 'أمل الراوي',
    'content': 'صف من التغذية',
    'media': const <Map<String, dynamic>>[],
    'visibility': 0,
    'likeCount': 4,
    'commentCount': 1,
    'shareCount': 0,
    'isLiked': true,
    'createdAt': '2026-08-12T09:00:00Z',
  };

  PostRepositoryImpl repositoryReturning(
    Future<ResponseBody> Function(RequestOptions) handler,
  ) => PostRepositoryImpl(apiClient: buildTestApiClient(onRequest: handler));

  group('PostRepositoryImpl.getAll', () {
    test('reads the home feed and maps its items into domain posts', () async {
      RequestOptions? captured;
      final repo = repositoryReturning((options) async {
        captured = options;
        return jsonResponse(
          feedEnvelope([feedItemJson(), feedItemJson(id: 'f2')]),
        );
      });

      final result = await repo.getAll();

      expect(result.isSuccess, isTrue);
      final posts = result.valueOrNull!;
      expect(posts, hasLength(2));
      expect(posts.first.id, 'f1');
      expect(posts.first.authorName, 'أمل الراوي');
      expect(posts.first.liked, isTrue);
      expect(captured!.method, 'POST');
      expect(captured!.path, '/api/social/Feed');
    });

    test('drops feed rows that are not posts', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse(
          feedEnvelope([
            feedItemJson(),
            // A reel and an ad — neither renders as a post card.
            feedItemJson(id: 'r1', itemType: 2),
            feedItemJson(id: 'ad1', itemType: 4),
          ]),
        ),
      );

      final result = await repo.getAll();

      expect(result.valueOrNull!.map((p) => p.id), ['f1']);
    });

    test('fails when the envelope reports an error on a 200', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse(envelope(null, error: true)),
      );

      final result = await repo.getAll();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ServerException>());
      // The server's own message survives — these are written for humans.
      expect(result.errorOrNull!.message, 'حدث خطأ');
    });

    test('returns UnauthorizedException on 401', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse({'message': 'unauthorized'}, statusCode: 401),
      );

      final result = await repo.getAll();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<UnauthorizedException>());
    });

    test('returns ServerException on 500', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse({'message': 'boom'}, statusCode: 500),
      );

      final result = await repo.getAll();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ServerException>());
    });

    test('returns TimeoutException on receive timeout', () async {
      final repo = repositoryReturning(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final result = await repo.getAll();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<TimeoutException>());
    });

    test('never throws a parse error past the repository boundary', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse(envelope('not-a-page')),
      );

      final result = await repo.getAll();

      // A malformed envelope degrades to an empty feed, not a crash.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('PostRepositoryImpl.homeFeed', () {
    test('sends no cursors on the first page and returns all three', () async {
      RequestOptions? captured;
      final repo = repositoryReturning((options) async {
        captured = options;
        return jsonResponse(feedEnvelope([feedItemJson()]));
      });

      final result = await repo.homeFeed();

      final body = captured!.data as Map<String, dynamic>;
      expect(body.containsKey('bucket'), isFalse);
      expect(body.containsKey('beforeEventTime'), isFalse);
      expect(body['recommendationOffset'], 0);

      final page = result.valueOrNull!;
      expect(page.hasMore, isTrue);
      expect(page.next.bucket, '2026-08');
      expect(page.next.beforeEventTime, 'ffff');
      expect(page.next.recommendationOffset, 3);
    });

    test('echoes every cursor back on the next page', () async {
      RequestOptions? captured;
      final repo = repositoryReturning((options) async {
        captured = options;
        return jsonResponse(feedEnvelope([]));
      });

      await repo.homeFeed(
        cursor: const FeedCursor(
          bucket: '2026-07',
          beforeEventTime: 'aaaa',
          recommendationOffset: 7,
        ),
        pageSize: 25,
      );

      final body = captured!.data as Map<String, dynamic>;
      expect(body['bucket'], '2026-07');
      expect(body['beforeEventTime'], 'aaaa');
      expect(body['recommendationOffset'], 7);
      expect(body['pageSize'], 25);
    });
  });

  group('PostRepositoryImpl.publish', () {
    test('posts the composer payload and returns the created post', () async {
      RequestOptions? captured;
      final repo = repositoryReturning((options) async {
        captured = options;
        return jsonResponse(envelope(postJson(id: 'new-1')));
      });

      final result = await repo.publish(
        text: 'مرحباً',
        visibility: PostVisibility.followers,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.id, 'new-1');
      expect(captured!.method, 'POST');
      expect(captured!.path, '/api/social/Posts/Publish');
      final body = captured!.data as Map<String, dynamic>;
      expect(body['content'], 'مرحباً');
      // The ordinal, not the name — PostVisibilityEnum is an int on the wire.
      expect(body['visibility'], 1);
      // Hashtags are parsed server-side; there is no tags field to send.
      expect(body.containsKey('tags'), isFalse);
    });

    test('derives hashtags from the content on the way back', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse(envelope(postJson())),
      );

      final result = await repo.publish(
        text: 'نص المنشور #التوظيف',
        visibility: PostVisibility.public,
      );

      expect(result.valueOrNull!.tags, ['التوظيف']);
    });
  });

  group('PostRepositoryImpl.toggleSave', () {
    test('reports that the backend does not support saving a post', () async {
      final repo = repositoryReturning(
        (_) async => jsonResponse(envelope(postJson())),
      );

      final result = await repo.toggleSave('p1');

      expect(result.errorOrNull, isA<ForbiddenException>());
    });
  });
}
