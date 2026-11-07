import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/image_viewer.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';
import 'package:mohandis/features/reels/domain/entities/reel.dart';
import 'package:mohandis/features/reels/presentation/screens/reels_screen.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';
import 'package:mohandis/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/features/stories/presentation/notifiers/story_groups.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_activity_notifier.dart';
import '../notifiers/profile_notifier.dart';
import 'cv_section_editor.dart';
import '../widgets/company_sections.dart';
import '../widgets/profile_activity_section.dart';
import '../widgets/profile_banner.dart';

/// One person's profile — their own or anybody else's.
///
/// **Always refetches on entry.** [profileNotifierProvider] caches a profile
/// for the whole session and that is right for its other readers: the job
/// detail, apply and company-job-form screens all read `me` constantly, and
/// `byPerson` is four requests (the profile plus experience, education and
/// skills), so paying that on every one of those screens would be absurd.
///
/// It is wrong *here*, though, and visibly so: walking back onto a profile
/// showed the copy fetched the last time it was opened — an old headline, an
/// old photo, a follower count from before the follow that was just made —
/// and left it there. This screen is the one surface whose entire job is to
/// say what the profile is now, so it re-reads on every visit and shows the
/// skeleton while it does, rather than painting a stale answer first.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// True from the moment this screen mounts over a cached profile until its
  /// own read replaces it.
  ///
  /// Needed as a separate flag rather than just calling `refresh()`, because
  /// `refresh()` cannot run during `initState` — it writes to the provider the
  /// next `build` watches — and by the time the deferred call lands, the stale
  /// profile has already been painted. This holds the skeleton across that
  /// gap, so nothing that belongs to an earlier visit is ever on screen.
  bool _stale = false;

  @override
  void initState() {
    super.initState();
    final provider = profileNotifierProvider(widget.personId);
    // No cached value means the provider is fetching for us already; the
    // `loading` branch below covers it and a second read would be one wasted
    // set of four requests per profile opened.
    if (!ref.read(provider).hasValue) return;

    _stale = true;
    Future.microtask(() async {
      if (!mounted) return;
      // `reload`, not `refresh`: the skeleton is already up here, and this
      // provider has readers elsewhere that should not be suspended over it.
      await ref.read(provider.notifier).reload();
      if (mounted) setState(() => _stale = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final profile = ref.watch(profileNotifierProvider(widget.personId));
    // The directory is one page of profiles, so a miss here is normal — the
    // profile payload itself carries the name, headline and location.
    final directoryPerson = ref
        .watch(peopleDirectoryProvider)
        .valueOrNull?[widget.personId];

    return Scaffold(
      backgroundColor: c.bg,
      body: _stale
          ? const ProfilePageSkeleton()
          : profile.when(
              loading: () => const ProfilePageSkeleton(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref
                    .read(profileNotifierProvider(widget.personId).notifier)
                    .refresh(),
              ),
              data: (data) {
                // Says which of the two flags the badge is reading, and from
                // WHICH record. The profile payload and the directory page can
                // disagree — `_Body` prefers the directory — so a badge that
                // will not appear has two possible sources and this names both.
                final shown = directoryPerson ?? data.person;
                debugPrint(
                  '[profile] ${widget.personId} badge: '
                  'verified=${shown.verified} subscribed=${shown.subscribed} '
                  '(from ${directoryPerson != null ? 'directory' : 'profile payload'}; '
                  'payload says verified=${data.person.verified} '
                  'subscribed=${data.person.subscribed})',
                );
                return _Body(
                  // The ROUTE's id, which is also this screen's provider key —
                  // `me` on your own profile. Refreshing needs the same key,
                  // and deriving it from the profile would miss when the route
                  // carries a real id for the viewer's own page.
                  providerKey: widget.personId,
                  profile: data,
                  person: shown,
                );
              },
            ),
    );
  }
}

/// The profile body: ONE scroll view, header then tab strip then the selected
/// tab's rows.
///
/// It was a `NestedScrollView` with a `TabBarView` — three scrollables kept
/// alive behind one another, under a pinned header and an overlap absorber.
/// That shape threw `!semantics.parentDataDirty` on every frame the profile
/// rebuilt, and it made pull-to-refresh ambiguous (which of the four scrollers
/// owns the gesture?). One viewport has neither problem: the tab strip pins
/// itself as an ordinary sliver, the tab's content follows it as more slivers,
/// and a single `RefreshIndicator` sits over the whole thing.
class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.providerKey,
    required this.profile,
    required this.person,
  });

  /// The key this screen's [profileNotifierProvider] family was read with.
  final String providerKey;

  final Profile profile;
  final Person person;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// 0 posts, 1 reels, 2 CV.
  int _tab = 0;

  Profile get profile => widget.profile;
  Person get person => widget.person;

  bool get _isMe => profile.isMe;

  /// A private account the viewer may not see into: not their own, not
  /// followed. Following it is what unlocks the posts.
  bool get _locked =>
      !profile.isCompany && profile.isPrivate && !_isMe && !profile.following;

  /// Opens one of the people lists for this profile.
  ///
  /// `me` rides as a query parameter because the list screen cannot work it
  /// out for itself — `isMe` comes off the server's projection of THIS
  /// profile, and the list route only carries an id. It gates the Unfollow
  /// button, so getting it wrong in the false direction merely hides a button,
  /// while the true direction would offer to tear down the viewer's own edges
  /// from a stranger's list.
  void _openPeople(String kind) {
    context.push('/profile/${person.id}/people/$kind?me=$_isMe');
  }

  /// Everything the page shows, re-read as one pull.
  ///
  /// The profile drives the indicator because it is the slowest and the one
  /// whose numbers the header prints; the tab providers are autoDispose
  /// families, so invalidating them refetches only what is on screen.
  Future<void> _refresh() async {
    ref.invalidate(profileActivityFeedProvider(person.id));
    ref.invalidate(profileReelsProvider(profile.personId));
    await pullRefresh(
      ref.refresh(profileNotifierProvider(widget.providerKey).future),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(person: person, isMe: _isMe),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: profile.isCompany
                ? _CompanyBody(
                    providerKey: widget.providerKey,
                    profile: profile,
                    person: person,
                    isMe: _isMe,
                  )
                : CustomScrollView(
                    // Always scrollable, so a short profile still answers a
                    // pull — without it the indicator only works once the
                    // content overflows the screen.
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _Header(
                          providerKey: widget.providerKey,
                          profile: profile,
                          person: person,
                          isMe: _isMe,
                          onOpenPeople: _openPeople,
                        ),
                      ),
                      // A locked account has no tabs: the notice below is the
                      // whole story, and a strip that only moves an indicator
                      // is a control that answers and does nothing.
                      if (!_locked)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabsHeader(
                            selected: _tab,
                            onSelect: (i) => setState(() => _tab = i),
                          ),
                        ),
                      if (_locked)
                        SliverToBoxAdapter(
                          child: _PrivateAccountNotice(
                            requested: profile.followRequestPending,
                          ),
                        )
                      else if (_tab == 0)
                        _PostsTab(
                          personId: person.id,
                          profileId: profile.personId,
                        )
                      else if (_tab == 1)
                        _ReelsTab(profileId: profile.personId)
                      else
                        _CvTab(
                          profile: profile,
                          personId: person.id,
                          isMe: _isMe,
                        ),
                      // Breathing room under the last row, and the slack a
                      // pull needs on a page that ends exactly at the fold.
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Back, the handle, and the options sheet — the bar that replaced the cover.
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.person, required this.isMe});

  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;

    return Container(
      color: c.surface,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              // `chevron_left` would point the wrong way in Arabic; the
              // directional icon flips with the locale.
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/feed'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      // The handle, not the display name: the name is under
                      // the avatar, and repeating it wastes the one line that
                      // says which account this is.
                      person.username.isEmpty ? person.name : person.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  NameBadges(
                    verified: person.verified,
                    subscribed: person.subscribed,
                    size: 15,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              // On your own profile the menu leads straight to Settings, which
              // already holds everything the old sheet offered (edit profile,
              // log out). Someone else's profile keeps the sheet for Block.
              onPressed: isMe
                  ? () => context.push('/settings')
                  : () => _showOptions(context, ref, person.id),
              tooltip: isMe
                  ? context.l10n.settingsTitle
                  : context.l10n.profileMoreOptions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything above the tabs: the avatar and the three counts, who this is,
/// what they do, and the two buttons.
/// The square the profile's mark occupies where it crosses the cover.
///
/// Fixed, and deliberately WIDER than the 78pt avatar inside it, because
/// `RungAvatar` grows by 10pt the moment it has a story ring to draw. Sizing
/// the slot to the avatar would move the counts and every line under them
/// sideways on the day the person posted a story, and back again when it
/// expired.
const double _avatarSlot = 88;

/// How far the mark hangs below the cover: half of it, so the cover's bottom
/// edge runs through its centre.
const double _avatarOverlap = _avatarSlot / 2;

/// The avatar the way the header stacks it — a fixed [_avatarSlot] square with
/// a surface ring, so it reads as sitting ON the cover rather than cut into it.
///
/// The ring is `RungAvatar`'s own whenever there is a story to show: that one
/// already paints a surface band between the gradient and the photo, and
/// drawing a second one around it would be two rings. With no story there is no
/// band at all, so this adds the plain disc — and pads by 5 so the result is
/// the same [_avatarSlot] either way.
class _HeaderAvatar extends ConsumerWidget {
  const _HeaderAvatar({required this.profile, required this.person});

  final Profile profile;
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final ring = ref.watch(storyRingForProvider(person.id));
    final url = ref.watch(imageUrlResolverProvider)(profile.avatarUrl);

    final Widget avatar = RungAvatar(
      seed: person.id,
      initials: person.initials,
      icon: person.accountType.icon,
      size: 78,
      ringState: ring,
      imageUrl: url,
    );

    return GestureDetector(
      // Only a real photo opens the viewer. A monogram has nothing to show
      // full-screen, and a tap that opens a blank sheet is worse than one that
      // does nothing.
      onTap: url == null ? null : () => showImageViewer(context, urls: [url]),
      child: SizedBox(
        width: _avatarSlot,
        height: _avatarSlot,
        child: Center(
          child: ring == StoryRingState.none
              ? Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surface,
                  ),
                  child: avatar,
                )
              : avatar,
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.providerKey,
    required this.profile,
    required this.person,
    required this.isMe,
    required this.onOpenPeople,
  });

  /// The key this screen's [profileNotifierProvider] was read with — passed
  /// down so the banner can publish its write onto the same instance.
  final String providerKey;

  final Profile profile;
  final Person person;
  final bool isMe;

  /// `followers` / `following` — the counts that open a list. Posts does not:
  /// they are right below, in the first tab.
  final void Function(String kind) onOpenPeople;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    // One line: what they do and what they are. "مهندس برمجيات · هندسة
    // البرمجيات" would be a stutter, so the discipline is dropped when the
    // headline already contains it.
    final discipline = profile.disciplineName.isEmpty
        ? profile.industry
        : profile.disciplineName;
    final showsDiscipline =
        discipline.isNotEmpty && !person.headline.contains(discipline);
    final subtitle = [
      if (person.headline.isNotEmpty) person.headline,
      if (showsDiscipline) discipline,
    ].join(' · ');

    final current = profile.experience.isEmpty ? null : profile.experience.first;
    final school = profile.education.isEmpty ? null : profile.education.first;
    final place = profile.governorateName.isEmpty
        ? person.location
        : profile.governorateName;

    return Stack(
      // The mark hangs off the cover's bottom edge, so it is a POSITIONED
      // sibling drawn last rather than a child of the padded block below.
      // Inside that block a negative offset would simply be painted over
      // by the block's own background.
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed and ABOVE the padded block, not inside it: a cover
            // inset by the gutter is a framed picture, not a banner.
            ProfileBanner(
              coverUrl: profile.coverUrl,
              seed: person.id,
              isMe: isMe,
              providerKey: providerKey,
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(
                RungSpace.gutter,
                RungSpace.sm,
                RungSpace.gutter,
                RungSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The counts, indented past the avatar that hangs over them.
                  // The avatar is NOT in this column — it is stacked on the cover
                  // above, and this inset is the hole it sits in.
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: _avatarSlot + RungSpace.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CountStat(
                          value: profile.postCount,
                          label: l10n.profilePosts,
                        ),
                        _CountStat(
                          value: profile.followerCount,
                          label: l10n.profileFollowers,
                          onTap: () => onOpenPeople('followers'),
                        ),
                        _CountStat(
                          value: profile.followingCount,
                          label: l10n.profileFollowing,
                          onTap: () => onOpenPeople('following'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RungSpace.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Name and badge are ONE Wrap child. As two, the
                          // Wrap's 8pt spacing would stack on the badge's own
                          // 5pt gap, and a long name could wrap away from the
                          // mark that belongs to it.
                          NameBadges(
                            verified: person.verified,
                            subscribed: person.subscribed,
                            size: 15,
                          ),
                        ],
                      ),
                      if (profile.openToWork)
                        RungStatusPill.success(
                          context,
                          label: l10n.profileOpenToWork,
                          leading: RungDot(color: c.green),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // The discipline's own logo, when this line is carrying the
                        // discipline at all — the uploaded mark for "هندسة البرمجيات"
                        // says what the words say, faster.
                        if (showsDiscipline) ...[
                          _DisciplineLogo(iconUrl: profile.disciplineIconUrl),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (profile.about.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      profile.about,
                      style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Where they work, where they studied, where they are — the three
                  // facts a visitor reads before deciding to follow. Each is omitted
                  // rather than shown empty.
                  if (current != null)
                    _MetaRow(
                      icon: Icons.work_outline_rounded,
                      text: current.company.isEmpty
                          ? current.role
                          : '${current.role} · ${current.company}',
                    ),
                  if (school != null)
                    _MetaRow(icon: Icons.school_outlined, text: school.school),
                  if (place.isNotEmpty)
                    _MetaRow(icon: Icons.place_outlined, text: place),
                  const SizedBox(height: RungSpace.sm),
                  _Actions(profile: profile, person: person, isMe: isMe),
                ],
              ),
            ),
          ],
        ),
        PositionedDirectional(
          start: RungSpace.gutter,
          top: ProfileBanner.height - _avatarOverlap,
          child: _HeaderAvatar(profile: profile, person: person),
        ),
      ],
    );
  }
}

