import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/job_repository.dart';

/// Current jobs-list filters. Held outside the results notifier so a chip tap
/// doesn't have to round-trip through an AsyncValue to be reflected in the UI.
///
/// Deliberately not autoDispose: the chosen filters are the state of the jobs
/// tab and must survive the results provider being torn down.
final jobFiltersProvider = StateProvider<JobFilters>((ref) => const JobFilters());

const _jobSearchDebounce = Duration(milliseconds: 300);

/// [jobFiltersProvider] once the typed query has settled.
///
/// `POST Jobs` is a round trip per change, so a query read straight off the
/// field costs one request per character and all but the last answer a string
/// nobody finished typing. A chip, by contrast, is a finished decision the
/// moment it is tapped — so a change that leaves the query alone passes
/// straight through and only the text is held back.
class JobFiltersDebouncer extends AutoDisposeNotifier<JobFilters> {
  Timer? _timer;

  @override
  JobFilters build() {
    ref.listen(jobFiltersProvider, (previous, next) {
      // The previous character's timer has to die with it, or the older
      // string lands after the one the typist stopped on.
      _timer?.cancel();
      if (previous?.query == next.query) {
        state = next;
        return;
      }
      _timer = Timer(_jobSearchDebounce, () => state = next);
    });
    ref.onDispose(() => _timer?.cancel());
    return ref.read(jobFiltersProvider);
  }
}

final debouncedJobFiltersProvider =
    NotifierProvider.autoDispose<JobFiltersDebouncer, JobFilters>(
  JobFiltersDebouncer.new,
);

/// Search results for the settled filters.
final jobsSearchProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final filters = ref.watch(debouncedJobFiltersProvider);
  final result = await ref.watch(jobRepositoryProvider).search(filters);
  return result.when(success: (jobs) => jobs, failure: (e) => throw e);
});

/// One job, by id.
///
/// autoDispose because `Job.applied` is the server's `hasApplied` at fetch
/// time: cached for the life of the process, a job read before applying would
/// keep claiming it had not been applied to for the rest of the session.
final jobDetailProvider =
    FutureProvider.autoDispose.family<Job, String>((ref, id) async {
  final result = await ref.watch(jobRepositoryProvider).getById(id);
  return result.when(success: (job) => job, failure: (e) => throw e);
});

class ApplicationsNotifier extends AsyncNotifier<List<JobApplication>> {
  @override
  Future<List<JobApplication>> build() async {
    final result = await ref.read(jobRepositoryProvider).applications();
    return result.when(success: (apps) => apps, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(jobRepositoryProvider).applications();
      return result.when(success: (apps) => apps, failure: (e) => throw e);
    });
  }

  /// [resumeUrl] is a stored document location, not a picked file name — see
  /// `JobRepository.apply`. Nothing in the app produces one yet.
  Future<Result<JobApplication, AppException>> apply({
    required String jobId,
    String? resumeUrl,
    String coverLetter = '',
  }) async {
    final result = await ref.read(jobRepositoryProvider).apply(
          jobId: jobId,
          resumeUrl: resumeUrl,
          coverLetter: coverLetter,
        );
    result.when(
      success: (application) {
        state = AsyncValue.data([
          application,
          ...(state.valueOrNull ?? const <JobApplication>[])
              .where((a) => a.jobId != jobId),
        ]);
      },
      failure: (_) {},
    );
    return result;
  }
}

final applicationsNotifierProvider =
    AsyncNotifierProvider<ApplicationsNotifier, List<JobApplication>>(
  ApplicationsNotifier.new,
);

/// jobId → application, so a job card can show "تم التقديم" without each card
/// querying on its own.
///
/// This is not the same signal as `Job.applied`: the map is empty until the
/// applications list loads and only covers the page it fetched, while
/// `Job.applied` is the server's own `hasApplied` but is stale for a job row
/// fetched before the person applied. Widgets take either.
final applicationsByJobProvider = Provider<Map<String, JobApplication>>((ref) {
  final apps = ref.watch(applicationsNotifierProvider).valueOrNull;
  if (apps == null) return const {};
  return {for (final a in apps) a.jobId: a};
});
