import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:flutter_mobile_template/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_mobile_template/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';
import 'cv_section_editor.dart';
import '../widgets/company_sections.dart';
import '../widgets/profile_activity_section.dart';
import 'package:flutter_mobile_template/features/settings/presentation/screens/settings_screen.dart';

/// Height of the gradient cover *below* the status bar. The status-bar inset
/// is added on top of it (see [_coverHeight]) so the header controls sit in
/// their own band instead of colliding with the notch or with the avatar,
/// which straddles the bottom of the cover.
const double _kCoverVisibleHeight = 132;

/// Distance the avatar hangs below the cover seam.
const double _kAvatarOverhang = 44;

double _coverHeight(BuildContext context) =>
    _kCoverVisibleHeight + MediaQuery.paddingOf(context).top;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final profile = ref.watch(profileNotifierProvider(personId));
    // The directory is one page of profiles, so a miss here is normal — the
    // profile payload itself carries the name, headline and location.
    final directoryPerson = ref
        .watch(peopleDirectoryProvider)
        .valueOrNull?[personId];

    return Scaffold(
      backgroundColor: c.bg,
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider(personId).notifier).refresh(),
        ),
        data: (data) =>
            _Body(profile: data, person: directoryPerson ?? data.person),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile, required this.person});

  final Profile profile;
  final Person person;

  /// Resolved server-side from the bearer token — the client cannot tell by
  /// comparing ids, because its own ProfileId is not in the auth token.
  bool get _isMe => profile.isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final coverHeight = _coverHeight(context);

    // The line under the name: a person's headline, or — for a company that
    // stated none — what it does. Resolved once here because the meta row
    // below has to know whether the industry was spent up here.
    final subtitle = profile.isCompany && person.headline.isEmpty
        ? profile.industry
        : person.headline;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        // The avatar straddles the cover/surface seam, so the header is a
        // Stack: the column reserves top padding for the overlap and the
        // avatar is positioned across the boundary.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Cover(
                  personId: person.id,
                  coverUrl: profile.coverUrl,
                  isMe: _isMe,
                ),
                Container(
                  width: double.infinity,
                  color: c.surface,
                  margin: const EdgeInsets.only(bottom: RungSpace.sectionGap),
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    52,
                    RungSpace.gutter,
                    RungSpace.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (person.verified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 18),
                          ],
                        ],
                      ),
                      // A company fills `industry`, not `headline` — the
                      // sign-up form does not ask an organisation for a job
                      // title. Reading headline first and falling back keeps
                      // the line from coming up empty on most companies.
                      //
                      // Omitted entirely when both are empty: an empty `Text`
                      // still lays out a full line box, so a company that has
                      // stated neither got 25px of dead space between its name
                      // and the line below.
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.ink2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      // Location alone for a person. For a company the same
                      // line carries industry, headcount and founding date
                      // too: those are the first things anyone wants to know
                      // about an organisation, and they used to sit in a card
                      // below the fold under a heading nobody scrolled to.
                      if (profile.isCompany)
                        _CompanyMetaRow(
                          profile: profile,
                          location: person.location,
                          // The header above falls back to the industry when
                          // there is no headline; when it did, this must not
                          // print it a second time.
                          showIndustry: subtitle != profile.industry,
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 13, color: c.ink3),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                person.location,
                                style: TextStyle(fontSize: 12.5, color: c.ink3),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: RungSpace.sm),
                      // A `Wrap`, not a `Row`. A company carries THREE stats
                      // where a person carries two, and each is a bare pair of
                      // texts with no flex — at a raised text scale the third
                      // overflowed. Wrap also means the 18px gaps belong to
                      // the stats rather than sitting between them: a stat
                      // that renders nothing (see `_OpenJobsStat` while the
                      // jobs read is in flight) no longer leaves its separator
                      // behind, which used to indent the whole row and then
                      // jump it sideways when the count landed.
                      Wrap(
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          // Companies are followed, not connected with — the
                          // module has no company-to-person connection, so the
                          // count would always read zero. Open postings take
                          // the slot instead: it is what a visitor came to
                          // find out, and the one number a company is judged
                          // on here.
                          if (profile.isCompany)
                            _OpenJobsStat(personId: person.id)
                          else
                            _CountStat(
                              value: profile.connectionCount,
                              label: l10n.profileConnections,
                              // `go`, not `push`: /network is a branch root of
                              // the shell's IndexedStack, and pushing it would
                              // mount a second StatefulNavigationShell over
                              // the first — two nav bars sharing one set of
                              // GlobalKeys.
                              onTap: () => context.go('/network'),
                            ),
                          _CountStat(
                            value: profile.followerCount,
                            label: l10n.profileFollowers,
                          ),
                          if (profile.isCompany)
                            _CountStat(
                              value: profile.postCount,
                              label: l10n.profilePosts,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Actions(profile: profile, person: person, isMe: _isMe),
                    ],
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              start: RungSpace.gutter,
              top: coverHeight - _kAvatarOverhang,
              // A rounded SQUARE for a company. A circle is a face — it is the
              // single strongest signal on the page that you are looking at a
              // person, and it was the reason a company's page read as
              // somebody's profile with extra cards bolted underneath. Every
              // other company mark in the app (job cards, the jobs list) is
              // already a rounded tile; this makes the profile agree with them.
              child: profile.isCompany
                  ? _CompanyMark(
                      profile: profile,
                      person: person,
                      size: 88,
                    )
                  : RungAvatar(
                      seed: person.id,
                      initials: person.initials,
                      size: 88,
                      borderColor: c.surface,
                      borderWidth: 4,
                      imageUrl:
                          ref.watch(imageUrlResolverProvider)(profile.avatarUrl),
                    ),
            ),
            // A company is never "open to work"; it is hiring. The two pills
            // occupy the same corner, so the individual one is gated as well
            // rather than relying on the flag never being set.
            if (profile.openToWork && !profile.isCompany)
              PositionedDirectional(
                end: RungSpace.gutter,
                top: coverHeight + 8,
                child: RungStatusPill.success(
                  context,
                  label: l10n.profileOpenToWork,
                  leading: RungDot(color: c.green),
                ),
              )
            else if (profile.hiring)
              PositionedDirectional(
                end: RungSpace.gutter,
                top: coverHeight + 8,
                child: RungStatusPill.accent(
                  context,
                  label: '✦ ${l10n.profileHiring}',
                ),
              ),
          ],
        ),
        // A company's About is rendered below, in its own order — see the
        // company block. This one carries the CV download a person has.
        if (!profile.isCompany)
        RungSection(
          title: l10n.profileAbout,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.about,
                style: TextStyle(fontSize: 13.5, height: 1.55, color: c.ink2),
              ),
              if (_isMe) ...[
                const SizedBox(height: RungSpace.sm),
                TextButton.icon(
                  onPressed: () => showRungToast(context, l10n.comingSoon),
                  icon: const Icon(Icons.download_outlined, size: 15),
                  label: Text(l10n.profileDownloadCv),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
        // ── Company order ─────────────────────────────────────────────
        //
        // Jobs FIRST, above about and above the feed. A visitor on a company
        // page is almost always there for one of two reasons, and "are they
        // hiring" is the one with a deadline on it. It used to sit under the
        // activity feed, which on an active company meant scrolling past six
        // posts to reach the thing the page is for.
        //
        // Then about, then what the company states about itself, then its
        // posts. There is no CV below — a company has no experience, education
        // or skills — so nothing here is protecting a section further down.
        if (profile.isCompany) ...[
          CompanyJobsSection(personId: person.id, isMe: _isMe),
          if (profile.about.trim().isNotEmpty)
            RungSection(
              title: l10n.profileAbout,
              child: Text(
                profile.about,
                style: TextStyle(fontSize: 13.5, height: 1.55, color: c.ink2),
              ),
            ),
          if (profile.hasCompanyDetails)
            CompanyOverviewSection(profile: profile),
          ProfileActivitySection(profile: profile, personId: person.id),
        ] else
          // Activity sits between "about" and the CV, matching the order people
          // expect: what this person is doing now, then where they have been.
          ProfileActivitySection(profile: profile, personId: person.id),

        // On your own profile the three CV sections always render, empty or
        // not — a section you cannot see is a section you cannot add the first
        // entry to. On someone else's they stay hidden when empty.
        if (!profile.isCompany && (_isMe || profile.experience.isNotEmpty))
          RungSection(
            title: l10n.profileExperience,
            trailing: _isMe
                ? _SectionEditButton(
                    path: '/profile/me/experience',
                    tooltip: l10n.profileEditExperience,
                  )
                : null,
            child: Column(
              children: [
                if (profile.experience.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  for (final group in _ExperienceGroup.from(profile.experience))
                    _ExperienceGroupView(group: group),
              ],
            ),
          ),
        if (!profile.isCompany && (_isMe || profile.education.isNotEmpty))
          RungSection(
            title: l10n.profileEducation,
            trailing: _isMe
                ? _SectionEditButton(
                    path: '/profile/me/education',
                    tooltip: l10n.profileEditEducation,
                  )
                : null,
            child: Column(
              children: [
                if (profile.education.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  for (final item in profile.education)
                    _EducationRow(item: item),
              ],
            ),
          ),
        if (!profile.isCompany && (_isMe || profile.skills.isNotEmpty))
          RungSection(
            title: l10n.profileSkills,
            gapBelow: 0,
            trailing: _isMe
                ? _SectionEditButton(
                    path: '/profile/me/skills',
                    tooltip: l10n.profileEditSkills,
                  )
                : null,
            child: Column(
              children: [
                if (profile.skills.isEmpty)
                  _EmptySectionHint(label: l10n.profileSectionEmpty)
                else
                  for (final skill in profile.skills)
                    _SkillRow(skill: skill, personId: person.id),
              ],
            ),
          ),
      ],
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({
    required this.personId,
    required this.isMe,
    this.coverUrl,
  });

  final String personId;

  /// Gates the account actions in the options sheet — you cannot edit or sign
  /// out of somebody else.
  final bool isMe;

  /// The stored, host-less banner path. Resolved to a CDN URL here.
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(imageUrlResolverProvider)(coverUrl);

    return SizedBox(
      height: _coverHeight(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: personId == 'me'
                  ? RungGradients.brand
                  : RungGradients.forSeed('cover-$personId'),
            ),
          ),
          // Over the gradient, which stays as the fallback: a banner that
          // fails to load leaves the seeded gradient rather than a grey hole.
          if (banner != null)
            Image.network(
              banner,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top,
            start: 0,
            end: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RungSpace.gutter,
                vertical: 8,
              ),
              child: Row(
                children: [
                  _OverlayButton(
                    icon: Icons.chevron_left,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/feed'),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  const Spacer(),
                  _OverlayButton(
                    icon: Icons.more_horiz,
                    onTap: () => _showOptions(context, ref, isMe, personId),
                    tooltip: context.l10n.profileMoreOptions,
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

/// The profile's options sheet.
///
/// Two different sheets behind one button. On your own profile it is your
/// account — edit, settings, sign out. On somebody else's it is what you can do
/// ABOUT them, which is block.
///
/// Settings used to be offered from either, on the reasoning that settings are
/// app-wide. They are, but the screen behind them opens with "تعديل الملف" —
/// so from a stranger's profile the only thing the sheet offered was a route
/// into editing your own, which reads as an offer to edit THEIRS.
Future<void> _showOptions(
  BuildContext context,
  WidgetRef ref,
  bool isMe,
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
            if (isMe) ...[
              ListTile(
                leading: Icon(Icons.person_outline, color: c.ink),
                title: Text(l10n.profileEdit),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/profile/me/edit');
                },
              ),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: c.ink),
                title: Text(l10n.settingsTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/settings');
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: c.red),
                title: Text(
                  l10n.settingsLogout,
                  style: TextStyle(color: c.red),
                ),
                onTap: () {
                  // Closed first: the confirm dialog belongs to the screen, not
                  // to a sheet that is about to be dismissed under it.
                  Navigator.of(sheetContext).pop();
                  confirmAndLogout(context, ref);
                },
              ),
            ] else
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

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x660F172A),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
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
    // Null while it loads, which reads as "not a company" — the optimistic
    // side. Showing the button for a beat and having the server refuse is a
    // smaller failure than hiding a control a person is entitled to.
    final viewerIsCompany = ref
            .watch(profileNotifierProvider(ProfileRepository.meSentinel))
            .valueOrNull
            ?.isCompany ??
        false;

    if (isMe) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => context.push('/profile/me/edit'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
              child: Text(l10n.profileEdit),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
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
        // Connect is for PEOPLE, at BOTH ends. A connection is mutual and
        // symmetric — two people agreeing they know each other — and a company
        // is an organisation you follow. The server refuses either direction,
        // so offering the button would only buy a round trip and a refusal.
        //
        // The viewer's own type is read from their profile rather than assumed:
        // a company browsing a person has the same button and the same refusal
        // waiting behind it.
        if (!profile.isCompany && !viewerIsCompany) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ConnectButton(profile: profile, person: person),
          ),
        ],
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          height: 42,
          child: OutlinedButton(
            onPressed: () => context.push('/messages'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              side: BorderSide(color: c.line2, width: 1.5),
              foregroundColor: c.ink2,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
          ),
        ),
      ],
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

class _ExperienceGroupView extends StatelessWidget {
  const _ExperienceGroupView({required this.group});

  final _ExperienceGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    if (group.isSingle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RungLogoTile(
              seed: group.company,
              monogram: group.first.monogram,
              size: 46,
              radius: 11,
            ),
            const SizedBox(width: 12),
            Expanded(child: _RoleDetails(item: group.first, showCompany: true)),
          ],
        ),
      );
    }

    // Several roles at one employer: the company owns the header, and each
    // role hangs off a timeline beneath it.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RungLogoTile(
            seed: group.company,
            monogram: group.first.monogram,
            size: 46,
            radius: 11,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.company,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                  child: RungDot(color: c.ink3, size: 7),
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
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
          item.role,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        if (showCompany)
          Text(
            _metaLine([item.company, type]),
            style: TextStyle(fontSize: 13, color: c.ink2),
          ),
        if (item.dates.isNotEmpty)
          Text(item.dates, style: TextStyle(fontSize: 12, color: c.ink3)),
        if (item.location.isNotEmpty)
          Text(item.location, style: TextStyle(fontSize: 12, color: c.ink3)),
        if (item.hasDescription)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              item.description,
              style: TextStyle(fontSize: 13, height: 1.5, color: c.ink2),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RungLogoTile(
            seed: item.school,
            monogram: item.monogram,
            size: 46,
            radius: 11,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.school,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.degreeLine,
                  style: TextStyle(fontSize: 13, color: c.ink2),
                ),
                Text(item.dates, style: TextStyle(fontSize: 12, color: c.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends ConsumerWidget {
  const _SkillRow({required this.skill, required this.personId});

  final Skill skill;
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.profileEndorsements(
                    ArabicNumbers.count(skill.endorsements),
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => ref
                .read(profileNotifierProvider(personId).notifier)
                .endorse(skill.id),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(context.l10n.profileEndorse),
          ),
        ],
      ),
    );
  }
}

