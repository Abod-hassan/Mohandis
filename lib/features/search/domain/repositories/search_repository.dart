import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import '../entities/search_results.dart';
import '../entities/trending_tag.dart';

/// Search owns the module's `SearchController` and `HashtagsController`.
///
/// People come back as [Person] because the backend's own search returns the
/// same `ProfileSimplifiedDto` the people directory is built from — this is
/// one more way to reach that projection, not a second person model. Jobs stay
/// with the jobs feature: its repository already searches them and can also
/// serve the no-query case, which the search endpoints cannot.
abstract class SearchRepository {
  /// The most-used tags right now. No query — this is the empty-search state.
  Future<Result<List<TrendingTag>, AppException>> trending({int take = 20});

  /// A few of everything for [query] in one round-trip. Answers empty for a
  /// blank query, which the service rejects before it reaches Postgres.
  Future<Result<SearchResults, AppException>> blended(
    String query, {
    int take = 10,
  });

  /// The `Profiles` slice, paged — full-text over username, display name and
  /// bio, so it matches more than the profile filter's name search.
  Future<Result<List<Person>, AppException>> people(
    String query, {
    int page = 1,
    int size = 20,
  });

  /// The `Hashtags` slice, paged — a prefix match, not full text.
  Future<Result<List<TrendingTag>, AppException>> hashtags(
    String query, {
    int page = 1,
    int size = 20,
  });
}
