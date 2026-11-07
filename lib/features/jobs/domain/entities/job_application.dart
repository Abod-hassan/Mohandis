import 'package:mohandis/core/base/base_entity.dart';

/// Application lifecycle. The order of these values is the order of the
/// status stepper — [accepted] and [rejected] are both the final step, so
/// they share [ApplicationStatus.stepIndex] 4.
///
/// This is NOT the server's `JobApplicationStatusEnum` order (`Rejected = 4`
/// comes before `Accepted = 5` there) and two members are spelled differently
/// (`Reviewed`, `Interviewing`). `JobApplicationDto.statusFromWire` owns the
/// translation; neither `values[i]` nor `byName` is safe.
enum ApplicationStatus {
  submitted,
  inReview,
  shortlisted,
  interview,
  accepted,
  rejected;

  int get stepIndex => switch (this) {
        ApplicationStatus.submitted => 0,
        ApplicationStatus.inReview => 1,
        ApplicationStatus.shortlisted => 2,
        ApplicationStatus.interview => 3,
        ApplicationStatus.accepted => 4,
        ApplicationStatus.rejected => 4,
      };

  bool get isDecided =>
      this == ApplicationStatus.accepted || this == ApplicationStatus.rejected;
}

class JobApplication extends BaseEntity {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.status,
    required this.submittedAt,
    this.resumeUrl = '',
    this.coverLetter = '',
    this.applicantId = '',
    this.applicantName = '',
    this.applicantHeadline = '',
    this.applicantAvatarUrl,
  });

  @override
  final String id;

  final String jobId;
  final ApplicationStatus status;
  final DateTime submittedAt;

  /// The stored résumé location, not a file name — the backend column is
  /// `ResumeUrl` and the poster's applicant list opens it as a link. Empty
  /// until the app can actually upload a document somewhere; see
  /// `JobRepository.apply`.
  final String resumeUrl;

  final String coverLetter;

  /// Who applied.
  ///
  /// Empty on the applicant's own list — they know who they are, and the
  /// endpoint pins the row to them anyway. Filled on the poster's view, which
  /// is the whole point of that screen: a company's applicant list is a list
  /// of people, and it renders them without a directory lookup.
  final String applicantId;
  final String applicantName;

  /// The applicant's own one-line description — what they do, in their words.
  /// Empty on the applicant's own list, and on a profile that never set one.
  final String applicantHeadline;

  /// Stored host-less like every other image; resolve before rendering.
  final String? applicantAvatarUrl;

  JobApplication copyWith({ApplicationStatus? status}) => JobApplication(
    id: id,
    jobId: jobId,
    status: status ?? this.status,
    submittedAt: submittedAt,
    resumeUrl: resumeUrl,
    coverLetter: coverLetter,
    applicantId: applicantId,
    applicantName: applicantName,
    applicantHeadline: applicantHeadline,
    applicantAvatarUrl: applicantAvatarUrl,
  );
}