/// One line of the small print under the bio.
/// The engineering discipline's logo, at text size.
///
/// An 18px mark rather than a chip: it sits inside the accent line that names
/// the discipline, so it is the same statement, not a second one. Falls back to
/// the generic engineering glyph while nobody has uploaded a logo for that
/// discipline — and to nothing at all if the upload is broken, since a grey
/// box beside the name would say less than the name alone.
class _DisciplineLogo extends ConsumerWidget {
  const _DisciplineLogo({required this.iconUrl});

  /// Host-less, like every other upload. Null on a discipline whose logo has
  /// never been set.
  final String? iconUrl;

  static const double _size = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final url = ref.watch(imageUrlResolverProvider)(iconUrl);

    if (url == null) {
      return Icon(Icons.engineering_outlined, size: _size, color: c.accent);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.engineering_outlined, size: _size, color: c.accent),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const SizedBox(width: _size, height: _size),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pinned tab strip between the header and the rows.
///
/// Three labels and an underline, drawn by hand rather than with a `TabBar`:
/// a `TabBar` needs a `TabController`, and the controller only earns its keep
/// alongside a `TabBarView` — which this page no longer has.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  const _TabsHeader({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const double _height = 46;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.rung;
    final l10n = context.l10n;
    final labels = [
      l10n.profileTabPosts,
      l10n.profileTabReels,
      l10n.profileTabCv,
    ];

