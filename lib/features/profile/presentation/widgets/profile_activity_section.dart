import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/posts/domain/entities/comment.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_activity_notifier.dart';
import 'activity_post_card.dart';

/// The profile's activity card: what this person has posted and commented.
///
/// A horizontal rail rather than a list, because it sits above the CV and must
/// not push experience off the first screen. The full history is one tap away
/// behind a card.
class ProfileActivitySection extends ConsumerWidget {
  const ProfileActivitySection({
    super.key,
    required this.profile,
    required this.personId,
  });

  final Profile profile;

  /// The route id — `me` on your own profile. The activity providers are keyed
  /// by it so the section and the screen share one cache entry.
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // A company page is its feed — see the `asFeed` note below.
    final asFeed = profile.isCompany;

    // Both providers answer `AsyncValue<ProfileActivity>`, so only the source
    // changes. The distinction that matters is ownership: the rail's provider
    // is a fixed preview nothing can write to, while the feed's is a notifier
    // with like/repost/save on it.
    //
    // WATCHING it is what makes those actions work. `profileActivityFeedProvider`
    // is autoDispose, and a card that only ever did `ref.read(...notifier)`
    // created an element with no listeners — Riverpod disposed it at the end of
    // the frame, while its own build was still in flight, so at tap time the
    // state was still loading and every mutation returned before it left the
    // device. Two of them toasted success anyway.
    final activity = asFeed
        ? ref.watch(profileActivityFeedProvider(personId))
        : ref.watch(profileActivityProvider(personId));
    final tab = ref.watch(profileActivityTabProvider(personId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header and chips are padded; the post cards below are not. A
        // PostCard is full-bleed with its own gutter, so nesting it inside the
        // section's padding would indent every post twice.
        RungSection(
          gapBelow: 0,
          title: l10n.profileActivity,
          trailing: profile.isMe
              ? TextButton(
                  onPressed: () => context.push('/feed/composer'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.profileCreatePost),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileFollowersCount(
                  ArabicNumbers.count(profile.followerCount),
                ),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: RungSpace.sm),
              Row(
                children: [
                  _TabChip(
                    label: l10n.profileActivityPosts,
                    selected: tab == ProfileActivityTab.posts,
                    onTap: () => ref
                        .read(profileActivityTabProvider(personId).notifier)
                        .state = ProfileActivityTab.posts,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: l10n.profileActivityComments,
                    selected: tab == ProfileActivityTab.comments,
                    onTap: () => ref
                        .read(profileActivityTabProvider(personId).notifier)
                        .state = ProfileActivityTab.comments,
                  ),
                ],
              ),
            ],
          ),
        ),
        activity.when(
          loading: () => Container(
            color: c.surface,
            height: 96,
            child: const Center(child: CircularProgressIndicator()),
          ),
          // Secondary to the profile it sits on, so a failure shows nothing
          // rather than an error panel over someone's CV.
          error: (_, __) => _EmptyRow(label: l10n.profileSectionEmpty),
          data: (data) => _Preview(
            tab: tab,
            data: data,
            personId: personId,
            avatarUrl: profile.avatarUrl,
            // The rail exists to keep six posts from pushing experience,
            // education and skills off the first screen — and a company has
            // none of those: its page ends just below this, at the overview
            // and its open postings. So there is nothing for a rail to
            // protect, and a side-scrolling strip of clipped cards is a worse
            // way to read a company's posts than the list everywhere else in
            // the app uses.
            asFeed: asFeed,
          ),
        ),
        RungSection(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: TextButton(
              onPressed: () => context.push('/profile/$personId/activity'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.profileActivityShowAll),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_back, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How many entries the rail holds before "show all" takes over.
const int _kPreviewCount = 6;

/// One card's footprint in the rail.
///
/// Narrower than the screen so the next card peeks in — that sliver is what
/// tells you the rail scrolls, without needing an arrow. The height is fixed
/// because a rail of ragged cards reads as broken; a post taller than this is
/// cut off under a fade and opens in full on tap.
const double _kRailCardWidth = 300;
const double _kRailHeight = 260;

class _Preview extends StatelessWidget {
  const _Preview({
    required this.tab,
    required this.data,
    required this.personId,
    required this.avatarUrl,
    this.asFeed = false,
  });

  final ProfileActivityTab tab;
  final ProfileActivity data;
  final String personId;
  final String? avatarUrl;

  /// Renders the entries as a vertical feed rather than a horizontal rail —
  /// see the call site.
  final bool asFeed;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final showingPosts = tab == ProfileActivityTab.posts;

    final items = showingPosts
        ? [
            for (final post in data.posts.take(_kPreviewCount))
              ActivityPostCard(
                post: post,
                personId: personId,
                // A rail card is a preview and the whole card is one tap to
                // the post, so its actions would be a second target inside a
                // single one. In feed form the card is the real thing and
                // carries them, as it does everywhere else.
                showActions: asFeed,
              ),
          ]
        : [
            for (final comment in data.comments.take(_kPreviewCount))
              _CommentRow(comment: comment, avatarUrl: avatarUrl),
          ];

    if (items.isEmpty) return _EmptyRow(label: l10n.profileSectionEmpty);

    if (asFeed) {
      return Container(
        color: c.surface,
        padding: const EdgeInsets.only(bottom: RungSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              items[i],
            ],
          ],
        ),
      );
    }

    return Container(
      color: c.surface,
      padding: const EdgeInsets.only(bottom: RungSpace.sm),
      child: SizedBox(
        height: _kRailHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _RailCard(child: items[i]),
        ),
      ),
    );
  }
}

