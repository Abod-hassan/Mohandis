import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/l10n/l10n.dart';

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
        loading: () => const PeopleListSkeleton(count: 6),
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
                onRefresh: () => pullRefresh(
                  ref.refresh(jobApplicantsProvider(jobId).future),
                ),
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

  /// Opens the attached résumé in whatever the phone uses for a PDF.
  ///
  /// The file sits on the CDN and is stored host-less, like every other upload,
  /// so the path goes through the resolver before anything tries to open it.
  Future<void> _openResume(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final url = ref.read(imageUrlResolverProvider)(application.resumeUrl);
    // The button only exists when there IS a résumé, so a null here means the
    // CDN base was not resolved — the file's problem, not the applicant's.
    // Saying "no CV attached" would blame the wrong party.
    if (url == null) {
      showRungToast(context, l10n.companyApplicantCvFailed, success: false);
      return;
    }

    // B2: `launchUrl` returns false for some failures and THROWS for others —
    // no activity for the intent, a malformed path out of the resolver — and an
    // unhandled one leaves the company with no CV and no explanation.
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showRungToast(context, l10n.companyApplicantCvFailed, success: false);
    }
  }

  /// The applicant in full: their whole note, the CV, and the way to their
  /// profile. The card keeps a four-line preview so a list of twenty stays a
  /// list; anything longer belongs here, where it can scroll.
  Future<void> _showDetails(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final c = sheetContext.rung;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          // A floor and a handle, as the pickers have: a DraggableScrollableSheet
          // eats the modal route's drag-to-dismiss, so without them a downward
          // swipe shrinks the sheet to a sliver that cannot be closed by
          // swiping again.
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(RungSpace.gutter),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: RungSpace.sm),
                  decoration: BoxDecoration(
                    color: c.line2,
                    borderRadius: RungRadius.pill,
                  ),
                ),
              ),
              Text(
                application.applicantName.isEmpty
                    ? l10n.companyApplicantUnknown
                    : application.applicantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (application.applicantHeadline.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  application.applicantHeadline,
                  style: TextStyle(fontSize: 13, color: c.ink2),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                l10n.companyAppliedAgo(
                  relativeTimeArabic(application.submittedAt),
                ),
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),
              const SizedBox(height: RungSpace.md),
              Text(
                l10n.companyApplicantNotes,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.ink3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                application.coverLetter.isEmpty
                    ? l10n.companyApplicantNoNotes
                    : application.coverLetter,
                style: TextStyle(fontSize: 14, height: 1.6, color: c.ink),
              ),
              const SizedBox(height: RungSpace.md),
              if (application.resumeUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openResume(context, ref);
                  },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text(l10n.companyApplicantOpenCv),
                ),
              if (application.applicantId.isNotEmpty) ...[
                const SizedBox(height: RungSpace.xs),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/profile/${application.applicantId}');
                  },
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: Text(l10n.companyApplicantProfile),
                ),
              ],
            ],
          ),
        );
      },
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
              // The whole identity opens the profile: a CV says what somebody
              // has done, the profile says who they are, and a company deciding
              // between applicants wants both.
              GestureDetector(
                onTap: application.applicantId.isEmpty
                    ? null
                    : () => context.push('/profile/${application.applicantId}'),
                child: RungAvatar(
                  seed: application.applicantId,
                  initials: _monogram(application.applicantName),
                  size: 42,
                  imageUrl: ref.watch(imageUrlResolverProvider)(
                    application.applicantAvatarUrl,
                  ),
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
                    if (application.applicantHeadline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        application.applicantHeadline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.ink2),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      l10n.companyAppliedAgo(
                        relativeTimeArabic(application.submittedAt),
                      ),
                      style: TextStyle(fontSize: 12, color: c.ink3),
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

          const SizedBox(height: RungSpace.sm),
          Text(
            l10n.companyApplicantNotes,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.ink3,
            ),
          ),
          const SizedBox(height: 3),
          // Said either way. An empty space where the applicant's own words
          // should be reads as a card that failed to load, not as somebody who
          // wrote nothing.
          Text(
            application.coverLetter.isEmpty
                ? l10n.companyApplicantNoNotes
                : application.coverLetter,
            // Long enough to judge by, short enough that a card stays a card —
            // the sheet below carries the rest.
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: application.coverLetter.isEmpty ? c.ink3 : c.ink2,
              fontStyle: application.coverLetter.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          if (application.coverLetter.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => _showDetails(context, ref),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.companyApplicantDetails),
              ),
            ),

          const SizedBox(height: RungSpace.sm),
          // The CV opens now. It used to be printed as its storage path — a
          // line of text nobody could do anything with, which is the one thing
          // an applicant list exists to let a company read.
          if (application.resumeUrl.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _openResume(context, ref),
                icon: const Icon(Icons.attach_file, size: 16),
                label: Text(l10n.companyApplicantOpenCv),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: c.line2),
                  foregroundColor: c.ink,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.attach_file, size: 15, color: c.ink3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    l10n.companyApplicantNoCv,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ),
              ],
            ),

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
