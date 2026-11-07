import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_mock_repository.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../../domain/entities/search_results.dart';
import '../../domain/entities/trending_tag.dart';
import '../../domain/repositories/search_repository.dart';

class SearchMockRepository implements SearchRepository {
  SearchMockRepository({this.latency = const Duration(milliseconds: 160)});

  final Duration latency;

  /// The demo cast rather than a second copy of it — mock search has to return
  /// the same people every other mock screen renders.
  final PeopleMockRepository _people = PeopleMockRepository();

  static const List<TrendingTag> _trending = [
    TrendingTag(tag: '#أنظمة_التصميم', postCount: 4208),
    TrendingTag(tag: '#التوظيف', postCount: 12100),
    TrendingTag(tag: '#علم_البيانات', postCount: 2940),
    TrendingTag(tag: '#العمل_عن_بعد', postCount: 8760),
    TrendingTag(tag: '#القيادة', postCount: 6330),
  ];

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<Result<List<TrendingTag>, AppException>> trending({
    int take = 20,
  }) async {
    await _wait();
    return Result.success(_trending.take(take).toList(growable: false));
  }

  @override
  Future<Result<SearchResults, AppException>> blended(
    String query, {
    int take = 10,
  }) async {
    final people = await _people.search(query);
    final tags = await hashtags(query, size: take);
    return Result.success(
      SearchResults(
        people: (people.valueOrNull ?? const <Person>[])
            .take(take)
            .toList(growable: false),
        tags: tags.valueOrNull ?? const <TrendingTag>[],
      ),
    );
  }

  @override
  Future<Result<List<Person>, AppException>> people(
    String query, {
    int page = 1,
    int size = 20,
    AccountType? accountType,
  }) =>
      _people.search(query, accountType: accountType);

  @override
  Future<Result<List<TrendingTag>, AppException>> hashtags(
    String query, {
    int page = 1,
    int size = 20,
  }) async {
    await _wait();
    final q = query.trim().replaceFirst('#', '').toLowerCase();
    final matches = q.isEmpty
        ? _trending
        : _trending
            .where((t) => t.tag.toLowerCase().contains(q))
            .toList(growable: false);
    return Result.success(matches.take(size).toList(growable: false));
  }
}
