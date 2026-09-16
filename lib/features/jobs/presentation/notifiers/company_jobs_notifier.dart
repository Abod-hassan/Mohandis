import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/profile/presentation/notifiers/profile_notifier.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';

/// The signed-in company's own postings, newest first.
///
/// Keyed off `profileNotifierProvider('me')` rather than taking an id: every
/// company surface is about the caller's own postings, and threading an id
/// through would only create a way to ask for someone else's — which the
/// server refuses anyway.
///
/// Not autoDispose: it is a tab root, and the list is re-read after a publish
/// rather than on every visit.
final companyJobsProvider = FutureProvider<List<Job>>((ref) async {
  final profile = await ref.watch(profileNotifierProvider('me').future);
  final result = await ref.watch(jobRepositoryProvider).postedBy(
    profile.personId,
  );
  return result.when(success: (jobs) => jobs, failure: (e) => throw e);
});

/// The applicants for one posting, with the status writes that act on them.
///
/// autoDispose because a company reads a posting's applicants, acts, and moves
/// on; holding every posting's list for the session would keep stale decisions
/// on screen the next time they open it.
class JobApplicantsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<JobApplication>, String> {
  @override
  Future<List<JobApplication>> build(String jobId) async {
    final result = await ref.watch(jobRepositoryProvider).applicants(jobId);
    return result.when(success: (rows) => rows, failure: (e) => throw e);
  }

  /// Moves one application along.
  ///
  /// Optimistic: the row flips the moment the button is tapped, and reverts if
  /// the server refuses. The endpoint answers `true` rather than the updated
  /// row, so there is nothing to reconcile against — which is exactly why the
  /// failure path has to restore the previous list rather than re-read.
  Future<Result<bool, AppException>> setStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data([
        for (final a in previous)
          a.id == applicationId ? a.copyWith(status: status) : a,
      ]);
    }

    final result = await ref
        .read(jobRepositoryProvider)
        .setApplicationStatus(applicationId: applicationId, status: status);

    result.when(
      success: (_) {},
      failure: (_) {
        if (previous != null) state = AsyncValue.data(previous);
      },
    );
    return result;
  }
}

final jobApplicantsProvider =
    AsyncNotifierProvider.autoDispose
        .family<JobApplicantsNotifier, List<JobApplication>, String>(
          JobApplicantsNotifier.new,
        );
