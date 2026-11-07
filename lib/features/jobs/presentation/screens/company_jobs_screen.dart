import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import '../notifiers/company_jobs_notifier.dart';
import '../widgets/job_card.dart';

/// A company's own postings — the "Jobs" tab for a company account.
///
/// Deliberately not the same screen as the individual's jobs tab. That one is
/// a browse surface with search and workplace chips; this one is a management
/// surface, so it carries no filters, shows closed postings alongside open
/// ones, and leads with the button that creates another.
class CompanyJobsScreen extends ConsumerWidget {
  const CompanyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final jobs = ref.watch(companyJobsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(showBack: false, title: l10n.companyJobsTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/company/jobs/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.companyPostJob),
      ),
      body: jobs.when(
        loading: () => const CardListSkeleton(height: 120, lines: 3),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(companyJobsProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.companyJobsEmpty,
                message: l10n.companyJobsEmptyHint,
                icon: Icons.work_outline_rounded,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    pullRefresh(ref.refresh(companyJobsProvider.future)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _PostingRow(job: list[i]),
                ),
              ),
      ),
    );
  }
}

/// A posting plus the two things its owner came to see: whether it is still
/// open, and how many people applied.
class _PostingRow extends StatelessWidget {
  const _PostingRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobCard(job: job, onTap: () => context.push('/jobs/${job.id}')),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RungSpace.gutter,
            0,
            RungSpace.gutter,
            12,
          ),
          child: Row(
            children: [
              _StatePill(open: job.isOpen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.companyApplicantCount(
                    ArabicNumbers.count(job.applicantCount),
                  ),
                  style: TextStyle(fontSize: 12.5, color: c.ink2),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/company/applicants/${job.id}'),
                child: Text(l10n.companyViewApplicants),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: c.line),
      ],
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final color = open ? c.green : c.ink3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: RungRadius.pill,
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        open ? context.l10n.companyJobOpen : context.l10n.companyJobClosed,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
