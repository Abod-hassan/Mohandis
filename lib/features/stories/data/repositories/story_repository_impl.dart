import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/features/shared/people/data/dtos/person_dto.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';
import '../dtos/story_dto.dart';

/// Stories against the RoboByte.SocialMedia module.
///
/// The module's two house rules shape every method here:
///
///   * **Reads are POSTs with a filter body.** `POST /api/social/Stories` takes
///     a `StoryFilter` and `?page=&size=`; there is no query-string list
///     endpoint, and no `GET Stories/{id}` either — the filter's `id` IS the
///     single-row read. `viewerProfileId` is set server-side from the bearer
///     token, so it is never sent from here.
///   * **Every response is a `ResultViewModel` envelope**, unwrapped by
///     [apiCall]. A 200 can still carry `error: true`.
class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// The rail is a single page — it never scrolls to a second — and 50 is what
  /// `StoriesController.Get` defaults to anyway.
  static const int _defaultPageSize = 50;

  // ── Reads ────────────────────────────────────────────────────────────────

  /// The story rail.
  ///
  /// [query] accepts `followedOnly`, `authorIds`, `page` and `size`; omitted
  /// keys keep their server-side defaults.
  @override
  Future<Result<List<Story>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) {
    return apiCall(
      EndPoints.stories,
      () => _api.dio.post<dynamic>(
        EndPoints.stories,
        data: {
          // A rail of strangers' stories is not a rail. `followedOnly` scopes
          // it to accepted follows, and the server folds the viewer's own
          // stories into that set — so "your story" still appears without a
          // second call.
          'followedOnly': query?['followedOnly'] ?? true,
          if (query?['authorIds'] != null) 'authorIds': query!['authorIds'],
          // Expired rows are dropped inside the query; filtering again on the
          // client would only hide rows that are still live for the server.
          'activeOnly': true,
        },
        queryParameters: {
          'page': query?['page'] ?? 1,
          'size': query?['size'] ?? _defaultPageSize,
        },
      ),
      (envelope) => envelope.list
          .map((j) => StoryDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  /// One story.
  ///
  /// A story that expires while someone is watching it has to keep resolving
  /// rather than 404-ing mid-view, so `activeOnly` is sent as false. The
  /// `id` branch of `StoryFilter` happens to return before the flag is read,
  /// but the filter defaults it to **true** — resting on where that
  /// short-circuit sits in the query builder is one refactor away from an
  /// empty page.
  @override
  Future<Result<Story, AppException>> getById(String id) {
    return apiCall(
      EndPoints.stories,
      () => _api.dio.post<dynamic>(
        EndPoints.stories,
        data: {'id': id, 'activeOnly': false},
        queryParameters: {'page': 1, 'size': 1},
      ),
      _firstStory,
    );
  }

  @override
  Future<Result<List<Person>, AppException>> viewers(
    String storyId, {
    int page = 1,
    int size = 20,
  }) {
    final path = EndPoints.storyViewers(storyId);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(
        path,
        queryParameters: {'page': page, 'size': size},
      ),
      // `ProfileSimplifiedDto` rows — the same projection the people directory
      // is built from, so they decode with its DTO rather than a copy of it.
      (envelope) => envelope.list
          .map((j) => PersonDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// `Stories/View` answers `true`, not the story, so the row is re-read for
  /// its authoritative `viewedByMe` / `viewCount` instead of being patched
  /// locally — the same publish-then-read shape as
  /// `PostRepositoryImpl.toggleRepost`.
  @override
  Future<Result<Story, AppException>> markSeen(String storyId) async {
    final viewed = await apiCall(
      EndPoints.storiesView,
      () => _api.dio.post<dynamic>(
        EndPoints.storiesView,
        queryParameters: {'storyId': storyId},
      ),
      (envelope) => envelope.data != false,
    );
    return viewed.flatMapAsync((_) => getById(storyId));
  }

  /// Publishes a story. [body] is the `PublishStoryDto`: `mediaUrl` (the
  /// server rejects a story without one), `isVideo`, and an optional
  /// `caption`.
  @override
  Future<Result<Story, AppException>> create(Map<String, dynamic> body) {
    final caption = '${body['caption'] ?? ''}';
    return apiCall(
      EndPoints.storiesPublish,
      () => _api.dio.post<dynamic>(
        EndPoints.storiesPublish,
        data: {
          'mediaUrl': '${body['mediaUrl'] ?? ''}',
          'kind': StoryDto.kindToWire(body['isVideo'] == true),
          if (caption.trim().isNotEmpty) 'caption': caption,
        },
      ),
      (envelope) => StoryDto.fromJson(envelope.object).toDomain(),
    );
  }

  /// The module has no story-edit endpoint — a published story is immutable
  /// for the 24 hours it lives.
  @override
  Future<Result<Story, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    return const Result.failure(
      ForbiddenException('Stories cannot be edited after publishing'),
    );
  }

  /// **Not supported by the backend.** `StoriesController` exposes no delete
  /// action and `StoryService` has no soft-delete path, so a story can only
  /// leave the rail by expiring. Kept on the interface because
  /// `BaseRepository` requires it.
  @override
  Future<Result<void, AppException>> delete(String id) async {
    return const Result.failure(
      ForbiddenException(
        'A story cannot be deleted — it disappears 24 hours after it is '
        'published',
      ),
    );
  }

  // ── Decoders ─────────────────────────────────────────────────────────────

  /// The single-row read still comes back as a paged list, because the service
  /// only has `GetAsync` — the row has to be pulled out of it.
  Story _firstStory(ApiEnvelope envelope) {
    final rows = envelope.list;
    if (rows.isEmpty) throw const NotFoundException('Story not found');
    return StoryDto.fromJson(rows.first).toDomain();
  }
}

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