    return Material(
      color: c.surface,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  height: _height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected ? c.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: i == selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i == selected ? c.ink : c.ink3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) =>
      oldDelegate.selected != selected;
}

/// Everything this person has published — posts AND reels, newest first.
///
/// **One grid, two sources.** A reel is a post as far as a visitor is
/// concerned: it is a thing this person made, and leaving it out of the first
/// tab meant a profile whose owner posts mostly reels looked empty until you
/// found the second tab. The reels tab stays, as the filter for somebody who
/// wants only those — the same split Instagram uses, and for the same reason.
///
/// **Posts decide the state; reels are additive.** The two come from separate
/// calls, so a reels failure must not blank out the posts — it would turn one
/// endpoint having a bad moment into "this person has posted nothing", which
/// is a lie about them rather than an error about us. Reels contribute what
/// they have and nothing when they have nothing.
class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.personId, required this.profileId});

  final String personId;

  /// The real ProfileId — `me` is a route alias the reels filter does not know.
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activity = ref.watch(profileActivityFeedProvider(personId));
    final reels = ref.watch(profileReelsProvider(profileId));

    // A sliver, not a box: this goes straight into the page's one
    // CustomScrollView, under the pinned tab strip.
    return activity.when(
      // Still loading while EITHER is in flight, so the grid is not drawn
      // once without reels and then again with them — a reshuffle of
      // everything the person is already looking at.
      loading: () => const SliverToBoxAdapter(child: GridTabSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(profileActivityFeedProvider(personId)),
        ),
      ),
      data: (data) {
        if (reels.isLoading) {
          return const SliverToBoxAdapter(child: GridTabSkeleton());
        }

        final entries = <_Published>[
          for (final post in data.posts) _Published.post(post),
          // `valueOrNull`: an errored reels call contributes nothing rather
          // than taking the posts down with it.
          for (final reel in reels.valueOrNull ?? const <Reel>[])
            _Published.reel(reel),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (entries.isEmpty) return _TabEmpty(text: l10n.profileNoPosts);

        return SliverPadding(
          padding: const EdgeInsets.all(1),
          sliver: SliverGrid(
            // Square, not the reels tab's 0.72. A mixed grid has to pick one
            // shape, and a square crops a portrait poster without stretching
            // a landscape photo — the reels tab is where the real proportion
            // still lives.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final entry = entries[i];
                final post = entry.asPost;
                return post != null
                    ? _PostTile(post: post)
                    : _ReelTile(reel: entry.asReel!, profileId: profileId);
              },
              childCount: entries.length,
            ),
          ),
        );
      },
    );
  }
}

