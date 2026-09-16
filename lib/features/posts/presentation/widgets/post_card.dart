import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/post.dart';
import 'post_document_list.dart';
import 'post_media_grid.dart';
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
                child: Text(
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
                  for (final tag in post.tags) RungHashtag(tag: tag),
                ],
              ),
            ),
          if (post.hasPictures)
            Padding(
              padding: const EdgeInsets.only(top: RungSpace.sm),
              child: PostMediaGrid(media: post.media, onTap: onOpen),
            ),
          PostDocumentList(media: post.media),
          if (post.quoted != null)
            _QuoteEmbed(quote: post.quoted!, author: quoteAuthor),
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

class _QuoteEmbed extends ConsumerWidget {
  const _QuoteEmbed({required this.quote, this.author});

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

    return Container(
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
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
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
