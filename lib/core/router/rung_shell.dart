import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/features/network/presentation/notifiers/network_notifier.dart';
import 'package:flutter_mobile_template/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../theme/rung_colors.dart';
import '../widgets/rung/rung.dart';

/// Branch indices, in the order they are declared on the router's
/// `StatefulShellRoute`.
///
/// A branch list is fixed when the route is built, so both tab sets live in it
/// and this file decides which of them a given account sees. Naming the
/// indices rather than writing the numbers inline is what keeps that decision
/// readable — and what makes inserting a branch a compile-time concern rather
/// than a silent renumbering that sends a tab to the wrong screen.
abstract final class _Branch {
  static const int feed = 0;
  static const int reels = 1;
  static const int dashboard = 2;
  static const int jobs = 3;
  static const int network = 4;
  static const int companyJobs = 5;
  static const int companyApplicants = 6;
  static const int companyProfile = 7;
}

/// Shell around the primary tabs. Each branch keeps its own navigation stack
/// and scroll position via `StatefulShellRoute.indexedStack`.
///
/// **The tab bar differs by account type.** An individual browses: feed,
/// reels, dashboard, job search, network. A company manages: feed, its own
/// postings, the people who applied to them, network, and its page. Reels and
/// the engineer dashboard are individual surfaces with nothing for a company
/// to do on them, and a company browsing job listings is looking at its
/// competitors' — so neither set is a subset of the other, and both are
/// declared here in full.
class RungShell extends ConsumerWidget {
  const RungShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final pendingRequests = ref.watch(pendingRequestCountProvider);
    final isCompany = ref.watch(isCompanyAccountProvider);

    final tabs = isCompany
        ? _companyTabs(l10n, pendingRequests)
        : _individualTabs(l10n, pendingRequests);

    // Reels is a full-bleed dark surface; the bar floats over it instead of
    // pushing the video up. Compared against the branch, not the visible
    // position, because the two only line up for an individual.
    final isReels = navigationShell.currentIndex == _Branch.reels;

    // -1 when the active branch is not one of this account's tabs — which
    // happens for a moment while the profile loads and the bar swaps, and for
    // a deep link into the other set. Nothing is highlighted rather than the
    // wrong thing, and every tab still works.
    final currentIndex = tabs.indexWhere(
      (tab) => tab.branch == navigationShell.currentIndex,
    );

    return Scaffold(
      backgroundColor: c.bg,
      extendBody: isReels,
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        translucent: isReels,
        onSelect: (index) {
          final branch = tabs[index].branch;
          navigationShell.goBranch(
            branch,
            // Tapping the active tab pops that branch back to its root.
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        items: tabs,
      ),
    );
  }

  List<_NavItem> _individualTabs(AppLocalizations l10n, int pendingRequests) => [
    _NavItem(
      branch: _Branch.feed,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: l10n.navHome,
    ),
    _NavItem(
      branch: _Branch.reels,
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library,
      label: l10n.navReels,
    ),
    _NavItem(
      branch: _Branch.dashboard,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: l10n.navDashboard,
    ),
    _NavItem(
      branch: _Branch.jobs,
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: l10n.navJobs,
    ),
    _NavItem(
      branch: _Branch.network,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: l10n.navNetwork,
      badgeCount: pendingRequests,
    ),
  ];

  List<_NavItem> _companyTabs(AppLocalizations l10n, int pendingRequests) => [
    _NavItem(
      branch: _Branch.feed,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: l10n.navHome,
    ),
    _NavItem(
      branch: _Branch.companyJobs,
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: l10n.navMyJobs,
    ),
    _NavItem(
      branch: _Branch.companyApplicants,
      icon: Icons.assignment_ind_outlined,
      activeIcon: Icons.assignment_ind,
      label: l10n.navApplicants,
    ),
    _NavItem(
      branch: _Branch.network,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: l10n.navNetwork,
      badgeCount: pendingRequests,
    ),
    _NavItem(
      branch: _Branch.companyProfile,
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      label: l10n.navPage,
    ),
  ];
}

class _NavItem {
  const _NavItem({
    required this.branch,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  /// Which `StatefulShellBranch` this tab activates. Carried on the item
  /// rather than inferred from its position, because a tab's position differs
  /// between the two bars while the branch it opens does not.
  final int branch;

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
    required this.translucent,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final background = translucent ? const Color(0xE60A0D13) : c.surface;
    final inactive = translucent ? Colors.white60 : c.ink3;
    final active = translucent ? Colors.white : c.accent;

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(color: translucent ? Colors.white24 : c.line),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    // -1 selects nothing — see the shell's `currentIndex`.
                    selected: i == currentIndex,
                    activeColor: active,
                    inactiveColor: inactive,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: color,
                ),
                if (item.badgeCount > 0)
                  PositionedDirectional(
                    top: -4,
                    start: -6,
                    child: RungCountBadge(count: item.badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
