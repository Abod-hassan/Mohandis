import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../notifiers/saved_posts_notifier.dart';
import '../widgets/post_card.dart';

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
        loading: () => const LoadingView(),
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
                onRefresh: () async => ref.invalidate(savedPostsProvider),
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
