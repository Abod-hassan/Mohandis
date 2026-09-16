import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/reel.dart';
import '../notifiers/reels_notifier.dart';

/// Vertical reel player. Swiping the page view moves between reels; the
/// progress pips at the top mirror the design's segmented bar.
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final _controller = PageController();

  /// Reels already counted as played this visit. The page view rebuilds for
  /// reasons that have nothing to do with playback — an optimistic like, a
  /// theme change — and the server counts every call it is given, so without
  /// this one reel would rack up plays by sitting still.
  final _played = <String>{};

  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _countPlay(String reelId) {
    if (!mounted || !_played.add(reelId)) return;
    ref.read(reelsNotifierProvider.notifier).markPlayed(reelId);
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: reels.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(reelsNotifierProvider.notifier).refresh(),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                context.l10n.emptyTitle,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          // A refresh can return a shorter list than the page the user was on.
          final index = _index < list.length ? _index : list.length - 1;
          final currentId = list[index].id;
          // `_index` only ever moves through setState, so every swipe lands
          // here on the next build — one hook counts the first reel and every
          // one after it.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _countPlay(currentId),
          );

          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: list.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  // Fetch ahead by two so the next swipe lands on a reel that
                  // is already there — a full-screen pager has no room for a
                  // spinner between pages.
                  if (i >= list.length - 3) {
                    ref.read(reelsNotifierProvider.notifier).loadMore();
                  }
                },
                itemBuilder: (context, i) => _ReelPage(reel: list[i]),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (var i = 0; i < list.length; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == index ? Colors.white : Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReelPage extends ConsumerWidget {
  const _ReelPage({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The backend inlines the author on every reel row, so the reel itself is
    // the fallback when the directory — which is paged, and need not hold this
    // person at all — misses.
    final author = resolveAuthor(ref, reel.authorId, reel.author);
    final thumbnail = reel.thumbnailUrl;
    final notifier = ref.read(reelsNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(gradient: RungGradients.forSeed(reel.id)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The still frame is as far as this screen goes — there is no video
          // player yet — so the play glyph over it is decoration, not a
          // control.
          if (thumbnail != null)
            Image.network(
              thumbnail,
              fit: BoxFit.cover,
              // The gradient underneath is the fallback; a broken-image glyph
              // across a full-bleed reel would read as a crash.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          SafeArea(
            child: Stack(
              children: [
                const Center(child: _PlayGlyph()),
                PositionedDirectional(
                  top: 16,
                  start: 16,
                  end: 16,
                  child: Row(
                    children: [
                      Text(
                        l10n.reelsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          final wasSaved = reel.saved;
                          final result = await notifier.toggleSave(reel.id);
                          if (!context.mounted) return;
                          // The notifier rolls its optimistic flip back on
                          // failure, so the toast has to read the result too —
                          // otherwise the glyph says "not saved" while the
                          // toast says "saved".
                          result.when(
                            success: (_) {
                              if (wasSaved) return;
                              showRungToast(context, l10n.toastSavedToReels);
                            },
                            failure: (e) => showRungToast(
                              context,
                              arabicMessageForException(e),
                              success: false,
                            ),
                          );
                        },
                        icon: Icon(
                          reel.saved ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: l10n.postActionSave,
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  end: 12,
                  bottom: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RailAction(
                        icon: reel.liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: ArabicNumbers.compact(reel.likeCount),
                        color: reel.liked
                            ? const Color(0xFFFF5470)
                            : Colors.white,
                        onTap: () => notifier.toggleLike(reel.id),
                      ),
                      const SizedBox(height: 22),
                      _RailAction(
                        icon: Icons.mode_comment_outlined,
                        // Comments in this module hang off a post, and a reel
                        // is its own entity — there is no count to show, and
                        // nothing to open yet.
                        label: l10n.postActionComment,
                        color: Colors.white,
                        onTap: () => showRungToast(context, l10n.comingSoon),
                      ),
                      const SizedBox(height: 22),
                      _RailAction(
                        icon: Icons.repeat_rounded,
                        label: l10n.reelShare,
                        color: Colors.white,
                        onTap: () => showRungToast(context, l10n.comingSoon),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 16,
                  end: 74,
                  bottom: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${reel.authorId}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RungAvatar(
                              seed: reel.authorId,
                              initials: author.initials,
                              imageUrl: ref.watch(imageUrlResolverProvider)(
                                author.avatarUrl,
                              ),
                              size: 38,
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                author.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: RungRadius.pill,
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 1.4,
                                ),
                              ),
                              child: Text(
                                l10n.reelFollow,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reel.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (reel.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in reel.tags)
                              Text(
                                tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '▶ ${l10n.reelPlays(ArabicNumbers.compact(reel.playCount))}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0x47000000),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
