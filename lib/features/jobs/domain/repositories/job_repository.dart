import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/job.dart';
import '../entities/job_application.dart';

/// Search filters for the jobs list.
///
/// A null [workMode] is "الكل", and it means the key is left out of the
/// `JobFilter` body entirely — there is no server-side value for "any", so
/// sending one would narrow the list to a single workplace type. The
/// translation to the wire lives in `JobRepositoryImpl`; this stays a plain
/// value object so the domain layer keeps no knowledge of the API shape.
class JobFilters {
  const JobFilters({this.query = '', this.workMode});

  final String query;
  final WorkMode? workMode;

  JobFilters copyWith({
    String? query,
    WorkMode? workMode,
    bool clearWorkMode = false,
  }) {
    return JobFilters(
      query: query ?? this.query,
      workMode: clearWorkMode ? null : (workMode ?? this.workMode),
    );
  }
}

abstract class JobRepository extends BaseRepository<Job> {
  Future<Result<List<Job>, AppException>> search(JobFilters filters);

  /// The signed-in person's own applications, newest first.
  Future<Result<List<JobApplication>, AppException>> applications();

  /// Jobs the caller has bookmarked, newest first.
  Future<Result<List<Job>, AppException>> saved();

  /// Toggles the caller's bookmark and returns the job as the server sees it,
  /// so an optimistic tap can be reconciled rather than trusted.
  Future<Result<Job, AppException>> toggleSave(String jobId);

  /// Applies to [jobId] and returns the application row that was created.
  ///
  /// [resumeUrl] is a STORED location, not a picked file name: the backend
  /// column is `ResumeUrl` and the poster's applicant list renders it as a
  /// link, so a bare file name would read to them as a CV that fails to open.
  /// The apply screen uploads the document first and passes the path back.
  /// Omitted when null, in which case the server falls back to the CV on the
  /// applicant's profile — and refuses the application if there is none.
  Future<Result<JobApplication, AppException>> apply({
    required String jobId,
    String? resumeUrl,
    String coverLetter,
  });

  // ── The poster's side ────────────────────────────────────────────────────

  /// Every job [profileId] has posted, open and closed.
  ///
  /// Closed ones are included deliberately: this backs a company's own list of
  /// its postings, where a closed posting is still theirs, still has applicants
  /// to look at, and hiding it would read as data loss.
  Future<Result<List<Job>, AppException>> postedBy(String profileId);

  /// Who applied to [jobId], newest first.
  ///
  /// Poster-only server-side — anyone else gets a 403, surfaced here as a
  /// [ForbiddenException].
  Future<Result<List<JobApplication>, AppException>> applicants(String jobId);

  /// Moves an application to [status]. Poster-only, same as [applicants].
  ///
  /// The server answers `true` rather than the updated row, so callers patch
  /// their own copy — see [JobApplication.copyWith].
  Future<Result<bool, AppException>> setApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  });

  /// Posts a new job on the caller's behalf and returns the created row.
  ///
  /// [title] and [company] are the server's only required fields; everything
  /// else is optional on `JobForm` and omitted from the body when empty rather
  /// than sent blank.
  Future<Result<Job, AppException>> publish({
    required String title,
    required String company,
    String? location,
    EmploymentType? employmentType,
    WorkMode? workMode,
    String description,
    String? requirements,
    num? salaryMin,
    num? salaryMax,
    String? currency,
  });
}
