import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../notifiers/post_detail_notifier.dart';
import '../widgets/post_card.dart';
import '../widgets/post_document_list.dart';
import '../widgets/post_media_grid.dart';
import '../widgets/post_visibility_label.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final result = await ref
        .read(postDetailNotifierProvider(widget.postId).notifier)
        .addComment(text);
    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) => _commentController.clear(),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final state = ref.watch(postDetailNotifierProvider(widget.postId));

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(title: context.l10n.postDetailTitle),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref
              .read(postDetailNotifierProvider(widget.postId).notifier)
              .refresh(),
        ),
        data: (post) => _Body(
          post: post,
          controller: _commentController,
          sending: _sending,
          onSubmitComment: _submitComment,
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.post,
    required this.controller,
    required this.sending,
    required this.onSubmitComment,
  });

  final Post post;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmitComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // Falls back to the author the backend inlines on the post itself, so the
    // header renders even when the directory hasn't loaded this person — and
    // prefers the viewer's own live record over both. See `resolveAuthor`.
    final author = resolveAuthor(ref, post.authorId, post.author);
    final notifier =
        ref.read(postDetailNotifierProvider(post.id).notifier);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _AuthorHeader(post: post, author: author),
              if (post.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    RungSpace.sm,
                    RungSpace.gutter,
                    0,
                  ),
                  child: Text(
                    post.text,
                    style: TextStyle(fontSize: 15, height: 1.55, color: c.ink),
                  ),
                ),
              if (post.hasTags)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    8,
                    RungSpace.gutter,
                    0,
                  ),
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    children: [
                      for (final tag in post.tags) RungHashtag(tag: tag),
                    ],
                  ),
                ),
              if (post.hasPictures)
                Padding(
                  padding: const EdgeInsets.only(top: RungSpace.sm),
                  child: PostMediaGrid(media: post.media),
                ),
              PostDocumentList(media: post.media),
              Container(
                padding: const EdgeInsets.all(RungSpace.sm),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.postLikesCount(ArabicNumbers.count(post.likeCount)),
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                    Text(
                      l10n.postRepostsCount(
                        ArabicNumbers.count(post.repostCount),
                      ),
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                margin: const EdgeInsets.only(bottom: RungSpace.sectionGap),
                color: c.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: PostAction(
                        icon: post.liked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        label: l10n.postActionLike,
                        color: post.liked ? c.accent : c.ink2,
                        onTap: notifier.toggleLike,
                      ),
                    ),
                    Expanded(
                      child: PostAction(
                        icon: Icons.mode_comment_outlined,
                        label: l10n.postActionComment,
                        color: c.ink2,
                        onTap: () => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    Expanded(
                      child: PostAction(
                        icon: Icons.repeat_rounded,
                        label: l10n.postActionRepost,
                        color: post.reposted ? c.green : c.ink2,
                        // Green means already reposted, and there is nothing
                        // to undo it with — see PostCard.
                        onTap: post.reposted ? null : notifier.toggleRepost,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RungSpace.gutter,
                  RungSpace.sm,
                  RungSpace.gutter,
                  6,
                ),
                child: Text(
                  l10n.postCommentsCount(
                    ArabicNumbers.count(post.commentCount),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final comment in post.comments)
                _CommentTile(comment: comment, postId: post.id),
              const SizedBox(height: RungSpace.md),
            ],
          ),
        ),
        _CommentComposer(
          controller: controller,
          sending: sending,
          onSubmit: onSubmitComment,
        ),
      ],
    );
  }
}

class _AuthorHeader extends ConsumerWidget {
  const _AuthorHeader({required this.post, required this.author});

