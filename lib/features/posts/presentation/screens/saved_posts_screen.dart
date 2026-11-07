import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../notifiers/saved_posts_notifier.dart';
import '../widgets/post_card.dart';
import '../widgets/post_options_sheet.dart';

/// The posts this person bookmarked.
///
/// Deliberately NOT built on `feedNotifierProvider`: that notifier owns the
/// home feed's list and its cursors, and pushing a different query through it
/// would replace the feed the person goes back to. This list owns its own
/// reads, and un-saving here removes the row locally rather than re-fetching
/// the whole list for one removal.
class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final saved = ref.watch(savedPostsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.savedPostsTitle),
      body: saved.when(
        loading: () => const PostListSkeleton(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(savedPostsProvider),
        ),
        data: (posts) => posts.isEmpty
            ? EmptyView(
                title: l10n.savedPostsEmpty,
                icon: Icons.bookmark_border,
              )
            : RefreshIndicator(
                onRefresh: () => pullRefresh(ref.refresh(savedPostsProvider.future)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => _SavedRow(post: posts[i]),
                ),
              ),
      ),
    );
  }
}

class _SavedRow extends ConsumerWidget {
  const _SavedRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = resolveAuthor(ref, post.authorId, post.author);
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id;

    return PostCard(
      post: post,
      author: author,
      onOpen: () => context.push('/feed/posts/${post.id}'),
      onComment: () => context.push('/feed/posts/${post.id}'),
      onOpenAuthor: () => context.push('/profile/${author.id}'),
      // Like and repost are left to the post's own screen here. This list is
      // for finding something again, and a card that can be liked but whose
      // count comes from a separate read would drift from the feed's copy of
      // the same post.
      onSave: () => _unsave(context, ref),
      onMore: () => showPostOptions(
        context,
        ref,
        post: post,
        isMine: myId != null && myId == post.authorId,
        // This list IS the saved list, so any of these changes it: an edit
        // rewrites the row, a delete removes it, and unsaving takes it off the
        // list the screen is showing. The home feed is told as well — it holds
        // its rows for the whole session, so without this a post deleted here
        // is still tappable there, and an edited one still reads as it did.
        onChanged: (updated) {
          ref.read(feedNotifierProvider.notifier).applyServerPost(updated);
          ref.invalidate(savedPostsProvider);
        },
        onDeleted: () {
          ref.read(feedNotifierProvider.notifier).removePost(post.id);
          ref.invalidate(savedPostsProvider);
        },
        onSaveToggled: () => ref.invalidate(savedPostsProvider),
      ),
    );
  }

  Future<void> _unsave(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(postRepositoryProvider).toggleSave(post.id);
    if (!context.mounted) return;
    result.when(
      success: (updated) {
        // Only a row that came back UNSAVED leaves. The endpoint is a toggle,
        // so a double-tap that re-saves it must not remove it from the list it
        // now belongs on again.
        if (!updated.saved) ref.invalidate(savedPostsProvider);
      },
      failure: (AppException e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }
}