/// One thing somebody published: a post or a reel, with the date that orders
/// them against each other.
///
/// A small sealed-by-convention holder rather than a shared supertype on the
/// entities: `Post` and `Reel` come from different features and have no
/// business knowing about one another for the sake of one grid.
class _Published {
  const _Published.post(Post this.asPost) : asReel = null;
  const _Published.reel(Reel this.asReel) : asPost = null;

  final Post? asPost;
  final Reel? asReel;

  DateTime get createdAt => asPost?.createdAt ?? asReel!.createdAt;
}

/// One square in the posts grid: its first picture, or its opening words.
class _PostTile extends ConsumerWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final pictures = [for (final m in post.media) if (!m.isDocument) m];
    final resolve = ref.watch(imageUrlResolverProvider);
    final quoted = post.quoted;
    // A repost has nothing of its own to draw — a plain one carries no text or
    // media at all, and used to come out as a bare gradient. Its own picture
    // and words still win (a quote with commentary); the original fills in
    // whatever the repost lacks.
    final url = pictures.isNotEmpty
        ? resolve(pictures.first.url)
        : resolve(quoted?.firstMediaUrl);
    final text = post.text.trim().isNotEmpty
        ? post.text
        : (quoted?.text.trim() ?? '');
    final isRepost = (post.sharedPostId ?? '').isNotEmpty || quoted != null;

    return GestureDetector(
      onTap: () => context.push('/feed/posts/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Neutral, not a per-post gradient: a picture still loading (or one
          // that failed) should read as a picture-shaped gap, not as colour
          // the post was published with.
          // A picture's tile is light grey until the picture arrives; a
          // text-only post gets the card below instead.
          if (url != null) ColoredBox(color: c.surface3),
          if (url != null)
            Image.network(
              url,
              fit: BoxFit.cover,
              // The grey underneath is the fallback, with an image mark so a
              // picture that failed reads as one rather than as an empty tile.
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.image_outlined, size: 22, color: c.ink3),
              ),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
          // Text only, with no picture to cover it: a card of its own.
          if (url == null && text.isNotEmpty) _TextPostTile(text: text),
          // The original was deleted: say so rather than leave a blank tile.
          if (post.originalUnavailable && url == null && text.isEmpty)
            Center(
              child: Icon(
                Icons.link_off_rounded,
                size: 22,
                color: c.ink3,
              ),
            ),
          // Marks a repost, so somebody else's post in this grid does not
          // read as this person's own.
          if (isRepost)
            PositionedDirectional(
              top: 6,
              start: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  // Dark glass over a picture; the accent tint on a text card,
                  // where a black disc would be the darkest thing on it.
                  color: url == null ? c.accentSoft2 : const Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 13,
                  color: url == null ? c.accent : Colors.white,
                ),
              ),
            ),
          if (pictures.length > 1)
            const PositionedDirectional(
              top: 6,
              end: 6,
              child: Icon(Icons.collections_outlined,
                  size: 15, color: Colors.white),
            ),
          if (post.media.any((m) => m.isDocument))
            PositionedDirectional(
              bottom: 6,
              end: 6,
              child: Icon(Icons.description_outlined,
                  size: 15, color: url == null ? c.ink3 : c.surface),
            ),
        ],
      ),
    );
  }
}

/// A post with words and no picture, as a tile in the grid.
///
/// A soft accent wash with a large quotation mark behind the words, and the
/// words centred — so the tile reads as a quote card rather than as a picture
/// that failed to load, which is what plain text at the top of a white square
/// looked like.
class _TextPostTile extends StatelessWidget {
  const _TextPostTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [c.accentSoft, c.surface],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The mark sits at the reading start of the tile, mostly off the
          // top edge so it decorates without competing with the words.
          PositionedDirectional(
            top: -10,
            start: 2,
            child: Icon(
              Icons.format_quote_rounded,
              size: 56,
              color: c.accentSoft2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 14),
            child: Center(
              child: Text(
                text,
                // A glimpse, not the post: three lines is enough to recognise
                // it, and the full text is one tap away.
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
          ),
          // A short accent rule at the foot, like the underline of a pull
          // quote. Small on purpose: an ornament, not a progress bar.
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reels grid. A tile opens this profile's reels full screen, starting at
/// that reel — see `_ReelTile`.
class _ReelsTab extends ConsumerWidget {
  const _ReelsTab({required this.profileId});

  /// The real ProfileId — `me` is a route alias the reels filter does not know.
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reels = ref.watch(profileReelsProvider(profileId));

    return reels.when(
      loading: () => const SliverToBoxAdapter(
        child: GridTabSkeleton(aspectRatio: 0.72),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(profileReelsProvider(profileId)),
        ),
      ),
      data: (rows) => rows.isEmpty
          ? _TabEmpty(text: l10n.profileNoReels)
          : SliverPadding(
              padding: const EdgeInsets.all(1),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ReelTile(reel: rows[i], profileId: profileId),
                  childCount: rows.length,
                ),
              ),
            ),
    );
  }
}

class _ReelTile extends ConsumerWidget {
  const _ReelTile({required this.reel, required this.profileId});

  final Reel reel;

  /// Whose grid this tile sits in — the key of [profileReelsProvider], and so
  /// of the player that opens from it.
  final String profileId;

