import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/activity/presentation/notifiers/activity_notifier.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import 'package:flutter_mobile_template/features/subscription/domain/entities/subscription_entities.dart';
import 'package:flutter_mobile_template/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:flutter_mobile_template/features/subscription/presentation/widgets/subscription_gate.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../notifiers/dashboard_notifier.dart';

/// The engineer panel — learning progress, services, and personal tools.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final summary = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DashboardHeader(),
            // The header stays outside the gate: it is the tab's identity, and
            // a paywall that replaced the whole screen would leave someone
            // unsure they were still where they thought they were.
            Expanded(
              child: SubscriptionGate(
                child: Column(
                  children: [
                    const _SubscriptionStrip(),
                    Expanded(
                      child: summary.when(
                        loading: () => const LoadingView(),
                        error: (e, _) => ErrorView(
                          error: e,
                          onRetry: () => ref
                              .read(dashboardNotifierProvider.notifier)
                              .refresh(),
                        ),
                        data: (data) => RefreshIndicator(
                          onRefresh: () async {
                            // The gate too, not just the numbers: a pull is how
                            // somebody whose subscription was just approved
                            // finds out, and nothing pushes at the client.
                            ref.read(subscriptionProvider.notifier).refresh();
                            await ref
                                .read(dashboardNotifierProvider.notifier)
                                .refresh();
                          },
                          child: _Body(summary: data),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line at the top of the panel saying what is keeping it open, and how long
/// for. Only when this tenant charges: with the feature off there is no
/// subscription to manage and nothing true to say about one.
class _SubscriptionStrip extends ConsumerWidget {
  const _SubscriptionStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(subscriptionProvider).valueOrNull;

    if (state == null || !state.isVisible) return const SizedBox.shrink();

    final trial = state.source == AccessSource.trial;
    final current = state.current;

    final String text;
    if (trial) {
      text = l10n.subscriptionTrialEndsIn(
        ArabicNumbers.plain(state.trialDaysRemaining),
      );
    } else if (current != null && current.isLive) {
      text = current.daysRemaining <= 0
          ? l10n.subscriptionEndsToday
          : l10n.subscriptionExpiresIn(
              ArabicNumbers.plain(current.daysRemaining),
            );
    } else {
      text = l10n.subscriptionManage;
    }

    final tint = trial ? c.amber : c.accent;

    // Ink rather than a Container: an opaque box painted inside an InkWell
    // covers the splash, so the row would take taps and show nothing.
    return Material(
      color: trial ? c.amberSoft : c.accentSoft,
      child: InkWell(
        onTap: () => context.push('/subscription'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RungSpace.gutter,
            vertical: 9,
          ),
          child: Row(
            children: [
              Icon(
                trial ? Icons.schedule : Icons.workspace_premium_outlined,
                size: 16,
                color: tint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tint,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final me = ref.watch(currentPersonProvider).valueOrNull;
    final unread = ref.watch(unreadActivityCountProvider);

    return Container(
      padding: const EdgeInsets.all(RungSpace.gutter),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/me'),
            child: RungAvatar(
              seed: me?.id ?? 'me',
              initials: me?.initials ?? '—',
              imageUrl: ref.watch(imageUrlResolverProvider)(me?.avatarUrl),
              size: 44,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dashboardGreeting,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.ink3,
                  ),
                ),
                Text(
                  me?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          RungIconButton(
            icon: Icons.notifications_none_rounded,
            size: 40,
            radius: 12,
            onPressed: () => context.push('/notifications'),
            tooltip: context.l10n.notificationsTitle,
            badge: unread > 0 ? RungCountBadge(count: unread) : null,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.only(bottom: RungSpace.lg),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RungSpace.gutter,
            RungSpace.gutter,
            RungSpace.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardContinueLearning,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: c.ink3,
                ),
              ),
              const SizedBox(height: 10),
              _ContinueCard(
                progress: summary.progress,
                // Straight to the theory catalogue: the summary names the
                // course but carries no id, so the section it lives in is the
                // closest honest destination.
                onTap: () => context.push('/panel/courses/theory'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RungSpace.gutter,
            RungSpace.gutter,
            RungSpace.gutter,
            0,
          ),
          child: Row(
            children: [
              _Stat(value: summary.activeCourses, label: l10n.dashboardStatCourses),
              const SizedBox(width: 10),
              _Stat(value: summary.learningHours, label: l10n.dashboardStatHours),
              const SizedBox(width: 10),
              _Stat(
                value: summary.certificates,
                label: l10n.dashboardStatCertificates,
              ),
            ],
          ),
        ),
        RungSectionLabel(l10n.dashboardSectionLearning),
        RungGroupedCard(
          children: [
            RungNavRow(
              icon: Icons.menu_book_outlined,
              iconColor: c.accent,
              iconBackground: c.accentSoft,
              title: l10n.dashboardTheory,
              subtitle: l10n.dashboardTheorySubtitle,
              badge: _NewBadge(count: summary.newTheoryCount),
              onTap: () => context.push('/panel/courses/theory'),
            ),
            RungNavRow(
              icon: Icons.handyman_outlined,
              iconColor: c.green,
              iconBackground: c.greenSoft,
              title: l10n.dashboardPractical,
              subtitle: l10n.dashboardPracticalSubtitle,
              badge: _NewBadge(count: summary.newPracticalCount),
              onTap: () => context.push('/panel/courses/practical'),
            ),
            RungNavRow(
              icon: Icons.school_outlined,
              iconColor: c.accent,
              iconBackground: c.accentSoft,
              title: l10n.dashboardTraining,
              subtitle: l10n.dashboardTrainingSubtitle,
              badge: _NewBadge(count: summary.newTrainingCount),
              onTap: () => context.push('/panel/courses/training'),
            ),
          ],
        ),
        RungSectionLabel(l10n.dashboardSectionServices),
        RungGroupedCard(
          children: [
            RungNavRow(
              icon: Icons.smart_toy_outlined,
              iconColor: c.accent,
              iconBackground: c.accentSoft,
              title: l10n.dashboardEngy,
              subtitle: l10n.dashboardEngySubtitle,
              titleSuffix: _AiTag(label: l10n.dashboardEngyBadge),
              onTap: () => context.push('/panel/assistant'),
            ),
            RungNavRow(
              icon: Icons.support_agent_outlined,
              iconColor: c.green,
              iconBackground: c.greenSoft,
              title: l10n.dashboardLegalRequest,
              subtitle: l10n.dashboardLegalRequestSubtitle,
              onTap: () => context.push('/panel/legal-requests'),
            ),
            RungNavRow(
              icon: Icons.gavel_outlined,
              iconColor: c.amber,
              iconBackground: c.amberSoft,
              title: l10n.dashboardLegalAffairs,
              subtitle: l10n.dashboardLegalAffairsSubtitle,
              onTap: () => context.push('/panel/documents/legal-affairs'),
            ),
          ],
        ),
        RungSectionLabel(l10n.dashboardSectionTools),
        RungGroupedCard(
          children: [
            RungNavRow(
              icon: Icons.description_outlined,
              iconColor: c.amber,
              iconBackground: c.amberSoft,
              title: l10n.dashboardNotes,
              subtitle: l10n.dashboardNotesSubtitle,
              onTap: () => context.push('/panel/notes'),
            ),
            RungNavRow(
              icon: Icons.local_library_outlined,
              iconColor: c.ink3,
              iconBackground: c.surface3,
              title: l10n.dashboardLibrary,
              subtitle: l10n.dashboardLibrarySubtitle,
              enabled: summary.libraryAvailable,
              badge: summary.libraryAvailable
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface3,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.comingSoon,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: c.ink3,
                        ),
                      ),
                    ),
              onTap: () => context.push('/panel/documents/library'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress, required this.onTap});

  final LearningProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungCard(
      onTap: onTap,
      radius: RungRadius.md + 2,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.menu_book_outlined, size: 26, color: c.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.dashboardLectureProgress(
                        ArabicNumbers.plain(progress.currentLecture),
                        ArabicNumbers.plain(progress.totalLectures),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 6,
                    backgroundColor: c.surface3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ArabicNumbers.percent(progress.fraction),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: RungRadius.mdAll,
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Text(
              ArabicNumbers.plain(value),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        context.l10n.dashboardNewBadge(ArabicNumbers.plain(count)),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: c.accent,
        ),
      ),
    );
  }
}

class _AiTag extends StatelessWidget {
  const _AiTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: c.accent,
        ),
      ),
    );
  }
}
