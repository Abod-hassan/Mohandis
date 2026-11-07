import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/posts/domain/entities/post.dart';
import 'package:mohandis/features/posts/presentation/widgets/post_card.dart';
import 'package:mohandis/features/posts/presentation/widgets/post_options_sheet.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../notifiers/profile_activity_notifier.dart';

/// One post in a profile's activity, rendered with the SAME card the home feed
/// uses.
///
/// The wiring differs only in where the mutations land: these go through
/// [ProfileActivityFeed] so the activity list updates, rather than through
/// `FeedNotifier`, which owns a list this screen isn't showing.
class ActivityPostCard extends ConsumerWidget {
  const ActivityPostCard({
    super.key,
    required this.post,
    required this.personId,
    this.showActions = true,
  });

  final Post post;

  /// The activity list this card belongs to — the provider family key.
  final String personId;

  /// Off in the profile's rail, where the card is a preview: see [PostCard].
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Read inside the callbacks, not here. `profileActivityFeedProvider` is
    // autoDispose, so reading its notifier on every build of a card whose
    // actions are switched off created and threw away an element — and each one
    // fired a `byAuthor` + `commentsByAuthor` pair on the way out.
    ProfileActivityFeed notifier() =>
        ref.read(profileActivityFeedProvider(personId).notifier);
    // The post carries its author denormalised, so no directory lookup is
    // needed — and on an activity list every card has the same author anyway.
    // Still routed through `resolveAuthor`: this rail is mostly the viewer
    // looking at their own profile, where the inlined copy goes stale the
    // moment they change their photo.
    final author = resolveAuthor(ref, post.authorId, post.author);
    // In build, so the options sheet knows whose post this is the first time it
    // is opened — see the note in feed_screen.
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id;

    return PostCard(
      post: post,
      author: author,
      showActions: showActions,
      quoteAuthor: post.quoted == null
          ? null
          : Person(
              id: post.quoted!.authorId,
              name: post.quoted!.authorName,
              firstName: post.quoted!.authorName.split(RegExp(r'\s+')).first,
              headline: '',
              location: '',
            ),
      onOpen: () => context.push('/feed/posts/${post.id}'),
      onComment: () => context.push('/feed/posts/${post.id}'),
      onOpenAuthor: () => context.push('/profile/${author.id}'),
      onLike: () => notifier().toggleLike(post.id),
      // Already-reposted is a state, not an action — there is no un-share.
      onRepost: post.reposted
          ? null
          : () async {
              final ok = await notifier().toggleRepost(post.id);
              if (!context.mounted || !ok) return;
              showRungToast(context, l10n.toastReposted);
            },
      onMore: () => showPostOptions(
        context,
        ref,
        post: post,
        isMine: myId != null && myId == post.authorId,
        onChanged: (updated) => notifier().applyServerPost(updated),
        onDeleted: () => notifier().removePost(post.id),
      ),
      onSave: () async {
        final wasSaved = post.saved;
        final ok = await notifier().toggleSave(post.id);
        if (!context.mounted || !ok || wasSaved) return;
        showRungToast(context, l10n.toastSavedToItems);
      },
    );
  }
}
