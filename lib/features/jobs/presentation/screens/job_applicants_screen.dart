import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/job_application.dart';
import '../notifiers/company_jobs_notifier.dart';
import '../notifiers/jobs_notifier.dart';
import '../widgets/job_labels.dart';

/// Everyone who applied to one posting, and the decisions the company can make
/// about them.
class JobApplicantsScreen extends ConsumerWidget {
  const JobApplicantsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final applicants = ref.watch(jobApplicantsProvider(jobId));
    // Only for the title. A failure here leaves the generic heading rather
    // than blocking the list the company actually came for.
    final job = ref.watch(jobDetailProvider(jobId)).valueOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: job?.title ?? l10n.companyApplicantsTitle),
      body: applicants.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(jobApplicantsProvider(jobId)),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.companyNoApplicants,
                message: l10n.companyNoApplicantsHint,
                icon: Icons.person_search_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(jobApplicantsProvider(jobId)),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _ApplicantCard(jobId: jobId, application: list[i]),
                ),
              ),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({required this.jobId, required this.application});

  final String jobId;
  final JobApplication application;

  /// The decisions offered on a card, in the order a company works through
  /// them. `submitted` is absent on purpose — it is where every application
  /// starts, and moving one back to it says nothing.
  static const List<ApplicationStatus> _actions = [
    ApplicationStatus.inReview,
    ApplicationStatus.shortlisted,
    ApplicationStatus.interview,
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  ];

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    ApplicationStatus status,
  ) async {
    final result = await ref
        .read(jobApplicantsProvider(jobId).notifier)
        .setStatus(application.id, status);
    if (!context.mounted) return;
    result.when(
      success: (_) => showRungToast(context, context.l10n.companyStatusSaved),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final status = application.status;
    final statusColor = switch (status) {
      ApplicationStatus.accepted => c.green,
      ApplicationStatus.rejected => c.red,
      _ => c.accent,
    };

    return RungCard(
      margin: const EdgeInsets.symmetric(horizontal: RungSpace.sm),
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RungAvatar(
                seed: application.applicantId,
                initials: _monogram(application.applicantName),
                size: 42,
                imageUrl: ref.watch(imageUrlResolverProvider)(
                  application.applicantAvatarUrl,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicantName.isEmpty
                          ? l10n.companyApplicantUnknown
                          : application.applicantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.companyAppliedAgo(
                        relativeTimeArabic(application.submittedAt),
                      ),
                      style: TextStyle(fontSize: 12, color: c.ink2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: RungRadius.pill,
                  color: statusColor.withValues(alpha: 0.12),
                ),
                child: Text(
                  status.label(context),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (application.coverLetter.isNotEmpty) ...[
            const SizedBox(height: RungSpace.sm),
            Text(
              application.coverLetter,
              // Long enough to judge by, short enough that a card stays a card.
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink2),
            ),
          ],

          if (application.resumeUrl.isNotEmpty) ...[
            const SizedBox(height: RungSpace.sm),
            Row(
              children: [
                Icon(Icons.attach_file, size: 15, color: c.ink3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    // Shown, not opened: the value is a stored location the
                    // app has no viewer for yet, and a tap that goes nowhere
                    // is worse than a line of text that explains itself.
                    application.resumeUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.ink2),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: RungSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in _actions)
                if (action != status)
                  OutlinedButton(
                    onPressed: () => _setStatus(context, ref, action),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(
                        color: action == ApplicationStatus.rejected
                            ? c.red
                            : c.line2,
                      ),
                      foregroundColor: switch (action) {
                        ApplicationStatus.rejected => c.red,
                        ApplicationStatus.accepted => c.green,
                        _ => c.ink2,
                      },
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(action.label(context)),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  /// Two letters from the applicant's name, mirroring `Person.initials` — the
  /// application carries a name but no `Person`, so there is nothing to borrow.
  static String _monogram(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) {
      final first = parts.first;
      return first.length <= 2 ? first : first.substring(0, 2);
    }
    return '${parts.first[0]}${parts.last[0]}';
  }
}
