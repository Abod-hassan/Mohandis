import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/domain/repositories/profile_repository.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../notifiers/jobs_notifier.dart';
import '../notifiers/saved_jobs_notifier.dart';
import '../widgets/job_labels.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final job = ref.watch(jobDetailProvider(jobId));
    final application = ref.watch(applicationsByJobProvider)[jobId];

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: l10n.jobDetailTitle,
        // No bookmark here. It sat outside `job.when`, so it could neither
        // show the saved state nor act on a job it had no reference to — and
        // it only ever raised a toast claiming a save nothing recorded. The
        // footer's bookmark is the real one, and two of them on one screen was
        // one too many even when both worked.
      ),
      body: job.when(
        loading: () => const DetailSkeleton(hasHero: false, paragraphs: 4),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
        data: (data) => Column(
          children: [
            Expanded(child: _Body(job: data)),
            _Footer(job: data, application: application),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        18,
        RungSpace.gutter,
        RungSpace.lg,
      ),
      children: [
        Row(
          children: [
            RungLogoTile(
              seed: job.company,
              monogram: job.monogram,
              size: 58,
              radius: 14,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.company,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink2,
                    ),
                  ),
                  Text(
                    '${l10n.jobApplicants(ArabicNumbers.count(job.applicantCount))} · '
                    '${l10n.jobPostedAgo(relativeTimeArabic(job.postedAt))}',
                    style: TextStyle(fontSize: 12, color: c.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          job.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 14, color: c.ink2),
            const SizedBox(width: 5),
            Text(job.location, style: TextStyle(fontSize: 13, color: c.ink2)),
          ],
        ),
        const SizedBox(height: 14),
        // Both are nullable columns on the posting form — a chip is only
        // shown for what the poster actually stated.
        if (job.workMode != null || job.employmentType != null) ...[
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (job.workMode != null)
                RungTagChip(
                  label: job.workMode!.label(context),
                  emphasis: RungTagEmphasis.accent,
                ),
              if (job.employmentType != null)
                RungTagChip(label: job.employmentType!.label(context)),
            ],
          ),
          const SizedBox(height: RungSpace.md),
        ],
        // `SalaryMin` / `SalaryMax` / `Currency` are all optional, and most
        // postings fill in none of them — an empty label means the poster
        // published no figures, so the whole panel is dropped rather than
        // showing a "نطاق الراتب" header over nothing.
        if (job.salaryLabel.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: RungRadius.mdAll,
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.greenSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: c.green,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.jobSalaryRange,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                      Text(
                        job.salaryLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(l10n.jobAboutSection, style: _sectionStyle),
        const SizedBox(height: 8),
        Text(
          job.description,
          style: TextStyle(fontSize: 14, height: 1.6, color: c.ink2),
        ),
        if (job.requirements.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(l10n.jobRequirementsSection, style: _sectionStyle),
          const SizedBox(height: 10),
          for (final requirement in job.requirements)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 18, color: c.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      requirement,
                      style: TextStyle(fontSize: 14, height: 1.5, color: c.ink2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static const _sectionStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
}

/// Toggles the bookmark and re-reads the job.
///
/// `jobDetailProvider` is what the footer renders from, so invalidating it is
/// what flips the icon — patching a local copy would disagree with the saved
/// list the moment that screen opens.
Future<void> _toggleSaveJob(
  BuildContext context,
  WidgetRef ref,
  String jobId,
) async {
  final result = await ref.read(jobRepositoryProvider).toggleSave(jobId);
  if (!context.mounted) return;
  result.when(
    success: (job) {
      ref.invalidate(jobDetailProvider(jobId));
      ref.invalidate(savedJobsProvider);
      showRungToast(
        context,
        job.saved
            ? context.l10n.toastSavedToItems
            : context.l10n.jobSaveRemoved,
      );
    },
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.job, required this.application});

  final Job job;
  final JobApplication? application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final me = ref
        .watch(profileNotifierProvider(ProfileRepository.meSentinel))
        .valueOrNull;
    // Held in a local so the null check promotes — `application` is a field.
    //
    // Either source alone is incomplete: `job.applied` is the server's
    // `hasApplied`, correct on a cold start but stale for a job fetched before
    // this person applied, while the applications list is the reverse. So they
    // are OR-ed, and only the row itself can name the stage reached — the flag
    // on its own gets the neutral "تم التقديم".
    final mine = application;
    final applied = mine != null || job.applied;
    // Fails OPEN while the subscription state is unknown — offline, a failed
    // read — exactly as the panel's own gate does. The server checks every
    // application anyway, so the worst case is a round trip that comes back
    // refused; the alternative locks a paying subscriber out of a job because
    // one request failed.
    final canApply =
        ref.watch(subscriptionProvider).valueOrNull?.canApplyToJobs ?? true;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: RungSpace.sm,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 48,
              child: OutlinedButton(
                // Was a toast that claimed a save nothing recorded. The
                // bookmark is real now — `Jobs/Save` toggles a row and the
                // saved list reads it back.
                onPressed: () => _toggleSaveJob(context, ref, job.id),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: job.saved ? c.accent : c.line2,
                    width: 1.5,
                  ),
                  foregroundColor: job.saved ? c.accent : c.ink2,
                ),
                child: Icon(
                  job.saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // A company hires; it does not apply. The seeker tab is already
            // hidden for a company account, but a job still opens from search,
            // a deep link or a company profile's own list — and the service
            // refuses the application anyway, so offering the button would only
            // buy a round trip and a refusal in English.
            if (me?.isCompany == true)
              Expanded(
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: RungRadius.pill,
                    border: Border.all(color: c.line2),
                  ),
                  child: Text(
                    l10n.jobCompanyCannotApply,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                ),
              )
            else
            Expanded(
              child: applied
                  ? Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.greenSoft,
                        borderRadius: RungRadius.pill,
                      ),
                      child: Text(
                        mine == null
                            ? '✓ ${l10n.jobApplied}'
                            : '✓ ${l10n.jobApplicationStatus(mine.status.label(context))}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.green,
                        ),
                      ),
                    )
                  : !canApply
                      // Applying is a subscriber's action — `JobService.Apply`
                      // refuses it otherwise. The button stays live rather
                      // than going dead: it leads to the page that fixes the
                      // problem, which is more use than a disabled control
                      // nobody can explain.
                      ? FilledButton.icon(
                          onPressed: () => context.push('/subscription'),
                          icon: const Icon(Icons.lock_outline_rounded, size: 18),
                          label: Text(l10n.jobApplyLocked),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: c.surface2,
                            foregroundColor: c.ink,
                          ),
                        )
                      : FilledButton(
                          // The service rejects an application to a closed
                          // posting, and a closed posting still opens from an
                          // old link or a shared card — so the button goes
                          // dead here instead of round-tripping to an error
                          // toast.
                          onPressed: job.isOpen
                              ? () => context.push('/jobs/${job.id}/apply')
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(l10n.jobApplyNow),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
