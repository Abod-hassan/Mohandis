import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:flutter_mobile_template/features/messaging/presentation/notifiers/messaging_notifier.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/features/stories/presentation/widgets/stories_rail.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final feed = ref.watch(feedNotifierProvider);
    final directory = ref.watch(peopleDirectoryProvider).valueOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _FeedTopBar(),
            Expanded(
              child: feed.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.read(feedNotifierProvider.notifier).refresh(),
                ),
                data: (posts) => RefreshIndicator(
                  onRefresh: () =>
                      ref.read(feedNotifierProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: RungSpace.lg),
                    itemCount: posts.length + 3,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StoriesRail(
                          onOpenStory: (id) => context.push('/feed/stories/$id'),
                          // The rail's "+" said story and opened a post
                          // composer. It now opens the one it promised.
                          onAddStory: () =>
                              context.push('/feed/composer?mode=story'),
                        );
                      }
                      if (index == 1) return const _ComposerEntry();
                      if (index == posts.length + 2) return const _CaughtUp();

                      final post = posts[index - 2];
                      // Prefetch two cards from the end rather than at it, so
                      // the next page is usually already in when the user
                      // reaches the bottom.
                      if (index >= posts.length) {
                        // After the frame, never during it — loadMore moves
                        // notifier state, and mutating it mid-build throws.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(feedNotifierProvider.notifier).loadMore();
                        });
                      }
                      return _FeedPost(post: post, directory: directory);
                    },
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

class _FeedPost extends ConsumerWidget {
  const _FeedPost({required this.post, required this.directory});

  final Post post;
  final Map<String, Person>? directory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The backend inlines the author on every post and feed row, so a card
    // never has to wait for — or be dropped because of — a directory lookup.
    // The directory entry is still preferred when there is one: it carries the
    // headline and location a post payload doesn't.
    //
    // The viewer's own record wins over both — see `resolveAuthor`.
    final author = resolveAuthor(ref, post.authorId, post.author);

    final jobs = ref.watch(jobsDirectoryProvider).valueOrNull;
    final job = post.jobId == null ? null : jobs?[post.jobId];
    final l10n = context.l10n;
    final notifier = ref.read(feedNotifierProvider.notifier);

    return PostCard(
      post: post,
      author: author,
      repostedBy:
          post.repostedById == null ? null : directory?[post.repostedById!],
      quoteAuthor: post.quoted == null
          ? null
          : directory?[post.quoted!.authorId] ??
                Person(
                  id: post.quoted!.authorId,
                  name: post.quoted!.authorName,
                  firstName: post.quoted!.authorName
                      .split(RegExp(r'\s+'))
                      .first,
                  headline: '',
                  location: '',
                ),
      jobEmbed: job == null
          ? null
          : PostJobEmbed(
              id: job.id,
              title: job.title,
              company: job.company,
              location: job.location,
              monogram: job.monogram,
            ),
      onOpen: () => context.push('/feed/posts/${post.id}'),
      onComment: () => context.push('/feed/posts/${post.id}'),
      onOpenAuthor: () => context.push('/profile/${author.id}'),
      onOpenJob: job == null ? null : () => context.push('/jobs/${job.id}'),
      onLike: () => notifier.toggleLike(post.id),
      onRepost: () async {
        final wasReposted = post.reposted;
        final result = await notifier.toggleRepost(post.id);
        if (!context.mounted) return;
        result.when(
          success: (_) {
            if (!wasReposted) showRungToast(context, l10n.toastReposted);
          },
          failure: (e) => showRungToast(
            context,
            arabicMessageForException(e),
            success: false,
          ),
        );
      },
      onSave: () async {
        final wasSaved = post.saved;
        final result = await notifier.toggleSave(post.id);
        if (!context.mounted) return;
        result.when(
          success: (_) {
            if (!wasSaved) showRungToast(context, l10n.toastSavedToItems);
          },
          failure: (e) => showRungToast(
            context,
            arabicMessageForException(e),
            success: false,
          ),
        );
      },
    );
  }
}

class _FeedTopBar extends ConsumerWidget {
  const _FeedTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final me = ref.watch(currentPersonProvider).valueOrNull;
    // Was hardcoded on — a red dot every user saw forever, unread or not.
    final unread = ref.watch(unreadThreadCountProvider);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/me'),
            child: RungAvatar(
              seed: me?.id ?? 'me',
              initials: me?.initials ?? '—',
              size: 34,
              imageUrl: ref.watch(imageUrlResolverProvider)(me?.avatarUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RungSearchField(
              hint: context.l10n.topBarSearchHint,
              height: 38,
              onTap: () => context.push('/search'),
            ),
          ),
          const SizedBox(width: 12),
          RungIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: context.l10n.messagesTitle,
            onPressed: () => context.push('/messages'),
            badge: unread > 0 ? const _UnreadDot() : null,
          ),
        ],
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: c.red,
        shape: BoxShape.circle,
        border: Border.all(color: c.surface, width: 2),
      ),
    );
  }
}

class _ComposerEntry extends ConsumerWidget {
  const _ComposerEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final me = ref.watch(currentPersonProvider).valueOrNull;
    void open() => context.push('/feed/composer');

    return Container(
      color: c.surface,
      margin: const EdgeInsets.only(bottom: RungSpace.sectionGap),
      padding: const EdgeInsets.symmetric(
        horizontal: RungSpace.gutter,
        vertical: RungSpace.sm,
      ),
      child: Row(
        children: [
          RungAvatar(
            seed: me?.id ?? 'me',
            initials: me?.initials ?? '—',
            size: 38,
            imageUrl: ref.watch(imageUrlResolverProvider)(me?.avatarUrl),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: GestureDetector(
              onTap: open,
              child: Container(
                height: 40,
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: RungRadius.pill,
                  border: Border.all(color: c.line),
                ),
                child: Text(
                  context.l10n.feedComposerHint,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.ink3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          RungIconButton(
            icon: Icons.image_outlined,
            onPressed: open,
            size: 40,
            radius: 12,
            background: c.accentSoft,
            foreground: c.accent,
            tooltip: context.l10n.composerTitle,
          ),
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Text(
        context.l10n.feedCaughtUp,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: context.rung.ink3,
        ),
      ),
    );
  }
}
