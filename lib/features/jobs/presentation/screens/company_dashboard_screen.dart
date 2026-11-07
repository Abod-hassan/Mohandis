import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../../domain/entities/job.dart';
import '../notifiers/company_dashboard_notifier.dart';
import '../notifiers/company_jobs_notifier.dart';
import '../widgets/job_labels.dart';

/// The company's opening screen.
///
/// A company follows nobody and is followed rather than following, so the feed
/// that used to sit on this tab was a permanently empty page. What a company
/// actually opens the app for is upstairs: how many postings are live, who has
/// applied, and which of them is still waiting on an answer.
class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  /// Grey between the white blocks. `RungSpace.sectionGap` is 8, which is the
  /// right amount inside a list of related rows and too little between the
  /// parts of a dashboard.
  static const double _sectionGap = RungSpace.md;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final dashboard = ref.watch(companyDashboardProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(
        title: l10n.companyDashboardTitle,
        showBack: false,
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      body: dashboard.when(
        loading: () => const CardListSkeleton(count: 4),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(companyDashboardProvider),
        ),
        data: (data) => RefreshIndicator(
          // The postings are the source both this screen and the jobs tab read,
          // so the pull refreshes that rather than only the numbers here.
          onRefresh: () async {
            ref.invalidate(companyJobsProvider);
            await pullRefresh(ref.refresh(companyDashboardProvider.future));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: RungSpace.lg),
            children: [
              const _Greeting(),
              _Stats(data: data),
              // A dashboard is read block by block, so the blocks are given
              // more air than the app's default 8px section gap — at that
              // spacing the white bands read as one long sheet with hairlines
              // through it rather than as four separate things.
              const SizedBox(height: _sectionGap),
              _PendingSection(data: data),
              _OpenJobsSection(data: data),
              const _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's own identity, read straight from the profile.
///
/// Its own watch rather than a field on [CompanyDashboard]: a company editing
/// its page should see the new name here without the dashboard re-reading
/// every posting's applicants to find out.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final profile = ref.watch(profileNotifierProvider('me')).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    // On the surface, with the app bar's own bottom rule: the greeting is part
    // of the header, and floating it on the grey page left it looking like a
    // card that had lost its background.
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        0,
        RungSpace.gutter,
        RungSpace.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/company/profile'),
            child: RungAvatar(
              seed: profile.personId,
              initials: profile.person.initials,
              icon: profile.person.accountType.icon,
              size: 44,
              imageUrl: ref.watch(imageUrlResolverProvider)(profile.avatarUrl),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.companyDashboardGreeting(profile.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (profile.headline.isNotEmpty)
                  Text(
                    profile.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.ink2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four numbers, two by two. Deliberately not a chart: a company with three
/// postings has nothing to plot, and the counts are what the next tap is
/// decided from.
class _Stats extends ConsumerWidget {
  const _Stats({required this.data});

  final CompanyDashboard data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.rung;
    final followers =
        ref.watch(profileNotifierProvider('me')).valueOrNull?.followerCount ?? 0;

    final tiles = [
      (l10n.companyStatOpenJobs, data.openJobCount, Icons.work_outline_rounded,
          c.accent),
      (
        l10n.companyStatApplicants,
        data.applicantCount,
        Icons.people_outline,
        c.ink,
      ),
      (
        l10n.companyStatNewThisWeek,
        data.newThisWeek,
        // NOT a trend arrow: `trending_up` mirrors under RTL and reads as a
        // decline, which is the opposite of what the number means.
        Icons.schedule_rounded,
        c.green,
      ),
      (
        l10n.companyStatFollowers,
        followers,
        Icons.favorite_border_rounded,
        c.ink2,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        CompanyDashboardScreen._sectionGap,
        RungSpace.gutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two columns of two. `tiles.length - 1` rather than `tiles.length`:
          // a fifth tile added later would otherwise index past the end.
          for (var i = 0; i < tiles.length - 1; i += 2)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i == 0 ? 10 : 0),
                child: Column(
                  children: [
                    _StatTile(
                      label: tiles[i].$1,
                      value: tiles[i].$2,
                      icon: tiles[i].$3,
                      color: tiles[i].$4,
                    ),
                    const SizedBox(height: 10),
                    _StatTile(
                      label: tiles[i + 1].$1,
                      value: tiles[i + 1].$2,
                      icon: tiles[i + 1].$3,
                      color: tiles[i + 1].$4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return RungCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ArabicNumbers.count(value),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Applications nobody has answered. The one part of this screen that is a
/// queue rather than a report.
class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.data});

  final CompanyDashboard data;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungSection(
      gapBelow: CompanyDashboardScreen._sectionGap,
      title: l10n.companyPendingTitle,
      trailing: TextButton(
        onPressed: () => context.go('/company/applicants'),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        child: Text(l10n.companyPendingAll),
      ),
      child: data.pending.isEmpty
          ? Text(
              l10n.companyPendingEmpty,
              style: TextStyle(fontSize: 13, color: c.ink3),
            )
          : Column(
              children: [
                for (final row in data.pending) _PendingRow(row: row),
              ],
            ),
    );
  }
}

class _PendingRow extends ConsumerWidget {
  const _PendingRow({required this.row});

  final PendingApplication row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final application = row.application;

    return InkWell(
      // Into the posting's applicant list, not a screen of its own: the
      // decision buttons live there, and a second place to make the same
      // decision is a second place for it to be half-made.
      onTap: () => context.push('/company/applicants/${row.job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            RungAvatar(
              seed: application.applicantId,
              initials: _monogram(application.applicantName),
              size: 38,
              imageUrl: ref.watch(imageUrlResolverProvider)(
                application.applicantAvatarUrl,
              ),
            ),
            const SizedBox(width: 10),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${row.job.title} · '
                    '${relativeTimeArabic(application.submittedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: RungRadius.pill,
                color: c.accent.withValues(alpha: 0.12),
              ),
              child: Text(
                application.status.label(context),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same rule the applicant list uses — two letters, or one when that is all
  /// there is.
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

class _OpenJobsSection extends StatelessWidget {
  const _OpenJobsSection({required this.data});

  final CompanyDashboard data;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungSection(
      gapBelow: CompanyDashboardScreen._sectionGap,
      title: l10n.companyOpenJobsTitle,
      trailing: TextButton.icon(
        onPressed: () => context.push('/company/jobs/new'),
        icon: const Icon(Icons.add, size: 16),
        label: Text(l10n.companyPostJob),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.openJobs.isEmpty)
            Text(
              l10n.companyOpenJobsEmpty,
              style: TextStyle(fontSize: 13, color: c.ink3),
            )
          else
            for (final job in data.openJobs) _JobRow(job: job),
          if (data.closedJobCount > 0) ...[
            const SizedBox(height: RungSpace.xs),
            Text(
              l10n.companyClosedJobs(ArabicNumbers.count(data.closedJobCount)),
              style: TextStyle(fontSize: 12, color: c.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

/// The four things a company opens this app to do, as tiles.
///
/// They sit at the end rather than the top: somebody with applications waiting
/// should see the queue first. On a brand-new page with no postings and no
/// applicants, this is also what stops the screen from being two empty
/// sentences and a lot of grey.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final actions = <(String, IconData, VoidCallback)>[
      (
        l10n.companyPostJob,
        Icons.add_box_outlined,
        () => context.push('/company/jobs/new'),
      ),
      (
        l10n.companyPendingAll,
        Icons.assignment_ind_outlined,
        () => context.go('/company/applicants'),
      ),
      (
        l10n.composerTitle,
        Icons.edit_note_rounded,
        () => context.push('/feed/composer'),
      ),
      (
        l10n.companyEditPage,
        Icons.business_outlined,
        () => context.push('/profile/me/edit'),
      ),
    ];

    return RungSection(
      gapBelow: 0,
      title: l10n.companyQuickActions,
      child: Column(
        children: [
          for (var i = 0; i < actions.length - 1; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < actions.length ? 10 : 0),
              child: Row(
                children: [
                  Expanded(child: _ActionTile(action: actions[i])),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionTile(action: actions[i + 1])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final (String, IconData, VoidCallback) action;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return RungCard(
      onTap: action.$3,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(action.$2, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

    return InkWell(
      onTap: () => context.push('/company/applicants/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            RungLogoTile(seed: job.id, monogram: job.monogram, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.companyJobApplicants(ArabicNumbers.count(job.applicantCount)),
                    style: TextStyle(fontSize: 11.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            // `chevron_right`, which mirrors under RTL to point at the start
            // edge — `chevron_left` mirrors the other way and reads as "back",
            // which is what the app bar uses it for.
            Icon(Icons.chevron_right, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