/// The "add" button, in whichever of its four states applies.
///
/// It used to be a toast and nothing else — tapping it told you a request was
/// sent, no request was sent, and the button still said "connect" afterwards.
/// Each state now maps to the action that makes sense from there, and the
/// label is driven by the server's own view of the edge
/// (`isConnected` / `connectionIncoming` / `connectionOutgoing` on ProfileDto),
/// so it survives a reopen of the screen rather than living in widget state.
class _ConnectButton extends ConsumerWidget {
  const _ConnectButton({required this.profile, required this.person});

  final Profile profile;
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(profileNotifierProvider(person.id).notifier);

    Future<void> run(
      Future<Result<Profile, AppException>> Function() action,
      String successMessage,
    ) async {
      final result = await action();
      if (!context.mounted) return;
      result.when(
        success: (_) => showRungToast(context, successMessage),
        failure: (e) =>
            showRungToast(context, arabicMessageForException(e), success: false),
      );
    }

    // Order matters: connected wins over any stale pending flag, and an
    // inbound request outranks the option to send one of your own.
    final (label, onPressed) = switch (profile) {
      Profile(connected: true) => (
        l10n.profileConnected,
        () => run(notifier.removeConnection, l10n.toastConnectionRemoved),
      ),
      Profile(connectionIncoming: true) => (
        l10n.profileConnectAccept,
        () => run(notifier.acceptConnection, l10n.toastConnectAccepted),
      ),
      Profile(connectionOutgoing: true) => (
        l10n.profileConnectSent,
        // Tapping again withdraws it — the same endpoint that removes an
        // accepted connection deletes a pending one.
        () => run(
          notifier.removeConnection,
          l10n.toastConnectRequestCancelled,
        ),
      ),
      _ => (
        l10n.profileConnect,
        () => run(
          notifier.connect,
          l10n.toastConnectRequestSent(person.firstName),
        ),
      ),
    };

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
      child: Text(label),
    );
  }
}
