import 'package:flutter/material.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import 'job_labels.dart';

/// Job summary card used by the jobs list and the search "وظائف" tab.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.applied = false,
  });

  final Job job;
  final VoidCallback onTap;

  /// Whether the locally held applications list has a row for this job. It is
  /// OR-ed with the job's own `applied` flag below, so a caller that has no
  /// applications list (the search screen) still gets the pill.
  final bool applied;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    // Two independent sources of the same truth, each blind where the other
    // sees: `job.applied` is the server's `hasApplied` and is right on a cold
    // start but stale for a row fetched before this person applied; [applied]
    // comes from the applications list, which is the only thing that knows
    // about an application submitted seconds ago.
    final hasApplied = applied || job.applied;

    return RungCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: RungSpace.sm, vertical: 8),
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RungLogoTile(seed: job.company, monogram: job.monogram),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      '${job.company} · ${job.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.ink2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.jobPostedAgo(relativeTimeArabic(job.postedAt))} · '
                      '${l10n.jobApplicants(ArabicNumbers.count(job.applicantCount))}',
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                  ],
                ),
              ),
              if (hasApplied) ...[
                const SizedBox(width: 8),
                RungStatusPill.success(
                  context,
                  label: l10n.jobApplied,
                  dense: true,
                ),
              ],
            ],
          ),
          // Every chip here is optional server-side — workplace mode and
          // employment type are nullable columns and most postings quote no
          // salary — so the whole row goes, gap included, when a posting
          // states none of the three.
          if (job.workMode != null ||
              job.employmentType != null ||
              job.salaryLabel.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (job.workMode != null)
                  RungTagChip(
                    label: job.workMode!.label(context),
                    emphasis: RungTagEmphasis.accent,
                  ),
                if (job.employmentType != null)
                  RungTagChip(label: job.employmentType!.label(context)),
                if (job.salaryLabel.isNotEmpty)
                  RungTagChip(label: job.salaryLabel),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
