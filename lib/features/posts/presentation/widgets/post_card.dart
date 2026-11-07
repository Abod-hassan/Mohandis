import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../notifiers/suggested_action_notifier.dart';
import '../../domain/entities/post.dart';
import 'mention_text.dart';
import 'post_document_list.dart';
import 'post_media_grid.dart';
import 'post_poll.dart';
import 'post_visibility_label.dart';

/// Minimal job preview the feed needs to render a shared-job embed. The jobs
/// feature owns the full entity; the card only ever needs these four fields,
/// so it takes this instead of depending on the jobs domain.
class PostJobEmbed {
  const PostJobEmbed({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.monogram,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String monogram;
}

/// The feed's post card. Every optional block — repost banner, tags, media,
/// quote embed, job embed — collapses to nothing when its data is absent.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.author,
    this.repostedBy,
    this.quoteAuthor,
    this.jobEmbed,
    this.onOpen,
    this.onOpenAuthor,
    this.onOpenJob,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onSave,
    this.onMore,
    this.showActions = true,
  });

  final Post post;
  final Person author;

  /// Set when the post surfaced because someone in the network reposted it.
  final Person? repostedBy;

  final Person? quoteAuthor;
  final PostJobEmbed? jobEmbed;

  final VoidCallback? onOpen;
  final VoidCallback? onOpenAuthor;
  final VoidCallback? onOpenJob;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onSave;
  final VoidCallback? onMore;

  /// Whether to draw the like / comment / repost / save row.
  ///
  /// Off where the card is a preview rather than the thing itself — the
  /// profile's activity rail shows the same card at 300px, and a row of
  /// actions there competes with the tap that opens the post.
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      color: c.surface,
      margin: const EdgeInsets.only(bottom: RungSpace.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Above the repost banner, because it is the more surprising fact:
          // "you are seeing this because we picked it" outranks "someone
          // reposted it".
          if (post.suggested) const _SuggestedBanner(),
          if (repostedBy != null) _RepostBanner(name: repostedBy!.name),
          _Header(
            author: author,
            post: post,
            onOpenAuthor: onOpenAuthor,
            onMore: onMore,
          ),
          if (post.text.isNotEmpty)
            GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RungSpace.gutter,
                  10,
                  RungSpace.gutter,
                  0,
                ),
                child: MentionText(
                  post.text,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: c.ink,
                  ),
                ),
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
                spacing: 6,
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
          if (post.poll != null) PostPoll(postId: post.id, poll: post.poll!),
          if (post.hasPictures)
            Padding(
              padding: const EdgeInsets.only(top: RungSpace.sm),
              child: PostMediaGrid(media: post.media, onTap: onOpen),
            ),
          PostDocumentList(media: post.media),
          if (post.quoted != null)
            QuotedPostEmbed(quote: post.quoted!, author: quoteAuthor),
          // A repost whose original was deleted. Without this a PLAIN repost
          // has nothing at all to draw — no text, no media, no embed — and the
          // card is an author header over a blank space, which reads as a bug
          // in somebody's post rather than as a post that was taken down.
          if (post.originalUnavailable) const OriginalUnavailableNotice(),
          if (jobEmbed != null)
            _JobEmbed(job: jobEmbed!, onTap: onOpenJob),
          _Counts(post: post),
          if (showActions)
            _Actions(
              post: post,
              l10n: l10n,
              onLike: onLike,
              onComment: onComment,
              onRepost: onRepost,
              onSave: onSave,
            ),
        ],
      ),
    );
  }
}

