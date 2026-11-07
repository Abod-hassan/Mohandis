import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../notifiers/saved_posts_notifier.dart';
import '../widgets/post_card.dart';
import '../widgets/post_options_sheet.dart';

/// Every post carrying one hashtag, newest first.
///
/// Reached from a tag in search, or from a tag under any post. Owns its own
/// list like the saved-posts screen does, rather than pushing a filter through
/// the home feed's notifier — that would replace the feed the person goes
/// back to.
class HashtagPostsScreen extends ConsumerWidget {
  const HashtagPostsScreen({super.key, required this.tag});

  /// Without the `#`.
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final posts = ref.watch(hashtagPostsProvider(tag));

    return Scaffold(
      backgroundColor: c.bg,
      // LTR isolate: a Latin tag in an RTL title would otherwise render
      // its `#` on the wrong side.
      appBar: RungAppBar(title: '⁨#$tag⁩'),
      body: posts.when(
        loading: () => const PostListSkeleton(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(hashtagPostsProvider(tag)),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(title: l10n.hashtagPostsEmpty, icon: Icons.tag)
            : RefreshIndicator(
                onRefresh: () =>
                    pullRefresh(ref.refresh(hashtagPostsProvider(tag).future)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _TagPostRow(post: list[i], tag: tag),
                ),
              ),
      ),
    );
  }
}

class _TagPostRow extends ConsumerWidget {
  const _TagPostRow({required this.post, required this.tag});

  final Post post;
  final String tag;

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
      onMore: () => showPostOptions(
        context,
        ref,
        post: post,
        isMine: myId != null && myId == post.authorId,
        onChanged: (updated) {
          ref.read(feedNotifierProvider.notifier).applyServerPost(updated);
          ref.invalidate(hashtagPostsProvider(tag));
        },
        onDeleted: () {
          ref.read(feedNotifierProvider.notifier).removePost(post.id);
          ref.invalidate(hashtagPostsProvider(tag));
        },
        onSaveToggled: () => ref.invalidate(hashtagPostsProvider(tag)),
      ),
    );
  }
}
