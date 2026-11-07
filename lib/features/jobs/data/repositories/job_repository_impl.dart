import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/job_repository.dart';
import '../dtos/job_application_dto.dart';
import '../dtos/job_dto.dart';

/// Jobs against the RoboByte.SocialMedia module (`JobsController`).
///
/// The same three shape rules as the rest of the module drive this class:
///
///   * **Reads are POSTs with a filter body.** `POST /api/social/Jobs` takes a
///     `JobFilter` plus `?page&size`; there is no query-string list endpoint,
///     and `viewerProfileId` is filled server-side from the bearer token, so
///     it is never sent from here.
///   * **Every response is a `ResultViewModel` envelope**, unwrapped by
///     [apiCall]. A 200 can still carry `error: true` — and the job service
///     reports every one of its refusals ("This job is closed.", "You have
///     already applied…") that way rather than by status code.
///   * **Enums travel by name.** `StringEnumConverter` is registered
///     host-side; `JobDto` owns both directions.
class JobRepositoryImpl implements JobRepository {
  JobRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const int _defaultPageSize = 20;

  // ── Reads ────────────────────────────────────────────────────────────────

  /// Every job the caller can see, for use as a lookup table rather than a
  /// browse list — hence `openOnly: false`: a closed posting still has to
  /// resolve to a title for an existing application or an embedded job card.
  ///
  /// [query] is merged into the `JobFilter` body, so a caller can narrow it
  /// (`{'postedById': ...}`) without a bespoke method.
  @override
  Future<Result<List<Job>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) {
    return _list({
      'openOnly': false,
      'orderBy': 'Newest',
      'descending': true,
      ...?query,
    }, size: 50);
  }

  @override
  Future<Result<List<Job>, AppException>> search(JobFilters filters) {
    return _list(_filterBody(filters));
  }

  /// `openOnly: false` on purpose: a job saved while open and closed since is
  /// still on the person's list, and dropping it silently would read as the
  /// bookmark having been lost.
  @override
  Future<Result<List<Job>, AppException>> saved() {
    return _list({
      'onlySaved': true,
      'openOnly': false,
      'orderBy': 'Newest',
      'descending': true,
    }, size: 50);
  }

  @override
  Future<Result<Job, AppException>> toggleSave(String jobId) {
    return apiCall(
      EndPoints.jobsSave,
      () => _api.dio.post<dynamic>(
        EndPoints.jobsSave,
        queryParameters: {'jobId': jobId},
      ),
      (envelope) => JobDto.fromJson(envelope.object).toDomain(),
    );
  }

  /// `JobFilters` → `JobFilter`.
  ///
  /// The "الكل" chip drops `workplaceType` from the body entirely.
  /// `WorkplaceTypeEnum` has only the three real modes and no "any" member, so
  /// there is nothing to send for it — every value narrows the list, and an
  /// invented sentinel would fail to deserialise and take the whole read with
  /// it.
  Map<String, dynamic> _filterBody(JobFilters filters) {
    final search = filters.query.trim();
    return {
      if (search.isNotEmpty) 'search': search,
      if (filters.workMode != null)
        'workplaceType': JobDto.workModeToWire(filters.workMode!),
      // Browsing shows open postings only; the detail screen reaches closed
      // ones directly by id, where the controller overrides this anyway.
      'openOnly': true,
      'orderBy': 'Newest',
      'descending': true,
    };
  }

  Future<Result<List<Job>, AppException>> _list(
    Map<String, dynamic> filter, {
    int page = 1,
    int size = _defaultPageSize,
  }) {
    return apiCall(
      EndPoints.jobs,
      () => _api.dio.post<dynamic>(
        EndPoints.jobs,
        data: filter,
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) =>
          envelope.list.map((j) => JobDto.fromJson(j).toDomain()).toList(
            growable: false,
          ),
    );
  }

  @override
  Future<Result<Job, AppException>> getById(String id) {
    final path = EndPoints.jobById(id);
    return apiCall(path, () => _api.dio.get<dynamic>(path), (envelope) {
      // `GET Jobs/{id}` runs a one-row paged read, so the envelope carries a
      // single-element list rather than the object.
      final rows = envelope.list;
      if (rows.isEmpty) {
        throw const NotFoundException('لم يتم العثور على الوظيفة');
      }
      return JobDto.fromJson(rows.first).toDomain();
    });
  }

  // ── Applications ─────────────────────────────────────────────────────────

  @override
  Future<Result<List<JobApplication>, AppException>> applications() {
    return apiCall(
      EndPoints.jobsMyApplications,
      () => _api.dio.get<dynamic>(
        EndPoints.jobsMyApplications,
        // No filter body here — the controller pins `applicantId` to the
        // caller. One generous page: the screen has no paging affordance, and
        // `applicationsByJobProvider` is only right for the rows it holds.
        queryParameters: {'page': 1, 'size': 50},
      ),
      (envelope) => envelope.list
          .map((j) => JobApplicationDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<JobApplication, AppException>> apply({
    required String jobId,
    String? resumeUrl,
    String coverLetter = '',
  }) async {
    final letter = coverLetter.trim();
    final resume = resumeUrl?.trim() ?? '';

    final posted = await apiCall<void>(
      EndPoints.jobsApply,
      () => _api.dio.post<dynamic>(
        EndPoints.jobsApply,
        queryParameters: {'jobId': jobId},
        // `ApplyJobDto` is `{ coverLetter?, resumeUrl? }` and both are stored
        // verbatim, so an empty string would be written as an empty string.
        data: {
          if (letter.isNotEmpty) 'coverLetter': letter,
          if (resume.isNotEmpty) 'resumeUrl': resume,
        },
      ),
      // The response is the updated JOB, not the application — see below.
      (_) {},
    );
    if (posted.isFailure) {
      return Result.failure(_applyFailure(posted.errorOrNull!));
    }

    // `Jobs/Apply` answers with the job (its `hasApplied` now true), while
    // every caller here wants the row that was just created. There is no
    // "get one application" endpoint, so the list is re-read: it is ordered
    // by creation date descending server-side, which puts the new row first.
    final list = await applications();
    return list.when<Result<JobApplication, AppException>>(
      success: (rows) {
        final mine = rows.where((a) => a.jobId == jobId);
        if (mine.isEmpty) return Result.success(_placeholderFor(jobId, letter));
        return Result.success(mine.first);
      },
      // The write already succeeded, so a failed read-back must not be
      // reported as a failed application — the applicant would be shown an
      // error and would apply again, only to be told they already had.
      failure: (_) => Result.success(_placeholderFor(jobId, letter)),
    );
  }

  /// A local stand-in for an application the server accepted but did not hand
  /// back on the follow-up read.
  ///
  /// Reachable two ways: the read-back itself failed, or the new row fell
  /// outside page 1 of `my-applications`. Either way the write is done, so the
  /// applicant must see the success screen. The empty [JobApplication.id]
  /// marks it as not-yet-reconciled; the next load of the list replaces it
  /// with the server's row, and nothing keys off the id — the screens match
  /// applications by `jobId`.
  JobApplication _placeholderFor(String jobId, String coverLetter) {
    return JobApplication(
      id: '',
      jobId: jobId,
      status: ApplicationStatus.submitted,
      submittedAt: DateTime.now(),
      coverLetter: coverLetter,
    );
  }

  /// The job service refuses in plain English inside a 200/400 envelope.
  ///
  /// "You have already applied to this job." would otherwise reach
  /// `arabicErrorFor`, whose `already` row is about phone numbers — the
  /// applicant would be told their number is registered. Rewritten to the copy
  /// this screen has always shown.
  AppException _applyFailure(AppException e) {
    if (e.message.toLowerCase().contains('already applied')) {
      return const ValidationException('لقد قدّمت على هذه الوظيفة بالفعل');
    }
    return e;
  }

  // ── The poster's side ────────────────────────────────────────────────────

  @override
  Future<Result<List<Job>, AppException>> postedBy(String profileId) {
    // `openOnly: false` because a company's own list must keep showing a
    // posting it has closed — it still holds the applicants they came to read.
    return _list({
      'postedById': profileId,
      'openOnly': false,
      'orderBy': 'Newest',
      'descending': true,
    }, size: 50);
  }

  @override
  Future<Result<List<JobApplication>, AppException>> applicants(String jobId) {
    final path = EndPoints.jobApplications(jobId);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(
        path,
        // One generous page: the screen has no paging affordance, and a
        // posting with more than 50 applicants is not the case to optimise for
        // before the list itself is proven.
        queryParameters: {'page': 1, 'size': 50},
      ),
      (envelope) => envelope.list
          .map((a) => JobApplicationDto.fromJson(a).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<bool, AppException>> setApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) {
    final path = EndPoints.jobApplicationStatus(applicationId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        // A query parameter, and by NAME — the server numbers `Rejected`
        // before `Accepted`, the reverse of the app's enum, so an ordinal here
        // would accept the people a company just rejected.
        queryParameters: {'status': JobApplicationDto.statusToWire(status)},
      ),
      (envelope) => envelope.data == true,
    );
  }

  @override
  Future<Result<Job, AppException>> publish({
    required String title,
    required String company,
    String? location,
    EmploymentType? employmentType,
    WorkMode? workMode,
    String description = '',
    String? requirements,
    num? salaryMin,
    num? salaryMax,
    String? currency,
  }) {
    // Optional fields are omitted rather than sent empty: `JobForm` stores
    // what it is given verbatim, so a blank string becomes a blank location on
    // the posting instead of no location at all.
    String? trimmed(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return create({
      'title': title.trim(),
      'companyName': company.trim(),
      if (trimmed(location) != null) 'location': trimmed(location),
      if (employmentType != null)
        'employmentType': JobDto.employmentTypeToWire(employmentType),
      if (workMode != null) 'workplaceType': JobDto.workModeToWire(workMode),
      'description': description.trim(),
      if (trimmed(requirements) != null) 'requirements': trimmed(requirements),
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (trimmed(currency) != null) 'currency': trimmed(currency),
      'isOpen': true,
    });
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Posts a job. [body] is a `JobForm`: `title` and `companyName` are
  /// required server-side, and `location`, `employmentType`, `workplaceType`,
  /// `description`, `requirements`, `salaryMin`, `salaryMax`, `currency`,
  /// `isOpen` and `closesAt` are optional. `postedById` is ignored — the
  /// controller overwrites it with the caller's profile.
  @override
  Future<Result<Job, AppException>> create(Map<String, dynamic> body) {
    return apiCall(
      EndPoints.jobsPublish,
      () => _api.dio.post<dynamic>(EndPoints.jobsPublish, data: body),
      // Publish returns a single `JobDto`, not a paged list.
      (envelope) => JobDto.fromJson(envelope.object).toDomain(),
    );
  }

  /// `JobsController` exposes no edit route — a posting is written once by the
  /// Kernel's generic write engine and only its `IsOpen` flag and application
  /// count move afterwards, both server-side.
  @override
  Future<Result<Job, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    return const Result.failure(
      ForbiddenException('Job postings cannot be edited after publishing'),
    );
  }

  /// No delete route either. Closing a posting (`IsOpen = false`) is the
  /// intended lifecycle, and there is no endpoint for that from mobile.
  @override
  Future<Result<void, AppException>> delete(String id) async {
    return const Result.failure(
      ForbiddenException('Job postings cannot be deleted from mobile'),
    );
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// Id → [Job] lookup. The feed uses it to render shared-job embeds, and the
/// applications screen to put a title on each row, without fetching each
/// posting individually.
///
/// It is one page deep, so a job outside the newest 50 resolves to null and
/// its card falls back to the placeholder. Both callers already handle that;
/// fixing it properly needs a "jobs by id" read the module does not have.
final jobsDirectoryProvider = FutureProvider<Map<String, Job>>((ref) async {
  final result = await ref.watch(jobRepositoryProvider).getAll();
  return result.when(
    success: (jobs) => {for (final j in jobs) j.id: j},
    failure: (e) => throw e,
  );
});