/// Holds one full-size card at rail dimensions.
class _RailCard extends StatelessWidget {
  const _RailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return SizedBox(
      width: _kRailCardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: RungRadius.mdAll,
          border: Border.all(color: c.line),
        ),
        child: ClipRRect(
          borderRadius: RungRadius.mdAll,
          child: Stack(
            children: [
              // The scroll view is what makes this safe: it hands the card
              // unbounded height, so a post longer than the rail is clipped
              // instead of raising an overflow. Scrolling is disabled — the
              // rail scrolls sideways, and a card that scrolled inside it
              // would fight the gesture.
              SizedBox(
                height: _kRailHeight,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: child,
                ),
              ),
              // Fades the cut so a clipped card reads as "there is more"
              // rather than as a rendering bug.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 36,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.surface.withValues(alpha: 0), c.surface],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: double.infinity,
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        0,
        RungSpace.gutter,
        RungSpace.sm,
      ),
      child: Text(label, style: TextStyle(fontSize: 13, color: c.ink3)),
    );
  }
}

/// A comment has no card of its own in the feed, so this is the one place its
/// shape is defined: what was said, and which post it hangs under.
class _CommentRow extends ConsumerWidget {
  const _CommentRow({required this.comment, required this.avatarUrl});

  final Comment comment;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => context.push('/feed/posts/${comment.postId}'),
      child: Container(
        width: double.infinity,
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(
          RungSpace.gutter,
          RungSpace.sm,
          RungSpace.gutter,
          RungSpace.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RungAvatar(
              seed: comment.authorId,
              initials: _monogram(comment.authorName),
              size: 34,
              imageUrl: ref.watch(imageUrlResolverProvider)(avatarUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.profileCommentedOn,
                          style: TextStyle(fontSize: 11.5, color: c.ink3),
                        ),
                      ),
                      Text(
                        relativeTimeArabic(comment.createdAt),
                        style: TextStyle(fontSize: 11.5, color: c.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: c.ink),
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RungRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accent : null,
          borderRadius: BorderRadius.circular(RungRadius.full),
          border: Border.all(color: selected ? c.accent : c.line2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : c.ink2,
          ),
        ),
      ),
    );
  }
}

/// First character of a name, for the small avatars on these cards. The
/// two-letter monogram `Person.initials` builds needs a Person; a card renders
/// straight off the post's denormalised author name.
String _monogram(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '؟' : trimmed.substring(0, 1);
}
