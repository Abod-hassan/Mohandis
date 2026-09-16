import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/posts/domain/entities/comment.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../notifiers/profile_activity_notifier.dart';
import '../widgets/activity_post_card.dart';

/// Everything one profile has posted and commented, paged.
///
/// The section on the profile shows a fixed preview; this is the whole history.
class ProfileActivityScreen extends ConsumerStatefulWidget {
  const ProfileActivityScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<ProfileActivityScreen> createState() =>
      _ProfileActivityScreenState();
}

class _ProfileActivityScreenState
    extends ConsumerState<ProfileActivityScreen> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    // Fetch ahead of the bottom so the next page is usually already there.
    final threshold = _controller.position.maxScrollExtent - 400;
    if (_controller.position.pixels < threshold) return;

    final notifier =
        ref.read(profileActivityFeedProvider(widget.personId).notifier);
    if (ref.read(profileActivityTabProvider(widget.personId)) ==
        ProfileActivityTab.posts) {
      notifier.loadMorePosts();
    } else {
      notifier.loadMoreComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(profileActivityFeedProvider(widget.personId));
    final tab = ref.watch(profileActivityTabProvider(widget.personId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.profileActivity),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              RungSpace.sm,
              RungSpace.gutter,
              RungSpace.sm,
            ),
            child: Row(
              children: [
                _Chip(
                  label: l10n.profileActivityPosts,
                  selected: tab == ProfileActivityTab.posts,
                  onTap: () => ref
                      .read(
                        profileActivityTabProvider(widget.personId).notifier,
                      )
                      .state = ProfileActivityTab.posts,
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: l10n.profileActivityComments,
                  selected: tab == ProfileActivityTab.comments,
                  onTap: () => ref
                      .read(
                        profileActivityTabProvider(widget.personId).notifier,
                      )
                      .state = ProfileActivityTab.comments,
                ),
              ],
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(
                  profileActivityFeedProvider(widget.personId),
                ),
              ),
              data: (data) {
                final showingPosts = tab == ProfileActivityTab.posts;
                final count =
                    showingPosts ? data.posts.length : data.comments.length;
                if (count == 0) {
                  return EmptyView(
                    title: l10n.emptyTitle,
                    icon: Icons.article_outlined,
                  );
                }
                return ListView.builder(
                  controller: _controller,
                  padding: const EdgeInsets.only(top: RungSpace.sm),
                  itemCount: count,
                  itemBuilder: (context, i) => showingPosts
                      // The same card the home feed renders — a post should not
                      // look like a different object depending on where it is
                      // being read.
                      ? ActivityPostCard(
                          post: data.posts[i],
                          personId: widget.personId,
                        )
                      : _CommentRow(comment: data.comments[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => context.push('/feed/posts/${comment.postId}'),
      child: Container(
        width: double.infinity,
        color: c.surface,
        padding: const EdgeInsets.all(RungSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mode_comment_outlined, size: 13, color: c.ink3),
                const SizedBox(width: 5),
                Text(
                  l10n.profileCommentedOn,
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
                const Spacer(),
                Text(
                  relativeTimeArabic(comment.createdAt),
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              comment.text,
              style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.postLikeWithCount(ArabicNumbers.count(comment.likeCount)),
              style: TextStyle(fontSize: 11.5, color: c.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