/// Says, on a post from outside the viewer's network, that the server chose it.
///
/// Without this a brand-new account's feed — which is nothing BUT these — reads
/// as a network they somehow already have.
class _SuggestedBanner extends StatelessWidget {
  const _SuggestedBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        10,
        RungSpace.gutter,
        0,
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 15, color: c.amber),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              context.l10n.feedSuggestedPost,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepostBanner extends StatelessWidget {
  const _RepostBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.fromLTRB(RungSpace.gutter, 10, RungSpace.gutter, 0),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, size: 15, color: c.ink3),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              context.l10n.feedRepostedBy(name),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.author,
    required this.post,
    this.onOpenAuthor,
    this.onMore,
  });

  final Person author;
  final Post post;
  final VoidCallback? onOpenAuthor;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.fromLTRB(RungSpace.gutter, 13, 6, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onOpenAuthor,
            child: RungAvatar(
              seed: author.id,
              initials: author.initials,
              icon: author.accountType.icon,
              size: 44,
              imageUrl: ref.watch(imageUrlResolverProvider)(author.avatarUrl),
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
                      child: GestureDetector(
                        onTap: onOpenAuthor,
                        child: Text(
                          author.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ),
                    NameBadges(
                      verified: author.verified,
                      subscribed: author.subscribed,
                    ),
                    // Only on a suggestion. A row from someone you already
                    // follow does not need a Follow button, and the feed marks
                    // recommendations for exactly this reason.
                    //
                    // Not wrapped in Flexible: the name above it is, so when
                    // space runs out the NAME ellipsizes and the button keeps
                    // its full width. The other way round gives you a button
                    // reading "Conn…", which is worse than a shortened name.
                    if (post.suggested) ...[
                      const SizedBox(width: 8),
                      _SuggestedAction(author: author),
                    ],
                  ],
                ),
                Text(
                  author.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: c.ink2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${relativeTimeArabic(post.createdAt)} · '
                  '${post.visibility.label(context)}',
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ],
            ),
          ),
          // Hidden without a handler rather than shown disabled: a card in the
          // profile's preview rail has no options sheet behind it, and a greyed
          // "⋯" is a control that answers nothing.
          if (onMore != null)
            IconButton(
              onPressed: onMore,
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

/// Follow, beside the name on a suggested post.
///
/// A suggestion is the one place in the feed where the author is by definition
/// someone the viewer has no edge with, so the action is worth a tap's reach —
/// anywhere else it would be a button that does nothing.
class _SuggestedAction extends ConsumerWidget {
  const _SuggestedAction({required this.author});

  final Person author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // Watch the map, not just this id: Riverpod rebuilds on any change, and the
    // map is tiny. Reading `.notifier` alone would not rebuild the button when
    // its own state moved.
    final status = ref.watch(suggestedActionsProvider)[author.id] ??
        SuggestedActionState.idle;

    // One label for both kinds. It used to read "تواصل" for a person and
    // "متابعة" for a company; connections were withdrawn from the app, so
    // everyone is followed.
    final label = switch (status) {
      SuggestedActionState.done => l10n.postSuggestedFollowing,
      _ => l10n.profileFollow,
    };

    final settled = status == SuggestedActionState.done;
    final busy = status == SuggestedActionState.busy;

    return SizedBox(
      height: 24,
      child: OutlinedButton(
        onPressed: settled || busy ? null : () => _act(context, ref),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          // `shape` MUST be overridden, not just `side`. The app's
          // outlinedButtonTheme sets RungRadius.pill, so without this the
          // button inherits a full stadium and reads as a big lozenge next to
          // a 14.5px name. 6 is a soft corner that still looks like a control.
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          // Also lighter than the theme's 1.5: at this size a heavy outline is
          // the loudest thing in the header, louder than the name it sits beside.
          side: BorderSide(color: settled ? c.line : c.accent, width: 1),
          foregroundColor: c.accent,
          // A settled button stays on screen as a record of what you did, so it
          // has to read as inert rather than as something still waiting.
          disabledForegroundColor: c.ink3,
        ),
        child: busy
            ? SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: c.accent),
              )
            : Row(
                // The button sizes to its content; without this the Row would
                // try to fill the header.
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only while the action is still offered. Once it is sent,
                  // the label reads "Request sent" / "Following" and a plus in
                  // front of that would be inviting an action already taken.
                  //
                  // No Directionality handling needed: Row lays out from the
                  // START, so the plus sits to the RIGHT of the label in Arabic
                  // and to the left in English, which is leading in both.
                  if (!settled) ...[
                    const Icon(Icons.add_rounded, size: 13),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref
        .read(suggestedActionsProvider.notifier)
        .act(personId: author.id, isCompany: author.isCompany);
    if (!context.mounted) return;

    result.when(
      success: (_) =>
          showRungToast(context, l10n.toastFollowing(author.firstName)),
      // The button is already back to idle — `act` resets it — so this only has
      // to say why it did not take.
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }
}

/// The original post inside a repost or a quote — author, a preview of its
/// text and its first image. Tapping it opens the original.
///
/// Shared by the feed card and the post detail screen, so a repost reads the
/// same in both places.
class QuotedPostEmbed extends ConsumerWidget {
  const QuotedPostEmbed({
    super.key,required this.quote, this.author});

  final QuotedPost quote;

  /// The directory entry, when there is one — it carries the headline the
  /// quote projection doesn't.
  final Person? author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // The projection carries the name inline, so the directory is a bonus
    // rather than a requirement — a quote must never render nameless just
    // because its author is past the first page of profiles.
    final name = author?.name ?? quote.authorName;
    final headline = author?.headline ?? '';
    final resolve = ref.watch(imageUrlResolverProvider);
    final media = resolve(quote.firstMediaUrl);

    final embed = Container(
      margin: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        0,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: RungRadius.mdAll,
        border: Border.all(color: c.line),
      ),
      // Clipped so the image below meets the card's rounded corners instead of
      // squaring them off.
      child: ClipRRect(
        borderRadius: RungRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RungAvatar(
                        seed: quote.authorId,
                        initials: author?.initials ?? _initialOf(name),
                        icon: author?.accountType.icon,
                        size: 32,
                        // Prefers the directory record the initials already
                        // come from, so a refreshed name and photo stay in
                        // step; the quote's own inlined copy is the fallback.
                        imageUrl: resolve(
                          author?.avatarUrl ?? quote.authorAvatarUrl,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                // The quoted post's own projection carries no
                                // flags, so this lights up only when the author
                                // was resolved through the directory. Better
                                // than nothing and never wrong: a miss shows no
                                // badge rather than a false one.
                                NameBadges(
                                  verified: author?.verified ?? false,
                                  subscribed: author?.subscribed ?? false,
                                  size: 12,
                                ),
                              ],
                            ),
                            if (headline.isNotEmpty)
                              Text(
                                headline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: c.ink2),
                              ),
                            Text(
                              relativeTimeArabic(quote.createdAt),
                              style: TextStyle(fontSize: 11, color: c.ink3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (quote.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      quote.text,
                      // Truncated on purpose: this is a preview of another
                      // post, and letting it run full length would bury the
                      // commentary the sharer added above it.
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: c.ink2,
                      ),
                    ),
                    Text(
                      l10n.postSeeMore,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.ink3,
                      ),
                    ),
                  ],
                  SizedBox(height: media == null ? 12 : 10),
                ],
              ),
            ),
            if (media != null)
              Image.network(
                media,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                // Falls back to no image rather than a broken-image glyph —
                // the quote still reads without it.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(height: 190),
              ),
          ],
        ),
      ),
    );

    // Tapping the embed opens the ORIGINAL post, not the share around it —
    // the share's own detail is reached from its text and media above.
    if (quote.id.isEmpty) return embed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/feed/posts/${quote.id}'),
      child: embed,
    );
  }
}

