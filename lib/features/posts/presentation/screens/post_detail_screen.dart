import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import 'package:mohandis/features/shared/moderation/report_sheet.dart';

import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../notifiers/post_detail_notifier.dart';
import '../widgets/mention_suggestions.dart';
import '../widgets/mention_text.dart';
import '../widgets/post_card.dart';
import '../widgets/post_options_sheet.dart';
import '../widgets/post_document_list.dart';
import '../widgets/post_media_grid.dart';
import '../widgets/post_poll.dart';
import '../widgets/post_visibility_label.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  /// The comment being answered, while the composer is in reply mode.
  Comment? _replyTo;

  /// The `@handle ` put in front of the text for [_replyTo], so switching
  /// target or cancelling can take back exactly what was added.
  String _replyPrefix = '';

  @override
  void initState() {
    super.initState();
    // Rebuilds the mention strip as the caret moves through an @token.
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  /// Strips the previous reply's `@handle ` if it is still at the front.
  String _withoutReplyPrefix(String text) =>
      _replyPrefix.isNotEmpty && text.startsWith(_replyPrefix)
          ? text.substring(_replyPrefix.length)
          : text;

  void _setText(String text) {
    _commentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Puts the composer in reply mode for [comment] and pre-fills its author's
  /// handle — that `@handle` is what makes the server notify them by name,
  /// and it tells a reader of a flattened thread who is being answered.
  void _startReply(Comment comment) {
    final body = _withoutReplyPrefix(_commentController.text);
    final me = ref.read(currentPersonProvider).valueOrNull;
    final handle = comment.authorUsername?.trim() ?? '';
    final prefix =
        handle.isNotEmpty && comment.authorId != me?.id ? '@$handle ' : '';

    setState(() {
      _replyTo = comment;
      _replyPrefix = prefix;
    });
    _setText(prefix + body);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    final body = _withoutReplyPrefix(_commentController.text);
    setState(() {
      _replyTo = null;
      _replyPrefix = '';
    });
    _setText(body);
  }

  /// Replaces the `@token` under the caret with the picked handle.
  void _applyMention(String username) {
    final value = _commentController.value;
    final caret = value.selection.isValid
        ? value.selection.baseOffset
        : value.text.length;
    final query = MentionQuery.at(value.text, caret);
    if (query == null) return;
    final insert = '@$username ';
    final next = value.text.replaceRange(query.start, query.end, insert);
    _commentController.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: query.start + insert.length),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    // Only the pre-filled handle and nothing said: not worth posting.
    if (_replyPrefix.isNotEmpty && text == _replyPrefix.trim()) return;

    setState(() => _sending = true);
    final result = await ref
        .read(postDetailNotifierProvider(widget.postId).notifier)
        .addComment(text, parentCommentId: _replyTo?.id);
    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) {
        _commentController.clear();
        setState(() {
          _replyTo = null;
          _replyPrefix = '';
        });
      },
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
        loading: () => const DetailSkeleton(hasHero: false, paragraphs: 2),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref
              .read(postDetailNotifierProvider(widget.postId).notifier)
              .refresh(),
        ),
        data: (post) => _Body(
          post: post,
          controller: _commentController,
          focusNode: _focusNode,
          sending: _sending,
          onSubmitComment: _submitComment,
          replyTo: _replyTo,
          onReply: _startReply,
          onCancelReply: _cancelReply,
          onMention: _applyMention,
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.post,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSubmitComment,
    required this.replyTo,
    required this.onReply,
    required this.onCancelReply,
    required this.onMention,
  });

  final Post post;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSubmitComment;
  final Comment? replyTo;
  final ValueChanged<Comment> onReply;
  final VoidCallback onCancelReply;
  final ValueChanged<String> onMention;

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
                  child: MentionText(
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
                      for (final tag in post.tags)
                        RungHashtag(
                          tag: tag,
                          onTap: () => context.push(
                            '/hashtags/${Uri.encodeComponent(tag.replaceFirst('#', ''))}',
                          ),
                        ),
                    ],
                  ),
                ),
              if (post.poll != null)
                PostPoll(postId: post.id, poll: post.poll!),
              if (post.hasPictures)
                Padding(
                  padding: const EdgeInsets.only(top: RungSpace.sm),
                  child: PostMediaGrid(media: post.media),
                ),
              PostDocumentList(media: post.media),
              // The original, for a repost or a quote. Missing here before, so
              // a plain repost — no text or media of its own — opened onto an
              // author header and nothing else, while the feed showed the
              // original under it.
              if (post.quoted != null)
                QuotedPostEmbed(
                  quote: post.quoted!,
                  author: resolveAuthor(
                    ref,
                    post.quoted!.authorId,
                    Person(
                      id: post.quoted!.authorId,
                      name: post.quoted!.authorName,
                      firstName:
                          post.quoted!.authorName.split(RegExp(r'\s+')).first,
                      avatarUrl: post.quoted!.authorAvatarUrl,
                      headline: '',
                      location: '',
                    ),
                  ),
                ),
              if (post.originalUnavailable) const OriginalUnavailableNotice(),
              if (post.quoted != null || post.originalUnavailable)
                const SizedBox(height: RungSpace.sm),
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
                _CommentTile(
                  comment: comment,
                  postId: post.id,
                  onReply: onReply,
                ),
              const SizedBox(height: RungSpace.md),
            ],
          ),
        ),
        // Between the thread and the input, where the thumb already is.
        // Renders nothing until an @token with two letters is under the caret.
        MentionSuggestions(
          query: MentionQuery.at(
            controller.text,
            controller.selection.isValid
                ? controller.selection.baseOffset
                : controller.text.length,
          ),
          onSelected: (person) => onMention(person.username.trim()),
        ),
        _CommentComposer(
          controller: controller,
          focusNode: focusNode,
          sending: sending,
          onSubmit: onSubmitComment,
          replyTo: replyTo,
          onCancelReply: onCancelReply,
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
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id;
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
              icon: author.accountType.icon,
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
                    NameBadges(
                      verified: author.verified,
                      subscribed: author.subscribed,
                    ),
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
          // The same options the feed card carries. Deleting from here has
          // nowhere to stay, so the screen pops.
          IconButton(
            onPressed: () => showPostOptions(
              context,
              ref,
              post: post,
              isMine: myId != null && myId == post.authorId,
              // This screen first — `applyServerPost` mirrors into the feed
              // itself, so the row and the page it came from agree.
              onChanged: (updated) => ref
                  .read(postDetailNotifierProvider(post.id).notifier)
                  .applyServerPost(updated),
              onDeleted: () {
                ref.read(feedNotifierProvider.notifier).removePost(post.id);
                // The family is not autoDispose, so without this the deleted
                // post stays cached under its id and any later route back to
                // it — a quote embed, a mention, a search hit — would render
                // it in full with buttons that cannot work.
                ref.invalidate(postDetailNotifierProvider(post.id));
                if (context.canPop()) context.pop();
              },
            ),
            icon: const Icon(Icons.more_horiz),
            iconSize: 20,
            color: c.ink3,
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
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
    required this.onReply,
    this.isReply = false,
  });

  final Comment comment;
  final ValueChanged<Comment> onReply;

  /// The family argument for [postDetailNotifierProvider] — a reply knows its
  /// parent comment, not the post it hangs under.
  final String postId;

  final bool isReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final author = resolveAuthor(ref, comment.authorId, comment.author);
    final avatarSize = isReply ? 30.0 : 36.0;
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id;
    final isMine =
        myId != null && myId.toLowerCase() == comment.authorId.toLowerCase();

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
            icon: author.accountType.icon,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isReply ? 12.5 : 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          NameBadges(
                            verified: author.verified,
                            subscribed: author.subscribed,
                            size: 12,
                          ),
                        ],
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
                      MentionText(
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
                      const SizedBox(width: 16),
                      // On replies too: answering a reply threads under the
                      // same top-level comment and notifies that reply's
                      // author, not the thread starter.
                      InkWell(
                        onTap: () => onReply(comment),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Text(
                            context.l10n.postReply,
                            style: _metaStyle(c.ink3),
                          ),
                        ),
                      ),
                      // Somebody else's comment can be reported (App Store
                      // guideline 1.2); there is nothing to report on your own.
                      if (!isMine) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => showReportSheet(
                            context,
                            target: ReportTarget.comment,
                            targetId: comment.id,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Text(
                              context.l10n.actionReport,
                              style: _metaStyle(c.ink3),
                            ),
                          ),
                        ),
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
                      onReply: onReply,
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
    required this.focusNode,
    required this.sending,
    required this.onSubmit,
    required this.replyTo,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSubmit;
  final Comment? replyTo;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final me = ref.watch(currentPersonProvider).valueOrNull;

    final target = replyTo;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RungSpace.sm, vertical: 9),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (target != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 6),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 16, color: c.ink3),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.postReplyingTo(
                          resolveAuthor(ref, target.authorId, target.author)
                              .name,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.ink2,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onCancelReply,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: c.ink3,
                          semanticLabel: context.l10n.postCancelReply,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                RungAvatar(
                  seed: me?.id ?? 'me',
                  initials: me?.initials ?? '—',
                  icon: me?.accountType.icon,
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
                      focusNode: focusNode,
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
                        hintText: target != null
                            ? context.l10n.postWriteReply
                            : context.l10n.postAddComment,
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
          ],
        ),
      ),
    );
  }
}
