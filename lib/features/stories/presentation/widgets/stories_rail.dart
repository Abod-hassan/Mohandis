import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../notifiers/story_groups.dart';

/// Horizontal story rail at the top of the feed. Renders nothing but its own
/// height while loading so the feed below doesn't jump when stories land.
class StoriesRail extends ConsumerWidget {
  const StoriesRail({
    super.key,
    required this.onOpenStory,
    required this.onAddStory,
  });

  final void Function(String storyId) onOpenStory;
  final VoidCallback onAddStory;

  /// Tall enough for a 60px avatar, the 6px gap, and the label at the
  /// theme's maximum 1.3x text scale without the column overflowing.
  static const double _height = 116;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final groups = ref.watch(storyGroupsProvider);
    final meAsync = ref.watch(currentPersonProvider);
    final me = meAsync.valueOrNull;

    // The viewer's own stories are NOT a tile of their own. The server folds
    // them into the followed set, so left alone they render as a second face
    // beside "قصتك" — the same person, twice, one of them labelled "your
    // story". They belong on that tile, which grows a ring when there is
    // something on it.
    //
    // Telling them apart needs the viewer's ProfileId, and `me()` is its own
    // request racing the story read. Until it answers, the rail shows only
    // the "قصتك" tile: the alternative is to render the duplicate for a beat
    // and then reflow it away, which is the very bug this splits out. An
    // `me()` that FAILED is different — the id is not coming, and hiding
    // everybody's stories over it would be a worse answer than one repeated
    // face, so the groups render unsplit.
    StoryGroup? mine;
    final others = <StoryGroup>[];
    if (me != null) {
      for (final group in groups) {
        if (group.authorId == me.id) {
          mine = group;
        } else {
          others.add(group);
        }
      }
    } else if (meAsync.hasError) {
      others.addAll(groups);
    }

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(RungSpace.gutter, 14, RungSpace.gutter, 12),
        children: [
          _AddStoryTile(
            me: me,
            mine: mine,
            onAdd: onAddStory,
            onOpen: mine == null ? null : () => onOpenStory(mine!.entry.id),
          ),
          for (final group in others)
            _StoryTile(
              // The backend inlines the author on every story row; the
              // directory is the richer record when it happens to hold this
              // person, and it is paged, so it often does not.
              person: resolveAuthor(ref, group.authorId, group.cover.author),
              seed: group.authorId,
              seen: group.allSeen,
              // One tap per PERSON, landing on the first story of theirs that
              // has not been watched — the viewer walks the rest.
              onTap: () => onOpenStory(group.entry.id),
            ),
        ],
      ),
    );
  }
}

/// "قصتك" — the add affordance, and the viewer's own stories when they have
/// any.
///
/// Two targets in one slot: the avatar opens what they have posted, the "+"
/// badge posts another. Tapping the avatar with nothing there falls through to
/// adding, so the tile is never a dead end.
class _AddStoryTile extends ConsumerWidget {
  const _AddStoryTile({
    required this.me,
    required this.mine,
    required this.onAdd,
    required this.onOpen,
  });

  final Person? me;

  /// The viewer's own group, or null when they have posted nothing live.
  final StoryGroup? mine;

  final VoidCallback onAdd;

  /// Null when there is nothing of theirs to open.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final group = mine;
    final avatar = RungAvatar(
      seed: me?.id ?? 'me',
      initials: me?.initials ?? '—',
      icon: me?.accountType.icon,
      // Ringed at the tile's full size when there is something to watch, and
      // inset inside the dashed placeholder when there is not — so "you have a
      // story" and "you could post one" are not the same picture.
      size: group == null ? 44 : 55,
      ringState: group == null
          ? StoryRingState.none
          : (group.allSeen ? StoryRingState.seen : StoryRingState.unseen),
      imageUrl: ref.watch(imageUrlResolverProvider)(me?.avatarUrl),
    );

    return _RailSlot(
      label: context.l10n.feedYourStory,
      onTap: onOpen ?? onAdd,
      avatar: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (group == null)
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line2, width: 2),
                ),
                child: avatar,
              )
            else
              avatar,
            PositionedDirectional(
              // INSIDE the 60px box, not hanging off it. A hit outside a
              // RenderBox is rejected however the stack is clipped, so the
              // old -6 offset would have left three quarters of this badge
              // untappable — and the tap would have fallen through to the
              // slot behind it, which now opens the story instead of adding.
              // Flush with the 60px box, never hanging off it: a hit outside
              // a RenderBox is rejected however the stack is clipped, so an
              // overhanging target is a target that is partly not there.
              bottom: 0,
              start: 0,
              // Its own target: with a story on the tile the avatar opens it,
              // and without this badge there would be no way left to post a
              // second one.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAdd,
                // The badge DRAWS at 22px and is TAPPED at 40. Once there is a
                // story on this tile the slot behind it opens that story, so
                // every near-miss on a 22px circle would open the thing the
                // person was trying to add to — and this badge is the only way
                // left to post a second one.
                // The 40px box grows INWARD from the corner and the badge
                // stays pinned to that corner, so the target quadruples
                // without the badge moving a pixel.
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTile extends ConsumerWidget {
  const _StoryTile({
    required this.person,
    required this.seed,
    required this.seen,
    required this.onTap,
  });

  final Person person;
  final String seed;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = person.firstName;
    return _RailSlot(
      // A story whose author the directory missed and whose payload predates
      // the inlined name has nothing to label the slot with.
      label: name.isEmpty ? '…' : name,
      onTap: onTap,
      avatar: RungAvatar(
        seed: seed,
        initials: person.initials,
        icon: person.accountType.icon,
        size: 55,
        ringState: seen ? StoryRingState.seen : StoryRingState.unseen,
        imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
      ),
    );
  }
}

class _RailSlot extends StatelessWidget {
  const _RailSlot({
    required this.avatar,
    required this.label,
    required this.onTap,
  });

  final Widget avatar;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 60, child: Center(child: avatar)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