  /// Plays this profile's reels full screen, starting at this one, over the
  /// profile — back returns here. It used to switch to the Reels tab, which
  /// showed the general wall rather than this reel and left no way back.
  void _open(BuildContext context, WidgetRef ref) {
    final shown = ref.read(profileReelsProvider(profileId)).valueOrNull;
    final at = shown?.indexWhere((r) => r.id == reel.id) ?? -1;
    context.push(
      '/profile/$profileId/reels',
      extra: at < 0
          ? ReelsPlayerSeed(reels: [reel], index: 0)
          : ReelsPlayerSeed(reels: shown!, index: at),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The STREAM-aware resolver, like the full-screen player. A reel published
    // since Stream arrived keeps its poster under the video's guid, served by
    // the library's own CDN — resolving that against the storage zone builds a
    // URL that 404s, the errorBuilder swallows it, and every tile in the grid
    // comes out a flat gradient.
    final url = ref.watch(streamAwareUrlResolverProvider)(reel.posterPath);

    return GestureDetector(
      onTap: () => _open(context, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark neutral while the poster loads: the white play mark has to
          // stay readable, and a coloured gradient read as part of the reel.
          const ColoredBox(color: Color(0xFF2A2F3A)),
          if (url != null)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
          const PositionedDirectional(
            bottom: 6,
            start: 6,
            child: Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Experience, education and skills — the CV, under its own tab now that the
/// profile's first screen belongs to the posts.
class _CvTab extends StatelessWidget {
  const _CvTab({
    required this.profile,
    required this.personId,
    required this.isMe,
  });

  final Profile profile;
  final String personId;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Somebody else's profile with all three sections empty would render a
    // blank tab — the sections below are hidden when empty unless it is your
    // own profile, where they stay so the first entry can be added.
    if (!isMe &&
        profile.experience.isEmpty &&
        profile.education.isEmpty &&
        profile.skills.isEmpty) {
      return _TabEmpty(text: l10n.profileSectionEmpty);
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: RungSpace.sm, bottom: 28),
      sliver: SliverList.list(
        children: [
          // On your own profile the three sections always render, empty or not —
          // a section you cannot see is a section you cannot add the first entry
          // to. On somebody else's they stay hidden when empty.
          if (isMe || profile.experience.isNotEmpty)
            _CvSection(
              icon: Icons.work_outline_rounded,
              title: l10n.profileExperience,
              editPath: isMe ? '/profile/me/experience' : null,
              editTooltip: l10n.profileEditExperience,
              children: [
                if (profile.experience.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  for (final group in _ExperienceGroup.from(profile.experience))
                    _ExperienceGroupView(group: group),
              ],
            ),
          if (isMe || profile.education.isNotEmpty)
            _CvSection(
              icon: Icons.school_outlined,
              title: l10n.profileEducation,
              editPath: isMe ? '/profile/me/education' : null,
              editTooltip: l10n.profileEditEducation,
              children: [
                if (profile.education.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  for (final item in profile.education)
                    _EducationRow(item: item),
              ],
            ),
          if (isMe || profile.skills.isNotEmpty)
            _CvSection(
              icon: Icons.auto_awesome_outlined,
              title: l10n.profileSkills,
              editPath: isMe ? '/profile/me/skills' : null,
              editTooltip: l10n.profileEditSkills,
              children: [
                if (profile.skills.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  _SkillsWrap(
                    skills: profile.skills,
                    personId: personId,
                    canEndorse: !isMe,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: c.ink3),
        ),
      ),
    );
  }
}

/// A company keeps its single scroll: jobs, about, the overview and its posts.
/// The tabs above are a person's shape — a company has no CV and no reels.
class _CompanyBody extends StatelessWidget {
  const _CompanyBody({
    required this.providerKey,
    required this.profile,
    required this.person,
    required this.isMe,
  });

  final String providerKey;
  final Profile profile;
  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return ListView(
      // The page's RefreshIndicator needs a scrollable that always answers a
      // drag, even when the company's sections do not fill the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _CompanyHeader(
          providerKey: providerKey,
          profile: profile,
          person: person,
          isMe: isMe,
        ),
        CompanyJobsSection(personId: person.id, isMe: isMe),
        if (profile.about.trim().isNotEmpty)
          RungSection(
            title: l10n.profileAbout,
            child: Text(
              profile.about,
              style: TextStyle(fontSize: 13.5, height: 1.55, color: c.ink2),
            ),
          ),
        if (profile.hasCompanyDetails) CompanyOverviewSection(profile: profile),
        ProfileActivitySection(profile: profile, personId: person.id),
      ],
    );
  }
}

/// The company version of [_Header]: a rounded mark rather than a circle, and
/// open postings in place of the posts count.
class _CompanyHeader extends ConsumerWidget {
  const _CompanyHeader({
    required this.providerKey,
    required this.profile,
    required this.person,
    required this.isMe,
  });

  final String providerKey;
  final Profile profile;
  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final subtitle =
        person.headline.isEmpty ? profile.industry : person.headline;

    return Stack(
      // The mark hangs off the cover's bottom edge, so it is a POSITIONED
      // sibling drawn last rather than a child of the padded block below.
      // Inside that block a negative offset would simply be painted over
      // by the block's own background.
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed and ABOVE the padded block, not inside it: a cover
            // inset by the gutter is a framed picture, not a banner.
            ProfileBanner(
              coverUrl: profile.coverUrl,
              seed: person.id,
              isMe: isMe,
              providerKey: providerKey,
            ),
            Container(
              color: c.surface,
              margin: const EdgeInsets.only(bottom: RungSpace.sectionGap),
              padding: const EdgeInsets.fromLTRB(
                RungSpace.gutter,
                RungSpace.sm,
                RungSpace.gutter,
                RungSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Same hole as the individual header: the company's mark is
                  // stacked on the cover above, not laid out here.
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: _avatarSlot + RungSpace.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _OpenJobsStat(personId: person.id),
                        _CountStat(
                          value: profile.followerCount,
                          label: l10n.profileFollowers,
                          onTap: () => context.push(
                            '/profile/${person.id}/people/followers?me=$isMe',
                          ),
                        ),
                        _CountStat(
                          value: profile.postCount,
                          label: l10n.profilePosts,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RungSpace.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Name and badge are ONE Wrap child. As two, the
                          // Wrap's 8pt spacing would stack on the badge's own
                          // 5pt gap, and a long name could wrap away from the
                          // mark that belongs to it.
                          NameBadges(
                            verified: person.verified,
                            subscribed: person.subscribed,
                            size: 15,
                          ),
                        ],
                      ),
                      if (profile.hiring)
                        RungStatusPill.accent(
                          context,
                          label: '✦ ${l10n.profileHiring}',
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _CompanyMetaRow(
                    profile: profile,
                    location: profile.governorateName.isEmpty
                        ? person.location
                        : profile.governorateName,
                    // The line above falls back to the industry when there is no
                    // headline; when it did, this must not print it a second time.
                    showIndustry: subtitle != profile.industry,
                  ),
                  const SizedBox(height: RungSpace.sm),
                  _Actions(profile: profile, person: person, isMe: isMe),
                ],
              ),
            ),
          ],
        ),
        PositionedDirectional(
          start: RungSpace.gutter,
          top: ProfileBanner.height - _avatarOverlap,
          // A rounded SQUARE, not a circle. A circle is a face — the
          // strongest signal on the page that you are looking at a
          // person, and it was why a company read as somebody.
          child: _CompanyMark(
            profile: profile,
            person: person,
            size: _avatarSlot,
          ),
        ),
      ],
    );
  }
}

/// Options on someone else's profile. Your own profile's menu button opens
/// Settings directly instead.
Future<void> _showOptions(
  BuildContext context,
  WidgetRef ref,
  String personId,
) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = sheetContext.rung;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.flag_outlined, color: c.ink),
              title: Text(l10n.reportProfile),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showReportSheet(
                  context,
                  target: ReportTarget.profile,
                  targetId: personId,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: c.red),
              title: Text(
                l10n.profileBlock,
                style: TextStyle(color: c.red),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmBlock(context, ref, personId);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Asks first, then blocks, then leaves the profile.
///
/// Leaving is not optional: after a block the module stops serving that profile
/// to the caller, so staying on the screen would leave a page that cannot be
/// refreshed and 404s the moment anything re-reads it.
Future<void> _confirmBlock(
  BuildContext context,
  WidgetRef ref,
  String personId,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.profileBlockTitle),
      content: Text(l10n.profileBlockBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(l10n.profileBlock),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await ref.read(profileRepositoryProvider).block(personId);
  if (!context.mounted) return;

  result.when(
    success: (_) {
      showRungToast(context, l10n.profileBlockDone);
      // Everything that held this profile — the screen's own notifier, the
      // feed, the directory — was read before the block and still contains
      // them. Invalidating the profile alone would leave their posts in a feed
      // that no longer has any way to fetch them again.
      ref.invalidate(profileNotifierProvider(personId));
      ref.invalidate(feedNotifierProvider);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/feed');
      }
    },
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}

class _CountStat extends StatelessWidget {
  const _CountStat({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ArabicNumbers.compact(value),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c.ink3)),
        ],
      ),
    );
  }
}

