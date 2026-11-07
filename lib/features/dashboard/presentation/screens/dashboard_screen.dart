import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/activity/presentation/notifiers/activity_notifier.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import 'package:mohandis/features/subscription/domain/entities/subscription_entities.dart';
import 'package:mohandis/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

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
            // NO whole-screen paywall. The panel is open to everyone: the
            // sections that need a subscription carry their own padlock and
            // send a tap to `/subscription`, which is a far better answer than
            // a wall where a screen should be — somebody who cannot see what
            // is behind a door has no reason to pay for the key.
            Expanded(
              child: Column(
                children: [
                  const _SubscriptionStrip(),
                  Expanded(
                    child: summary.when(
                      loading: () => const TileGridSkeleton(),
                      error: (e, _) => ErrorView(
                        error: e,
                        onRetry: () => ref
                            .read(dashboardNotifierProvider.notifier)
                            .refresh(),
                      ),
                      data: (data) => RefreshIndicator(
                        onRefresh: () async {
                          // The subscription too, not just the numbers: a pull
                          // is how somebody whose subscription was just
                          // approved finds out, and nothing pushes at the
                          // client.
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
    } else if (state.hasAccess) {
      text = l10n.subscriptionManage;
    } else {
      // Nothing running. The strip is the one line on an open panel that says
      // why half of it is padlocked, so it asks rather than offering to
      // "manage" a subscription this person does not have.
      text = l10n.subscriptionLockedBody;
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
              icon: me?.accountType.icon,
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

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final subscription = ref.watch(subscriptionProvider).valueOrNull;

    // Whether to offer the teaching row at all. Defaults to NOT offering it
    // while the profile is still loading: a row that appears a second late is
    // a smaller mistake than one that appears and then fails on save.
    final canTeach =
        ref.watch(currentPersonProvider).valueOrNull?.canPublishCourses ?? false;

    /// A row for a section this viewer may not open: padlock instead of the
    /// badge, and a tap goes to the paywall rather than to a screen that would
    /// answer 402. Fails OPEN when the subscription state is unknown — the
    /// server checks every route anyway, and locking a subscriber out because
    /// one request failed is the worse mistake.
    Widget section({
      required IconData icon,
      required Color iconColor,
      required Color iconBackground,
      required String title,
      required String subtitle,
      required PlanFeature feature,
      required String route,
      Widget? badge,
      bool enabled = true,
    }) {
      // A section that is not live yet ("coming soon") is not a section to
      // sell: unavailability wins, so the row keeps its own badge and stays
      // inert rather than inviting somebody to pay for an empty shelf.
      final locked =
          enabled && subscription != null && !subscription.allows(feature);
      return RungNavRow(
        icon: locked ? Icons.lock_outline_rounded : icon,
        iconColor: locked ? c.ink3 : iconColor,
        iconBackground: locked ? c.surface3 : iconBackground,
        title: title,
        subtitle: locked ? l10n.dashboardSectionLocked : subtitle,
        badge: locked ? null : badge,
        enabled: enabled,
        onTap: () => context.push(locked ? '/subscription' : route),
      );
    }

    /// A row for a TOOL rather than a shelf — the assistant, the notes.
    ///
    /// Gated on holding a subscription at all, not on a [PlanFeature]: the
    /// plans sell named sections and these are not among them. Without this
    /// they were the two rows in the panel that a non-subscriber could open,
    /// which made the lock on everything around them look arbitrary.
    Widget tool({
      required IconData icon,
      required Color iconColor,
      required Color iconBackground,
      required String title,
      required String subtitle,
      required String route,
      Widget? titleSuffix,
    }) {
      // Fails OPEN while the subscription state is unknown, exactly like
      // `section` — the server checks every route anyway, and shutting a
      // subscriber out because one request failed is the worse mistake.
      final locked = subscription != null && !subscription.opensPanelTools;
      return RungNavRow(
        icon: locked ? Icons.lock_outline_rounded : icon,
        iconColor: locked ? c.ink3 : iconColor,
        iconBackground: locked ? c.surface3 : iconBackground,
        title: title,
        subtitle: locked ? l10n.dashboardSectionLocked : subtitle,
        titleSuffix: locked ? null : titleSuffix,
        onTap: () => context.push(locked ? '/subscription' : route),
      );
    }

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
            // The three catalogues are the ONE thing a non-subscriber may
            // walk into. Not generosity: every course inside carries its own
            // padlock, and a locked list somebody can browse is what gives
            // them a reason to subscribe. A locked ROW shows them nothing to
            // want.
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

            // The teaching side of the catalogue. A plain row, NOT `section`:
            // the three above are things a plan buys, and writing a course is
            // not one of them — gating the author's own shelf behind the
            // subscription would be charging somebody for the right to sell.
            //
            // Hidden from the kinds the server refuses a course from: a
            // مقاول, حرفي or صاحب آلية tapping this would reach an empty list
            // and a save that fails, which is worse than not offering it.
            if (canTeach)
              RungNavRow(
                icon: Icons.cast_for_education_outlined,
                iconColor: c.green,
                iconBackground: c.greenSoft,
                title: l10n.dashboardTeach,
                subtitle: l10n.dashboardTeachSubtitle,
                onTap: () => context.push('/panel/courses/mine'),
              ),
          ],
        ),
        RungSectionLabel(l10n.dashboardSectionServices),
        RungGroupedCard(
          children: [
            // المهندسة إنجي is hidden until the assistant answers: the
            // service stores questions but has no model behind it yet, and an
            // "AI assistant" that replies "not activated" is a placeholder
            // feature (App Store guideline 2.1). The route stays for when it
            // is wired up.
            section(
              icon: Icons.support_agent_outlined,
              iconColor: c.green,
              iconBackground: c.greenSoft,
              title: l10n.dashboardLegalRequest,
              subtitle: l10n.dashboardLegalRequestSubtitle,
              feature: PlanFeature.legalAffairs,
              route: '/panel/legal-requests',
            ),
            section(
              icon: Icons.gavel_outlined,
              iconColor: c.amber,
              iconBackground: c.amberSoft,
              title: l10n.dashboardLegalAffairs,
              subtitle: l10n.dashboardLegalAffairsSubtitle,
              feature: PlanFeature.legalAffairs,
              route: '/panel/documents/legal-affairs',
            ),
          ],
        ),
        RungSectionLabel(l10n.dashboardSectionTools),
        RungGroupedCard(
          children: [
            tool(
              icon: Icons.description_outlined,
              iconColor: c.amber,
              iconBackground: c.amberSoft,
              title: l10n.dashboardNotes,
              subtitle: l10n.dashboardNotesSubtitle,
              route: '/panel/notes',
            ),
            // Only when the library has documents. It used to stay on the
            // list greyed out with a "coming soon" badge, which is a
            // placeholder feature (App Store guideline 2.1).
            if (summary.libraryAvailable)
              section(
                icon: Icons.local_library_outlined,
                iconColor: c.ink3,
                iconBackground: c.surface3,
                title: l10n.dashboardLibrary,
                subtitle: l10n.dashboardLibrarySubtitle,
                feature: PlanFeature.library,
                route: '/panel/documents/library',
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
