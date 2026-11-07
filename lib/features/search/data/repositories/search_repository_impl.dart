import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/features/shared/people/data/dtos/person_dto.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/features/profile/data/dtos/profile_dto.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../../domain/entities/search_results.dart';
import '../../domain/entities/trending_tag.dart';
import '../../domain/repositories/search_repository.dart';
import '../dtos/search_dtos.dart';

/// Search against the module's `SearchController` / `HashtagsController`.
///
/// Unusually for this API these are plain **GETs with query strings** — search
/// takes no filter body — but the responses are still `ResultViewModel`
/// envelopes, so they go through [apiCall] like everything else and a 200 can
/// still carry `error: true`.
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// `SearchScopeEnum` names. The scope is a route SEGMENT, bound by name —
  /// `Profiles`, `Posts`, `Reels`, `Hashtags`, `Jobs`. An unknown word fails
  /// model binding with a 400, not a 404.
  static const String _profilesScope = 'Profiles';
  static const String _hashtagsScope = 'Hashtags';

  @override
  Future<Result<List<TrendingTag>, AppException>> trending({int take = 20}) {
    return apiCall(
      EndPoints.hashtagsTrending,
      () => _api.dio.get<dynamic>(
        EndPoints.hashtagsTrending,
        queryParameters: {'take': take},
      ),
      // The one search-side payload that really is a bare array.
      (envelope) => envelope.list
          .map((j) => HashtagDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<SearchResults, AppException>> blended(
    String query, {
    int take = 10,
  }) {
    return apiCall(
      EndPoints.search,
      () => _api.dio.get<dynamic>(
        EndPoints.search,
        queryParameters: {'q': query, 'take': take},
      ),
      (envelope) => SearchResultsDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<List<Person>, AppException>> people(
    String query, {
    int page = 1,
    int size = 20,
    AccountType? accountType,
  }) {
    final path = EndPoints.searchScope(_profilesScope);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(
        path,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
          if (accountType != null)
            'accountType': ProfileDto.accountTypeToWire(accountType),
        },
      ),
      // A `SearchPageDto`: one object with a populated list per scope, so the
      // rows are picked out by name rather than read off `envelope.list`.
      (envelope) => SearchResultsDto.rowsOf(envelope.object['profiles'])
          .map((j) => PersonDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<TrendingTag>, AppException>> hashtags(
    String query, {
    int page = 1,
    int size = 20,
  }) {
    final path = EndPoints.searchScope(_hashtagsScope);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(
        path,
        queryParameters: {'q': _withoutHash(query), 'page': page, 'size': size},
      ),
      (envelope) => SearchResultsDto.rowsOf(envelope.object['hashtags'])
          .map((j) => HashtagDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  /// Tags are matched with `StartsWith` against rows stored without their `#`,
  /// so a query that keeps the hash the user typed matches nothing at all.
  static String _withoutHash(String query) {
    final q = query.trim();
    return q.startsWith('#') ? q.substring(1) : q;
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
