import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../theme/rung_colors.dart';
import '../widgets/rung/rung.dart';
import 'package:mohandis/core/services/video_upload_queue.dart';
import 'package:mohandis/core/widgets/upload_banner.dart';
import 'shell_branch.dart';

/// Branch indices, in the order they are declared on the router's
/// `StatefulShellRoute`.
///
/// A branch list is fixed when the route is built, so both tab sets live in it
/// and this file decides which of them a given account sees. Naming the
/// indices rather than writing the numbers inline is what keeps that decision
/// readable — and what makes inserting a branch a compile-time concern rather
/// than a silent renumbering that sends a tab to the wrong screen.
/// Shell around the primary tabs. Each branch keeps its own navigation stack
/// and scroll position via `StatefulShellRoute.indexedStack`.
///
/// **The tab bar differs by account type.** An individual browses: feed,
/// reels, dashboard, job search, network. A company manages: its own
/// dashboard, its postings, the people who applied to them, and its page. Reels and the engineer dashboard are individual surfaces with nothing
/// for a company to do on them, a company browsing job listings is looking at
/// its competitors', and the feed is the one an account that follows nobody
/// would find empty — so neither set is a subset of the other, and both are
/// declared here in full.
class RungShell extends ConsumerWidget {
  const RungShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // Publish the visible branch for screens that must know when they are NOT
    // on screen — see `shellBranchProvider`. After the frame, because this runs
    // during build and moving provider state mid-build throws.
    final branch = navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(shellBranchProvider.notifier);
      if (notifier.state != branch) notifier.state = branch;
    });

    final isCompany = ref.watch(isCompanyAccountProvider);

    // The Network tab used to carry a pending connection-requests badge.
    // Connections were withdrawn from the app — following is the only
    // relationship it has — so there is nothing left to count there.
    final tabs = isCompany ? _companyTabs(l10n) : _individualTabs(l10n);

    // Reels is a full-bleed dark surface; the bar floats over it instead of
    // pushing the video up. Compared against the branch, not the visible
    // position, because the two only line up for an individual.
    final isReels = navigationShell.currentIndex == ShellBranch.reels;

    // -1 when the active branch is not one of this account's tabs — which
    // happens for a moment while the profile loads and the bar swaps, and for
    // a deep link into the other set. Nothing is highlighted rather than the
    // wrong thing, and every tab still works.
    final currentIndex = tabs.indexWhere(
      (tab) => tab.branch == navigationShell.currentIndex,
    );

    return PopScope(
      // A Dart isolate dies with the process, so backing out of the app with a
      // transfer running loses it. Nothing can be resumed without first copying
      // the video into app storage and adding a platform uploader, so the
      // honest protection is to ask.
      // Claimed jobs only. An unclaimed transfer belongs to a composer that is
      // still open above this shell, and that screen drops it on the way out.
      canPop: !ref.watch(
        videoUploadQueueProvider.select(
          (j) => (j?.isActive ?? false) && (j?.claimed ?? false),
        ),
      ),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: c.bg,
      extendBody: isReels,
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        translucent: isReels,
        onSelect: (index) {
          final branch = tabs[index].branch;
          final isRetap = branch == navigationShell.currentIndex;

          navigationShell.goBranch(
            branch,
            // Tapping the active tab pops that branch back to its root.
            initialLocation: isRetap,
          );

          // ...and tells that branch's screen, which popping cannot do. A
          // branch already at its root does not move, so without this the
          // commonest tap in the app — Home while on Home — does nothing at
          // all.
          if (isRetap) {
            ref.read(shellRetapProvider(branch).notifier).state++;
          }
        },
        items: tabs,
        // Above the bar, below everything else: the upload outlives the screen
        // it started on, so its report has to live where every tab can see it.
        banner: const UploadBanner(),
      ),
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.uploadLeaveTitle),
        content: Text(l10n.uploadLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.uploadLeaveStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.uploadLeaveQuit),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  List<_NavItem> _individualTabs(AppLocalizations l10n) => [
    _NavItem(
      branch: ShellBranch.feed,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: l10n.navHome,
    ),
    _NavItem(
      branch: ShellBranch.reels,
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library,
      label: l10n.navReels,
    ),
    _NavItem(
      branch: ShellBranch.dashboard,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: l10n.navDashboard,
    ),
    _NavItem(
      branch: ShellBranch.jobs,
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: l10n.navJobs,
    ),
    _NavItem(
      branch: ShellBranch.network,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: l10n.navNetwork,
    ),
  ];

  List<_NavItem> _companyTabs(AppLocalizations l10n) => [
    // The company's home is its dashboard, not the feed: a company follows
    // nobody, so that tab opened on an empty page every time.
    _NavItem(
      branch: ShellBranch.companyDashboard,
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard,
      label: l10n.navHome,
    ),
    _NavItem(
      branch: ShellBranch.companyJobs,
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: l10n.navMyJobs,
    ),
    _NavItem(
      branch: ShellBranch.companyApplicants,
      icon: Icons.assignment_ind_outlined,
      activeIcon: Icons.assignment_ind,
      label: l10n.navApplicants,
    ),
    // No Network tab. It is a people-you-may-know grid for an account that
    // follows nobody — four tabs a company uses beat five with one that opens
    // on strangers. The branch still exists, so a link into /network works.
    _NavItem(
      branch: ShellBranch.companyProfile,
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
    required this.banner,
  });

  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelect;
  final bool translucent;

  /// Drawn above the bar, inside the same surface. Here rather than in the
  /// Scaffold's body so it is not covered by a translucent bar over reels and
  /// does not move when a screen scrolls.
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final background = translucent ? const Color(0xE60A0D13) : c.surface;
    final inactive = translucent ? Colors.white60 : c.ink3;
    final active = translucent ? Colors.white : c.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        Container(
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
        ),
      ],
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
