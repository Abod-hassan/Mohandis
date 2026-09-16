import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_page.dart';
import '../../domain/repositories/reel_repository.dart';
import '../dtos/reel_dto.dart';

/// Reels against the RoboByte.SocialMedia module.
///
/// Same two house rules as posts: the list read is a POST carrying a
/// `ReelFilter` body with `?page=&size=` in the query — `viewerProfileId` is
/// set server-side from the bearer token and is never sent — and every
/// response is a `ResultViewModel` envelope that [apiCall] unwraps, including
/// the ones that arrive with a 200 and `error: true`.
class ReelRepositoryImpl implements ReelRepository {
  ReelRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const int _defaultPageSize = 20;

  // ── Reads ────────────────────────────────────────────────────────────────

  /// The reel wall.
  ///
  /// [query] accepts `onlySaved`, `onlyLiked`, `followedOnly`, `authorIds`,
  /// `search`, `page` and `size`. An empty filter is the whole public wall,
  /// newest first — what the reels tab wants — so omitted keys are left out
  /// entirely rather than sent as "no": the server's own defaults are the
  /// intent.
  @override
  Future<Result<ReelPage, AppException>> wall({Map<String, dynamic>? query}) {
    final page = query?['page'] ?? 1;
    final size = query?['size'] ?? _defaultPageSize;

    // Saved reels have their own GET, which needs no body and applies the
    // filter server-side — the caller cannot ask for someone else's.
    if (query?['onlySaved'] == true) {
      return apiCall(
        EndPoints.reelsSaved,
        () => _api.dio.get<dynamic>(
          EndPoints.reelsSaved,
          queryParameters: {'page': page, 'size': size},
        ),
        _reelPage,
      );
    }

    return apiCall(
      EndPoints.reels,
      () => _api.dio.post<dynamic>(
        EndPoints.reels,
        data: {
          if (query?['authorIds'] != null) 'authorIds': query!['authorIds'],
          if (query?['followedOnly'] != null)
            'followedOnly': query!['followedOnly'],
          if (query?['onlyLiked'] != null) 'onlyLiked': query!['onlyLiked'],
          if (query?['search'] != null) 'search': '${query!['search']}',
        },
        queryParameters: {'page': page, 'size': size},
      ),
      _reelPage,
    );
  }

  /// The first page of [wall], flattened — the shape [BaseRepository] asks
  /// for. Anything that pages must call [wall] instead, because `hasMore`
  /// cannot be inferred from a row count: the server may answer with fewer
  /// rows than the size it was asked for and still have another page.
  @override
  Future<Result<List<Reel>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    final page = await wall(query: query);
    return page.when(
      success: (p) => Result.success(p.reels),
      failure: (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<Reel, AppException>> getById(String id) {
    final path = EndPoints.reelById(id);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      // `GET Reels/{id}` runs the paged read with an id filter and hands the
      // whole envelope back, so the payload is a single-element list.
      _firstReel,
    );
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  @override
  Future<Result<Reel, AppException>> toggleLike(String reelId) {
    return apiCall(
      EndPoints.reelsLike,
      () => _api.dio.post<dynamic>(
        EndPoints.reelsLike,
        queryParameters: {'reelId': reelId},
      ),
      _reel,
    );
  }

  @override
  Future<Result<Reel, AppException>> toggleSave(String reelId) {
    return apiCall(
      EndPoints.reelsSave,
      () => _api.dio.post<dynamic>(
        EndPoints.reelsSave,
        queryParameters: {'reelId': reelId},
      ),
      _reel,
    );
  }

  /// Anonymous-friendly: `Reels/Play` never reads the caller's profile, so a
  /// play still counts while a token is being refreshed.
  @override
  Future<Result<bool, AppException>> markPlayed(String reelId) {
    return apiCall(
      EndPoints.reelsPlay,
      () => _api.dio.post<dynamic>(
        EndPoints.reelsPlay,
        queryParameters: {'reelId': reelId},
      ),
      (envelope) => envelope.data != false,
    );
  }

  /// Publishes a reel. [body] is the `PublishReelDto`: `videoUrl` (the server
  /// rejects a reel without one), and optional `thumbnailUrl`, `caption` and
  /// `durationSeconds`.
  ///
  /// Do not send a tags array — there is no field for one, and a reel's
  /// hashtags live in its caption.
  @override
  Future<Result<Reel, AppException>> create(Map<String, dynamic> body) {
    final caption = '${body['caption'] ?? ''}';
    return apiCall(
      EndPoints.reelsPublish,
      () => _api.dio.post<dynamic>(
        EndPoints.reelsPublish,
        data: {
          'videoUrl': '${body['videoUrl'] ?? ''}',
          if (body['thumbnailUrl'] != null)
            'thumbnailUrl': '${body['thumbnailUrl']}',
          if (caption.trim().isNotEmpty) 'caption': caption,
          if (body['durationSeconds'] != null)
            'durationSeconds': (body['durationSeconds'] as num).toDouble(),
        },
      ),
      _reel,
    );
  }

  /// The module has no reel-edit endpoint — a published reel is immutable.
  @override
  Future<Result<Reel, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    return const Result.failure(
      ForbiddenException('Reels cannot be edited after publishing'),
    );
  }

  /// Author-only soft delete. Anyone else gets "You can only delete your own
  /// reels." from the server rather than a 403, since the module reports its
  /// refusals through the envelope.
  @override
  Future<Result<void, AppException>> delete(String id) {
    final path = EndPoints.reelById(id);
    return apiCall(path, () => _api.dio.delete<dynamic>(path), (_) {});
  }

  // ── Decoders ─────────────────────────────────────────────────────────────

  ReelPage _reelPage(ApiEnvelope envelope) => ReelPage(
        reels: _reels(envelope),
        hasMore: envelope.hasMore,
      );

  List<Reel> _reels(ApiEnvelope envelope) => envelope.list
      .map((j) => ReelDto.fromJson(j).toDomain())
      .toList(growable: false);

  Reel _reel(ApiEnvelope envelope) =>
      ReelDto.fromJson(envelope.object).toDomain();

  Reel _firstReel(ApiEnvelope envelope) {
    final rows = envelope.list;
    if (rows.isEmpty) throw const NotFoundException('Reel not found');
    return ReelDto.fromJson(rows.first).toDomain();
  }
}

final reelRepositoryProvider = Provider<ReelRepository>((ref) {
  return ReelRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
