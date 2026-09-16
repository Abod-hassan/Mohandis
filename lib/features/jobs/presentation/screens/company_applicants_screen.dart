import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import '../notifiers/company_jobs_notifier.dart';

/// Which posting's applicants to open — the "Applicants" tab for a company.
///
/// A picker rather than one combined list because the applicant endpoint is
/// per job: a merged view would cost one request per posting on every visit
/// and get slower the more a company posts. Here each row already carries the
/// count, so the company can see where the interest is before opening
/// anything.
class CompanyApplicantsScreen extends ConsumerWidget {
  const CompanyApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final jobs = ref.watch(companyJobsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(showBack: false, title: l10n.companyApplicantsTitle),
      body: jobs.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(companyJobsProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.companyJobsEmpty,
                message: l10n.companyJobsEmptyHint,
                icon: Icons.assignment_ind_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(companyJobsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: c.line),
                  itemBuilder: (_, i) => _JobRow(job: list[i]),
                ),
              ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final count = job.applicantCount;

    return InkWell(
      onTap: () => context.push('/company/applicants/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (count > 0 ? c.accent : c.ink3).withValues(alpha: 0.12),
              ),
              child: Text(
                ArabicNumbers.count(count),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: count > 0 ? c.accent : c.ink3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    // The posting date rather than the company name: on this
                    // screen every row is the same company.
                    l10n.jobPostedAgo(relativeTimeArabic(job.postedAt)),
                    style: TextStyle(fontSize: 12.5, color: c.ink2),
                  ),
                ],
              ),
            ),
            if (!job.isOpen)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  l10n.companyJobClosed,
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ),
            Icon(Icons.chevron_right, size: 20, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
