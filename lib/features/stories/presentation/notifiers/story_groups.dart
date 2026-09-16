import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/story.dart';
import 'stories_notifier.dart';

/// One author's stories, as the rail and the viewer both see them.
///
/// The backend answers `POST /api/social/Stories` with a flat list of rows —
/// one per story, not one per person — so two stories from the same author
/// arrive as two rows. Rendering that list directly puts the same face on the
/// rail twice, which is what this type exists to stop.
class StoryGroup {
  const StoryGroup({required this.authorId, required this.stories});

  final String authorId;

  /// Oldest first, which is the order they are watched in.
  final List<Story> stories;

  /// The row the rail draws its avatar and name from. Any of them would do —
  /// the author fields are denormalised onto every row — so the first is as
  /// good as the last and does not change as new stories arrive.
  Story get cover => stories.first;

  /// The newest story's timestamp, which is what orders one group against
  /// another: a person who posted an hour ago belongs ahead of one who posted
  /// this morning, whatever their older stories say.
  DateTime get latestAt => stories.last.createdAt;

  /// A dimmed ring. The server never records an author's view of their own
  /// story, so a viewer's own group reads as unseen by design.
  bool get allSeen => stories.every((s) => s.seen);

  /// Where tapping the tile lands: the first story they have not watched, or
  /// the beginning again once they have watched them all. Picking up where
  /// they left off is the whole reason to group rather than to list.
  Story get entry {
    for (final story in stories) {
      if (!story.seen) return story;
    }
    return stories.first;
  }
}

/// The rail's stories, bucketed by author.
///
/// Derived rather than stored: [storiesNotifierProvider] stays the one list
/// that publishing, `markSeen` and refresh all write to, and this recomputes
/// from it. A second copy of the same rows would be a second thing to keep in
/// step with the seen flags.
final storyGroupsProvider = Provider<List<StoryGroup>>((ref) {
  final stories =
      ref.watch(storiesNotifierProvider).valueOrNull ?? const <Story>[];

  // Insertion-ordered, so a group's position starts from where its author
  // first appeared in the server's ordering rather than from a hash.
  final buckets = <String, List<Story>>{};
  for (final story in stories) {
    (buckets[story.authorId] ??= <Story>[]).add(story);
  }

  final groups = [
    for (final entry in buckets.entries)
      StoryGroup(
        authorId: entry.key,
        stories: entry.value
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      ),
  ];

  // Unseen first — the rail's job is to say who has something new — and newest
  // first within each half. `sort` is stable in Dart, but the comparator is
  // total anyway, so the result does not depend on that.
  groups.sort((a, b) {
    if (a.allSeen != b.allSeen) return a.allSeen ? 1 : -1;
    return b.latestAt.compareTo(a.latestAt);
  });
  return groups;
});

/// The group a given story belongs to, or null when the rail does not hold it.
///
/// The rail is scoped to followed authors and drops expired rows, so a story
/// opened from a notification or a shared link often is not in it — the viewer
/// falls back to reading that one story on its own.
StoryGroup? storyGroupFor(List<StoryGroup> groups, String storyId) {
  for (final group in groups) {
    for (final story in group.stories) {
      if (story.id == storyId) return group;
    }
  }
  return null;
}
