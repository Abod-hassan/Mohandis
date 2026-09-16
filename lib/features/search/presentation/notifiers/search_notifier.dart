import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:flutter_mobile_template/features/jobs/domain/entities/job.dart';
import 'package:flutter_mobile_template/features/jobs/domain/repositories/job_repository.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/entities/trending_tag.dart';

enum SearchTab { top, people, jobs, tags }

/// The live query. Kept separate from the results so typing rebuilds only the
/// field, and the async result provider re-runs off the debounced value.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

const _searchDebounce = Duration(milliseconds: 300);

/// [searchQueryProvider] once it has stopped changing for [_searchDebounce].
///
/// Every scope the screen shows is its own round trip, so a query read
/// straight off the field costs one request per character and all but the
/// last are answers to a string nobody finished typing.
class SearchQueryDebouncer extends AutoDisposeNotifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.listen(searchQueryProvider, (_, next) {
      // The previous character's timer has to die with it, or the older
      // string lands after the one the typist stopped on.
      _timer?.cancel();
      _timer = Timer(_searchDebounce, () => state = next);
    });
    ref.onDispose(() => _timer?.cancel());
    return ref.read(searchQueryProvider);
  }
}

final debouncedSearchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryDebouncer, String>(
  SearchQueryDebouncer.new,
);

final searchTabProvider =
    StateProvider.autoDispose<SearchTab>((ref) => SearchTab.top);

/// The Top tab: one blended call covering every section it shows.
///
/// The backend rejects a blank `q` before it reaches Postgres, so the landing
/// state — the tab a search opens on — is composed from trending tags and the
/// people directory instead. That is exactly what the tab showed before there
/// was a search backend.
final searchResultsProvider =
    FutureProvider.autoDispose<SearchResults>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider).trim();
  // Both repositories are resolved before the first await: reading a provider
  // afterwards races this one's own disposal when the query changes mid-flight.
  final search = ref.watch(searchRepositoryProvider);
  final directory = ref.watch(peopleRepositoryProvider);

  if (query.isEmpty) {
    // Two independent reads: awaited in series the landing state waits out
    // both, and neither repository throws, so nothing is left unhandled.
    final trending = search.trending();
    final profiles = directory.search(query);
    final tags = await trending;
    final people = await profiles;
    return SearchResults(
      people: people.when(success: (p) => p, failure: (e) => throw e),
      tags: tags.when(success: (t) => t, failure: (e) => throw e),
    );
  }

  final result = await search.blended(query);
  return result.when(success: (results) => results, failure: (e) => throw e);
});

/// The People tab — the paged `Profiles` slice. An empty query falls back to
/// the directory so the tab always has something to show.
final searchPeopleProvider =
    FutureProvider.autoDispose<List<Person>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider).trim();
  final result = query.isEmpty
      ? await ref.watch(peopleRepositoryProvider).search(query)
      : await ref.watch(searchRepositoryProvider).people(query);
  return result.when(success: (people) => people, failure: (e) => throw e);
});

/// The Tags tab — trending until there is something to match against.
final searchTagsProvider =
    FutureProvider.autoDispose<List<TrendingTag>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider).trim();
  final search = ref.watch(searchRepositoryProvider);
  final result =
      query.isEmpty ? await search.trending() : await search.hashtags(query);
  return result.when(success: (tags) => tags, failure: (e) => throw e);
});

/// Jobs keep coming from the jobs feature: `JobFilter` searches the same rows
/// the `Jobs` search scope does, and unlike that scope it also answers the
/// empty query, which this tab needs.
final searchJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider).trim();
  final result =
      await ref.watch(jobRepositoryProvider).search(JobFilters(query: query));
  return result.when(success: (jobs) => jobs, failure: (e) => throw e);
});
