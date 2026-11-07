import 'package:flutter/widgets.dart';

import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';

extension WorkModeLabel on WorkMode {
  String label(BuildContext context) => switch (this) {
        WorkMode.remote => context.l10n.jobsFilterRemote,
        WorkMode.hybrid => context.l10n.jobsFilterHybrid,
        WorkMode.onsite => context.l10n.jobsFilterOnsite,
      };
}

extension EmploymentTypeLabel on EmploymentType {
  /// One string per member, from the `employment*` set the CV editor already
  /// uses.
  ///
  /// These used to collapse `freelance`, `selfEmployed` and `temporary` onto
  /// "عقد" for want of copy — which put three identical options in a picker
  /// where nobody could tell them apart, and made the chosen one unreadable
  /// afterwards. The copy existed the whole time, one screen over; the two
  /// screens now share it, so a seventh member cannot be labelled in one place
  /// and missed in the other.
  String label(BuildContext context) => switch (this) {
        EmploymentType.fullTime => context.l10n.employmentFullTime,
        EmploymentType.partTime => context.l10n.employmentPartTime,
        EmploymentType.contract => context.l10n.employmentContract,
        EmploymentType.internship => context.l10n.employmentInternship,
        EmploymentType.freelance => context.l10n.employmentFreelance,
        EmploymentType.selfEmployed => context.l10n.employmentSelfEmployed,
        EmploymentType.temporary => context.l10n.employmentTemporary,
      };
}

extension ApplicationStatusLabel on ApplicationStatus {
  String label(BuildContext context) => switch (this) {
        ApplicationStatus.submitted => context.l10n.applicationStatusSubmitted,
        ApplicationStatus.inReview => context.l10n.applicationStatusInReview,
        ApplicationStatus.shortlisted =>
          context.l10n.applicationStatusShortlisted,
        ApplicationStatus.interview => context.l10n.applicationStatusInterview,
        ApplicationStatus.accepted => context.l10n.applicationStatusAccepted,
        ApplicationStatus.rejected => context.l10n.applicationStatusRejected,
      };
}

/// The five stepper labels, in order.
List<String> applicationStepLabels(BuildContext context) => [
      context.l10n.applicationStepSubmitted,
      context.l10n.applicationStepReview,
      context.l10n.applicationStepShortlist,
      context.l10n.applicationStepInterview,
      context.l10n.applicationStepDecision,
    ];