  final Post post;
  final Person author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        14,
        RungSpace.gutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${author.id}'),
            child: RungAvatar(
              seed: author.id,
              initials: author.initials,
              imageUrl: ref.watch(imageUrlResolverProvider)(author.avatarUrl),
              size: 44,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (author.verified) ...[
                      const SizedBox(width: 5),
                      const VerifiedBadge(),
                    ],
                  ],
                ),
                Text(
                  author.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.ink2),
                ),
                Text(
                  '${relativeTimeArabic(post.createdAt)} · '
                  '${post.visibility.label(context)}',
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    required this.comment,
    required this.postId,
    this.isReply = false,
  });

  final Comment comment;

  /// The family argument for [postDetailNotifierProvider] — a reply knows its
  /// parent comment, not the post it hangs under.
  final String postId;

  final bool isReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final author = resolveAuthor(ref, comment.authorId, comment.author);
    final avatarSize = isReply ? 30.0 : 36.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isReply ? 0 : RungSpace.gutter,
        isReply ? 8 : 8,
        isReply ? 0 : RungSpace.gutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RungAvatar(
            seed: comment.authorId,
            initials: author.initials,
            // `author` already falls back to `comment.author`, whose
            // avatarUrl IS `authorAvatarUrl` — so this keeps the fallback while
            // preferring the fresher record when there is one. Reading the
            // inlined copy directly would pair a refreshed name with an old
            // photo after the viewer changes theirs.
            imageUrl: ref.watch(imageUrlResolverProvider)(author.avatarUrl),
            size: avatarSize,
          ),
          SizedBox(width: isReply ? 9 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isReply ? 12 : 13,
                    vertical: isReply ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    // Flat corner points at the avatar, which sits on the
                    // right in RTL.
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(4),
                      topLeft: Radius.circular(isReply ? 12 : 14),
                      bottomLeft: Radius.circular(isReply ? 12 : 14),
                      bottomRight: Radius.circular(isReply ? 12 : 14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: TextStyle(
                          fontSize: isReply ? 12.5 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // A comment payload carries no headline, so this only
                      // renders for authors resolved through the directory.
                      if (!isReply && author.headline.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            author.headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.ink3),
                          ),
                        ),
                      Text(
                        comment.text,
                        style: TextStyle(
                          fontSize: isReply ? 13 : 13.5,
                          height: 1.45,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Row(
                    children: [
                      Text(
                        relativeTimeArabic(comment.createdAt),
                        style: _metaStyle(c.ink3),
                      ),
                      const SizedBox(width: 16),
                      // Was plain text: the count rendered, but there was
                      // nothing to tap, so `Comments/Like` was never called
                      // from anywhere in the app.
                      InkWell(
                        onTap: () async {
                          final result = await ref
                              .read(postDetailNotifierProvider(postId).notifier)
                              .toggleCommentLike(comment.id);
                          if (!context.mounted) return;
                          result.when(
                            success: (_) {},
                            failure: (e) => showRungToast(
                              context,
                              arabicMessageForException(e),
                              success: false,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Text(
                            context.l10n.postLikeWithCount(
                              ArabicNumbers.count(comment.likeCount),
                            ),
                            style: _metaStyle(
                              comment.liked ? c.accent : c.ink3,
                            ),
                          ),
                        ),
                      ),
                      if (!isReply) ...[
                        const SizedBox(width: 16),
                        Text(context.l10n.postReply, style: _metaStyle(c.ink3)),
                      ],
                    ],
                  ),
                ),
                for (final reply in comment.replies)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: _CommentTile(
                      comment: reply,
                      postId: postId,
                      isReply: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _metaStyle(Color color) => TextStyle(
        fontSize: isReply ? 11 : 11.5,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

class _CommentComposer extends ConsumerWidget {
  const _CommentComposer({
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final me = ref.watch(currentPersonProvider).valueOrNull;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RungSpace.sm, vertical: 9),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            RungAvatar(
              seed: me?.id ?? 'me',
              initials: me?.initials ?? '—',
              imageUrl: ref.watch(imageUrlResolverProvider)(me?.avatarUrl),
              size: 32,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: RungRadius.pill,
                  border: Border.all(color: c.line),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  style: TextStyle(fontSize: 13, color: c.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: context.l10n.postAddComment,
                    hintStyle: TextStyle(fontSize: 13, color: c.ink3),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: sending ? null : onSubmit,
              icon: sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              color: c.accent,
              tooltip: context.l10n.actionSend,
            ),
          ],
        ),
      ),
    );
  }
}
