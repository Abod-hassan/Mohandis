import 'package:mohandis/core/base/base_dto.dart';
import 'package:mohandis/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/job_application.dart';

/// Wire model for the backend's `JobApplicationDto`
/// (`GET /api/social/Jobs/my-applications`, `GET Jobs/{id}/applications`).
///
/// The applicant's identity rides on the row because the poster's view of the
/// same endpoint needs it; the applicant's own list already knows who it is.
/// The timestamp is `createdAt`, not `submittedAt` — an application is created
/// by being submitted, so there is only ever one date.
class JobApplicationDto implements BaseDto<JobApplication> {
  const JobApplicationDto({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    this.applicantName = '',
    this.applicantHeadline = '',
    this.applicantAvatarUrl,
    this.coverLetter,
    this.resumeUrl,
  });

  factory JobApplicationDto.fromJson(Map<String, dynamic> json) =>
      JobApplicationDto(
        id: '${json['id'] ?? ''}',
        jobId: '${json['jobId'] ?? ''}',
        applicantId: '${json['applicantId'] ?? ''}',
        applicantName: '${json['applicantName'] ?? ''}',
        applicantHeadline: '${json['applicantHeadline'] ?? ''}',
        applicantAvatarUrl: json['applicantAvatarUrl'] as String?,
        coverLetter: json['coverLetter'] as String?,
        resumeUrl: json['resumeUrl'] as String?,
        status: statusFromWire(json['status']),
        createdAt: PostDto.parseDate(json['createdAt']),
      );

  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final String applicantHeadline;
  final String? applicantAvatarUrl;
  final String? coverLetter;
  final String? resumeUrl;
  final ApplicationStatus status;
  final DateTime createdAt;

  @override
  JobApplication toDomain() => JobApplication(
    id: id,
    jobId: jobId,
    status: status,
    submittedAt: createdAt,
    resumeUrl: resumeUrl ?? '',
    coverLetter: coverLetter ?? '',
    applicantId: applicantId,
    applicantHeadline: applicantHeadline,
    applicantName: applicantName,
    applicantAvatarUrl: applicantAvatarUrl,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'applicantId': applicantId,
    'applicantName': applicantName,
    'applicantHeadline': applicantHeadline,
    'applicantAvatarUrl': applicantAvatarUrl,
    'coverLetter': coverLetter,
    'resumeUrl': resumeUrl,
    'status': statusToWire(status),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// `JobApplicationStatusEnum` — `Submitted`, `Reviewed`, `Shortlisted`,
  /// `Interviewing`, `Rejected`, `Accepted`.
  ///
  /// Neither shortcut works here. `ApplicationStatus.values.byName` misses on
  /// two of the six (`Reviewed` → `inReview`, `Interviewing` → `interview`),
  /// and `values[i]` swaps the last two outright: the server numbers
  /// `Rejected = 4, Accepted = 5`, while the stepper's enum lists accepted
  /// first so that both decisions land on step 4. Reading a rejection as an
  /// acceptance is the one mistake this file must not make.
  ///
  /// An unknown value degrades to [ApplicationStatus.submitted] — the stepper
  /// then shows its first step rather than throwing on a status added later.
  static ApplicationStatus statusFromWire(Object? raw) {
    if (raw is num) {
      return switch (raw.toInt()) {
        1 => ApplicationStatus.inReview,
        2 => ApplicationStatus.shortlisted,
        3 => ApplicationStatus.interview,
        4 => ApplicationStatus.rejected,
        5 => ApplicationStatus.accepted,
        _ => ApplicationStatus.submitted,
      };
    }
    return switch ('$raw'.toLowerCase()) {
      'reviewed' => ApplicationStatus.inReview,
      'shortlisted' => ApplicationStatus.shortlisted,
      'interviewing' => ApplicationStatus.interview,
      'rejected' => ApplicationStatus.rejected,
      'accepted' => ApplicationStatus.accepted,
      _ => ApplicationStatus.submitted,
    };
  }

  static String statusToWire(ApplicationStatus status) => switch (status) {
    ApplicationStatus.submitted => 'Submitted',
    ApplicationStatus.inReview => 'Reviewed',
    ApplicationStatus.shortlisted => 'Shortlisted',
    ApplicationStatus.interview => 'Interviewing',
    ApplicationStatus.rejected => 'Rejected',
    ApplicationStatus.accepted => 'Accepted',
  };
}