/// First character of a name, for a quote whose author isn't in the directory.
String _initialOf(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '؟' : trimmed.substring(0, 1);
}

class _JobEmbed extends StatelessWidget {
  const _JobEmbed({required this.job, this.onTap});

  final PostJobEmbed job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        0,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: RungRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: RungRadius.mdAll,
              border: Border.all(color: c.line),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.accentSoft, c.surface],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RungLogoTile(
                      seed: job.company,
                      monogram: job.monogram,
                      size: 44,
                      radius: 11,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            '${job.company} · ${job.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  context.l10n.postViewJob,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            child: const Icon(Icons.thumb_up_alt, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Text(
            ArabicNumbers.count(post.likeCount),
            style: TextStyle(fontSize: 12, color: c.ink3),
          ),
          const Spacer(),
          Text(
            l10n.postCommentsCount(ArabicNumbers.count(post.commentCount)),
            style: TextStyle(fontSize: 12, color: c.ink3),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.postRepostsCount(ArabicNumbers.count(post.repostCount)),
            style: TextStyle(fontSize: 12, color: c.ink3),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.post,
    required this.l10n,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onSave,
  });

  final Post post;
  final AppLocalizations l10n;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      margin: const EdgeInsets.fromLTRB(RungSpace.gutter, 10, RungSpace.gutter, 0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: PostAction(
              icon: post.liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
              label: l10n.postActionLike,
              color: post.liked ? c.accent : c.ink2,
              onTap: onLike,
            ),
          ),
          Expanded(
            child: PostAction(
              icon: Icons.mode_comment_outlined,
              label: l10n.postActionComment,
              color: c.ink2,
              onTap: onComment,
            ),
          ),
          Expanded(
            child: PostAction(
              icon: Icons.repeat_rounded,
              label: l10n.postActionRepost,
              color: post.reposted ? c.green : c.ink2,
              // One repost per person: there is no un-share endpoint, and a
              // second Posts/Share is refused, so once it is green the control
              // is a state indicator rather than an action.
              onTap: post.reposted ? null : onRepost,
            ),
          ),
          SizedBox(
            width: 48,
            child: PostAction(
              icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
              label: null,
              color: post.saved ? c.accent : c.ink2,
              onTap: onSave,
              semanticLabel: l10n.postActionSave,
            ),
          ),
        ],
      ),
    );
  }
}

/// One cell of the like / comment / repost / save row. Kept public so the
/// post-detail screen renders the identical control.
class PostAction extends StatelessWidget {
  const PostAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (label != null) ...[
                const SizedBox(width: 6),
                // Flexible, because this row is laid out inside an Expanded
                // cell whose width is whatever is left over: at full width the
                // label always fits, but the same card is rendered 300px wide
                // in the profile's activity rail, where "إعادة نشر" is wider
                // than its share and overflowed the row.
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in for a repost's original when that original has been deleted.
///
/// Without it a PLAIN repost has nothing at all to draw — no text, no media,
/// no embed — and the post is an author header over a blank space, which
/// reads as a bug in somebody's post rather than a post that was taken down.
class OriginalUnavailableNotice extends StatelessWidget {
  const OriginalUnavailableNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: RungRadius.mdAll,
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Icon(Icons.link_off_rounded, size: 18, color: c.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.postOriginalUnavailable,
              style: TextStyle(fontSize: 13, color: c.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
