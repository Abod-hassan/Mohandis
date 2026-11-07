import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import 'company_jobs_notifier.dart';

/// Everything the company's opening screen shows, read in one pass.
class CompanyDashboard {
  const CompanyDashboard({
    required this.openJobs,
    required this.closedJobCount,
    required this.applicantCount,
    required this.newThisWeek,
    required this.pending,
  });

  /// Postings still taking applications, newest first, each with the count the
  /// server reports.
  final List<Job> openJobs;

  final int closedJobCount;

  /// Everyone who has applied, across every posting — summed from the count
  /// the server puts on each one, so it is a true total rather than a total of
  /// however many postings this screen had room to read.
  final int applicantCount;

  /// Applications received in the last seven days — the number that says
  /// whether anything is happening right now, which a running total does not.
  ///
  /// Counted over the postings actually scanned (see `_maxJobsToScan`), which
  /// are the newest ones: "recent applications to recent postings" is what it
  /// means, and an older posting quietly missing from it is not a number
  /// anybody would read as wrong.
  final int newThisWeek;

  /// Applications nobody has decided on yet: still `submitted` or `inReview`.
  /// Each carries the posting it belongs to, because the card opens that
  /// posting's applicant list.
  final List<PendingApplication> pending;

  int get openJobCount => openJobs.length;
}

/// One undecided application with the posting it came from.
class PendingApplication {
  const PendingApplication({required this.application, required this.job});

  final JobApplication application;
  final Job job;
}

/// How many postings' applicant lists the dashboard reads.
///
/// The module has no "all my applications" endpoint — applications are read
/// per posting — so this screen fans out. The cap is what keeps a company with
/// forty archived postings from making forty requests to fill one list; the
/// postings are ordered newest first, so the ones left out are the stale ones.
const int _maxJobsToScan = 8;

/// The newest undecided applications, across postings.
const int _maxPending = 6;

/// The company's dashboard.
///
/// Built on [companyJobsProvider] so a posting published from the jobs tab is
/// reflected here without a second source of truth — invalidating that one
/// refreshes this too.
final companyDashboardProvider = FutureProvider<CompanyDashboard>((ref) async {
  // Deliberately NOT watching the profile: the header reads that for itself.
  // Watching it here meant every unrelated profile write — an edit, a deleted
  // post — re-ran this provider's whole fan-out.
  final jobs = await ref.watch(companyJobsProvider.future);

  final openJobs = [for (final job in jobs) if (job.isOpen) job];
  final closedJobCount = jobs.length - openJobs.length;
  // Off the postings themselves, so this covers every one of them rather than
  // only the handful the scan below reads.
  final applicantCount = jobs.fold<int>(0, (sum, j) => sum + j.applicantCount);

  // Postings, not applications, are what the API pages over — so the scan is
  // per posting and bounded. A failure on one posting costs that posting's
  // applicants, not the dashboard.
  final repository = ref.watch(jobRepositoryProvider);
  final scanned = jobs.take(_maxJobsToScan).toList(growable: false);
  final lists = await Future.wait([
    for (final job in scanned)
      repository.applicants(job.id).then(
        (result) => result.when(
          success: (rows) => rows,
          failure: (_) => const <JobApplication>[],
        ),
      ),
  ]);

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  var newThisWeek = 0;
  final pending = <PendingApplication>[];

  for (var i = 0; i < scanned.length; i++) {
    for (final application in lists[i]) {
      if (application.submittedAt.isAfter(weekAgo)) newThisWeek++;
      if (application.status == ApplicationStatus.submitted ||
          application.status == ApplicationStatus.inReview) {
        pending.add(
          PendingApplication(application: application, job: scanned[i]),
        );
      }
    }
  }

  // Newest first: an application that has been waiting a week is a worse thing
  // to bury than one that arrived an hour ago is to show.
  pending.sort(
    (a, b) => b.application.submittedAt.compareTo(a.application.submittedAt),
  );

  return CompanyDashboard(
    openJobs: openJobs,
    closedJobCount: closedJobCount,
    applicantCount: applicantCount,
    newThisWeek: newThisWeek,
    pending: pending.take(_maxPending).toList(growable: false),
  );
});
