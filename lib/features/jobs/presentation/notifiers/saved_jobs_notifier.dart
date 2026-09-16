import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';

/// The caller's bookmarked jobs.
///
/// `autoDispose` and not cached across visits: `Job.saved` and `Job.applied`
/// are both viewer-relative snapshots taken at fetch time, and a list held for
/// the life of the process would keep showing a job the person un-saved from
/// the detail screen two taps ago.
final savedJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final result = await ref.watch(jobRepositoryProvider).saved();
  return result.when(success: (jobs) => jobs, failure: (e) => throw e);
});