/// A company's mark: its logo on a rounded square, or a monogram tile when it
/// has no logo.
///
/// Deliberately not a [RungAvatar]. A circle reads as a face — it was the
/// single strongest reason a company page looked like somebody's profile — and
/// every other company mark in the app (job cards, the jobs list) is already a
/// rounded tile.
class _CompanyMark extends ConsumerWidget {
  const _CompanyMark({
    required this.profile,
    required this.person,
    required this.size,
  });

  final Profile profile;
  final Person person;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final logo = ref.watch(imageUrlResolverProvider)(profile.avatarUrl);
    const radius = 20.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius + 4),
        border: Border.all(color: c.surface, width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // The monogram is a LAYER beneath, not the else-branch. As an
        // either/or it was unreachable while the image was in flight, so a
        // company with a logo showed an empty surface-coloured square on its
        // own header for the whole fetch and then popped. `RungAvatar` has
        // always done it this way; this is the same shape.
        child: Stack(
          fit: StackFit.expand,
          children: [
            RungLogoTile(
              seed: person.id,
              monogram: person.initials,
              size: size,
              radius: radius,
            ),
            if (logo != null)
              Image.network(
                logo,
                fit: BoxFit.cover,
                // Both fall through to the monogram already painted below.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Industry · headcount · founded · location, on one wrapping line under the
/// company name.
///
/// These four used to live in a card below the activity feed, under a heading
/// most visitors never scrolled to. They are the first things anyone wants to
/// know about an organisation, and they are short enough to sit in the header.
class _CompanyMetaRow extends StatelessWidget {
  const _CompanyMetaRow({
    required this.profile,
    required this.location,
    required this.showIndustry,
  });

  final Profile profile;
  final String location;

  /// False when the line above is already showing the industry, because the
  /// company stated no headline. Repeating it immediately underneath reads as
  /// a rendering fault.
  final bool showIndustry;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final size = profile.companySize.label(context);
    final founded = profile.foundedOn;

    final facts = <(IconData, String)>[
      if (showIndustry && profile.industry.isNotEmpty)
        (Icons.category_outlined, profile.industry),
      if (location.isNotEmpty) (Icons.place_outlined, location),
      if (size != null) (Icons.groups_outlined, size),
      if (founded != null)
        (Icons.event_outlined, l10n.companyFoundedOn(formatDayArabic(founded))),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final (icon, value) in facts)
            ConstrainedBox(
              // `Wrap` hands each child a LOOSE full-width constraint and a
              // Row gives a non-flex child unbounded main-axis space, so a
              // long industry or location did not wrap or ellipsise — it
              // overflowed into stripes. Capping the fact at the line width
              // and letting the text flex inside it is what makes the ellipsis
              // reachable.
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: c.ink3),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.ink3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "N open jobs" — a company's headline number, in the stat row.
///
/// Reads the same provider the jobs section below does, so the count and the
/// list can never disagree. Renders nothing at all while it loads rather than
/// a zero: "0 postings" is a claim, and one made before anything was read is
/// the wrong one to put under a company's name.
class _OpenJobsStat extends ConsumerWidget {
  const _OpenJobsStat({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(companyOpenJobsProvider(personId)).valueOrNull;
    if (jobs == null) return const SizedBox.shrink();

    return _CountStat(
      value: jobs.length,
      // The plural form, not a fixed label: Arabic wants "وظائف" for three
      // and "وظيفة" for thirty, and one string cannot be both.
      label: context.l10n.companyOpenJobsCount(jobs.length),
      onTap: jobs.isEmpty
          ? null
          : () => context.push('/profile/$personId/jobs'),
    );
  }
}

/// The two buttons under the header.
///
/// Your own profile: edit it, or download your CV. Somebody else's: follow
/// them, or message them. There is no Connect — the app has one relationship
/// and it is following.
class _Actions extends ConsumerWidget {
  const _Actions({
    required this.profile,
    required this.person,
    required this.isMe,
  });

  final Profile profile;
  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    if (isMe) {
      return Row(
        children: [
          Expanded(
            child: _FlatButton(
              label: l10n.profileEdit,
              onTap: () => context.push('/profile/me/edit'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FlatButton(
              label: l10n.profileDownloadCv,
              onTap: () => _openCv(context, ref, profile),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 38,
            child: OutlinedButton(
              onPressed: () => context.push('/feed/composer'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                side: BorderSide(color: c.line2, width: 1.5),
                foregroundColor: c.ink2,
              ),
              child: const Icon(Icons.add, size: 19),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () async {
              final wasFollowing = profile.following;
              final result = await ref
                  .read(profileNotifierProvider(person.id).notifier)
                  .toggleFollow();
              if (!context.mounted) return;
              result.when(
                success: (_) => showRungToast(
                  context,
                  wasFollowing
                      ? l10n.toastUnfollowed
                      : l10n.toastFollowing(person.firstName),
                ),
                failure: (e) => showRungToast(
                  context,
                  arabicMessageForException(e),
                  success: false,
                ),
              );
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
            // A private profile answers a follow with a REQUEST, not a follow:
            // `following` stays false while `followRequestPending` is true, and
            // a button still reading "follow" invites the same tap forever.
            child: Text(
              profile.following
                  ? l10n.profileUnfollow
                  : profile.followRequestPending
                  ? l10n.profileFollowRequested
                  : l10n.profileFollow,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlatButton(
            label: l10n.profileMessage,
            onTap: () => context.push('/messages'),
          ),
        ),
      ],
    );
  }

  /// Opens the CV in whatever the phone uses for a PDF.
  ///
  /// The file is on the CDN and host-less on the profile, like every other
  /// upload, so it goes through the resolver first. A profile with none says
  /// so rather than opening an empty tab.
  static Future<void> _openCv(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final l10n = context.l10n;
    final url = ref.read(imageUrlResolverProvider)(profile.cvUrl);
    if (url == null) {
      showRungToast(context, l10n.profileNoCv, success: false);
      return;
    }

    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showRungToast(context, l10n.profileCvFailed, success: false);
    }
  }
}

/// The quiet button the design uses for everything that is not the primary
/// action: a filled grey pill with dark text.
class _FlatButton extends StatelessWidget {
  const _FlatButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        backgroundColor: c.surface2,
        foregroundColor: c.ink,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// The pencil beside a CV section heading. Own profile only.
class _SectionEditButton extends StatelessWidget {
  const _SectionEditButton({required this.path, required this.tooltip});

  final String path;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return IconButton(
      onPressed: () => context.push(path),
      icon: const Icon(Icons.edit_outlined, size: 19),
      tooltip: tooltip,
      color: c.ink2,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label, style: TextStyle(fontSize: 13, color: c.ink3)),
      ),
    );
  }
}

/// Consecutive roles at the same employer, shown under one logo.
///
/// The backend has no employer entity — `ExperienceModel.CompanyName` is free
/// text on each row — so a promotion is two unrelated rows that happen to share
/// a name. Grouping is therefore done here, and only over ADJACENT rows: the
/// list arrives newest-first, so two spells at the same company years apart
/// stay separate blocks, which is what actually happened.
class _ExperienceGroup {
  _ExperienceGroup(this.roles);

  final List<Experience> roles;

  Experience get first => roles.first;
  bool get isSingle => roles.length == 1;
  String get company => first.company;

  /// Span across every role in the group, oldest start to newest end.
  String get span {
    final start = roles
        .map((r) => r.startDate)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final current = roles.any((r) => r.isCurrent);
    final end = current
        ? null
        : roles
              .map((r) => r.endDate)
              .whereType<DateTime>()
              .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return formatDateRangeArabic(start, end, current);
  }

  static List<_ExperienceGroup> from(List<Experience> items) {
    final groups = <_ExperienceGroup>[];
    for (final item in items) {
      final key = item.company.trim();
      if (groups.isNotEmpty &&
          key.isNotEmpty &&
          groups.last.company.trim() == key) {
        groups.last.roles.add(item);
      } else {
        groups.add(_ExperienceGroup([item]));
      }
    }
    return groups;
  }
}

/// One block of the CV tab: a header with the section's mark and its edit
/// pencil, then the entries, with a hairline between them.
///
/// Its own widget rather than [RungSection]: the CV reads as a list of cards
/// with quiet headers, and RungSection's title is sized for the page-level
/// sections of the profile above.
class _CvSection extends StatelessWidget {
  const _CvSection({
    required this.icon,
    required this.title,
    required this.children,
    required this.editTooltip,
    this.editPath,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// Null on somebody else's profile — no pencil.
  final String? editPath;
  final String editTooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (editPath != null)
                _SectionEditButton(path: editPath!, tooltip: editTooltip),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            children[i],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The square beside an entry: the section's own mark on a soft tint.
///
/// Replaces a monogram on a per-company gradient. Two letters of a company
/// name said little, and five different saturated colours down one column
/// pulled the eye away from the text that matters.
class _CvMark extends StatelessWidget {
  const _CvMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Icon(icon, size: 21, color: c.ink2),
    );
  }
}

/// A small icon and a line of meta text — dates, a place.
class _CvMeta extends StatelessWidget {
  const _CvMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(icon, size: 13, color: c.ink3),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _isolate(text),
              style: TextStyle(fontSize: 12, height: 1.35, color: c.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps text that STARTS in a Latin script in a left-to-right isolate.
///
/// The page is right-to-left, and a string like ".Net" or "Full Stack
/// Developer as .NET Back-End" is laid out by the bidi algorithm as if it were
/// Arabic: the leading or trailing punctuation jumps to the wrong end, which is
/// how ".Net" came out as "Net.". The isolate keeps the string's own order
/// while the line stays right-aligned with the rest of the page.
String _isolate(String text) {
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (RegExp(r'[A-Za-z]').hasMatch(ch)) return '⁦$text⁩';
    if (RegExp(r'[؀-ۿ]').hasMatch(ch)) return text;
  }
  return text;
}

class _ExperienceGroupView extends StatelessWidget {
  const _ExperienceGroupView({required this.group});

  final _ExperienceGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    if (group.isSingle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CvMark(icon: Icons.business_center_outlined),
            const SizedBox(width: 12),
            Expanded(child: _RoleDetails(item: group.first, showCompany: true)),
          ],
        ),
      );
    }

    // Several roles at one employer: the company owns the header, and each
    // role hangs off a timeline beneath it.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CvMark(icon: Icons.business_center_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isolate(group.company),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _metaLine([
                    employmentTypeLabel(l10n, group.first.employmentType),
                    group.span,
                  ]),
                  style: TextStyle(fontSize: 12.5, color: c.ink3),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < group.roles.length; i++)
                  _TimelineRole(
                    item: group.roles[i],
                    isLast: i == group.roles.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One role on the nested timeline: a dot, a connecting rail, and the details.
class _TimelineRole extends StatelessWidget {
  const _TimelineRole({required this.item, required this.isLast});

  final Experience item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: RungDot(
                    color: item.isCurrent ? c.accent : c.ink3,
                    size: 8,
                  ),
                ),
                // The rail stops at the last role so the timeline doesn't
                // trail off into the next company's block.
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: c.line2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _RoleDetails(item: item, showCompany: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title, the meta lines, and the description — the part that reads the same
/// whether a role stands alone or sits on a timeline.
class _RoleDetails extends StatelessWidget {
  const _RoleDetails({required this.item, required this.showCompany});

  final Experience item;

  /// False inside a group, where the company is already the heading above.
  final bool showCompany;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final type = employmentTypeLabel(l10n, item.employmentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isolate(item.role),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        if (showCompany) ...[
          const SizedBox(height: 2),
          Text(
            _metaLine([_isolate(item.company), type]),
            style: TextStyle(fontSize: 13, color: c.ink2),
          ),
        ],
        if (item.dates.isNotEmpty)
          _CvMeta(icon: Icons.calendar_today_outlined, text: item.dates),
        if (item.location.isNotEmpty)
          _CvMeta(icon: Icons.place_outlined, text: item.location),
        if (item.hasDescription)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isolate(item.description),
              style: TextStyle(fontSize: 13, height: 1.55, color: c.ink2),
            ),
          ),
      ],
    );
  }
}

/// Joins the parts of a meta line with "·", dropping the empty ones so a
/// missing employment type doesn't leave a dangling separator.
String _metaLine(List<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

class _EducationRow extends StatelessWidget {
  const _EducationRow({required this.item});

  final Education item;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CvMark(icon: Icons.school_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isolate(item.school),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.degreeLine.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _isolate(item.degreeLine),
                    style: TextStyle(fontSize: 13, color: c.ink2),
                  ),
                ],
                if (item.dates.isNotEmpty)
                  _CvMeta(
                    icon: Icons.calendar_today_outlined,
                    text: item.dates,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skills as chips, each with its endorsement count.
///
/// A row per skill with an outlined button beside each made a short list look
/// long, and offered you "+ تزكية" on your OWN skills — endorsing yourself is
/// not a thing. On somebody else's profile a chip is the endorse button.
class _SkillsWrap extends ConsumerWidget {
  const _SkillsWrap({
    required this.skills,
    required this.personId,
    required this.canEndorse,
  });

  final List<Skill> skills;
  final String personId;
  final bool canEndorse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final skill in skills)
            Material(
              color: c.surface2,
              shape: StadiumBorder(side: BorderSide(color: c.line)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: canEndorse
                    ? () => ref
                        .read(profileNotifierProvider(personId).notifier)
                        .endorse(skill.id)
                    : null,
                child: Tooltip(
                  message: canEndorse
                      ? l10n.profileEndorse
                      : l10n.profileEndorsements(
                          ArabicNumbers.count(skill.endorsements),
                        ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isolate(skill.name),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: skill.endorsements > 0
                                ? c.accentSoft
                                : c.surface3,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: canEndorse && skill.endorsements == 0
                              ? Icon(Icons.add_rounded, size: 14, color: c.accent)
                              : Text(
                                  ArabicNumbers.count(skill.endorsements),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: skill.endorsements > 0
                                        ? c.accent
                                        : c.ink3,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivateAccountNotice extends StatelessWidget {
  const _PrivateAccountNotice({required this.requested});

  /// A follow request is already waiting on the owner.
  final bool requested;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RungSpace.gutter,
        vertical: RungSpace.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.line2, width: 1.5),
            ),
            child: Icon(Icons.lock_outline_rounded, size: 26, color: c.ink2),
          ),
          const SizedBox(height: RungSpace.sm),
          Text(
            l10n.profilePrivateTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            requested ? l10n.profilePrivateRequested : l10n.profilePrivateBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.ink3, height: 1.5),
          ),
        ],
      ),
    );
  }
}

