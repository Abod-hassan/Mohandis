import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import 'package:mohandis/core/router/shell_branch.dart';

import '../../domain/entities/reel.dart';
import '../notifiers/reels_notifier.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_activity_notifier.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';
import '../widgets/reel_comments_sheet.dart';
import '../widgets/reel_video.dart';
import '../widgets/reel_video_cache.dart';

/// What a profile's grid hands the player: the reels it shows, and which one
/// was tapped.
class ReelsPlayerSeed {
  const ReelsPlayerSeed({required this.reels, required this.index});

  final List<Reel> reels;
  final int index;
}

/// Vertical reel player. Swiping the page view moves between reels, and a pull
/// down on the first one re-reads the wall.
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key, this.initialIndex = 0, this.standalone = false});

  /// The reel to open on.
  final int initialIndex;

  /// Pushed over the app — a profile's reels — rather than living in the Reels
  /// tab. Gets a back button, and plays whenever it is the top route instead
  /// of only while the Reels tab is selected.
  final bool standalone;

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen>
    with WidgetsBindingObserver {
  late final _controller = PageController(initialPage: widget.initialIndex);
  final _videos = ReelVideoCache();

  /// Reels already counted as played this visit. The page view rebuilds for
  /// reasons that have nothing to do with playback — an optimistic like, a
  /// theme change — and the server counts every call it is given, so without
  /// this one reel would rack up plays by sitting still.
  final _played = <String>{};

  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The cache drives the video surfaces, and nothing else rebuilds when a
    // controller finishes initialising.
    _videos.addListener(_onVideos);
  }

  void _onVideos() {
    if (mounted) setState(() {});
  }

  /// Tapping Reels while already on Reels: back to the first one, with the
  /// wall re-read.
  ///
  /// The jump comes FIRST and without animation. Animating would scroll
  /// through every reel between here and the top, initialising and disposing a
  /// controller for each one it passes — a dozen videos opened to reach the
  /// first. `jumpToPage` moves the pager once.
  Future<void> _retap() async {
    if (!mounted) return;

    if (_controller.hasClients && _index != 0) {
      _controller.jumpToPage(0);
      setState(() => _index = 0);
    }

    // Plays are per visit, and this is a new one: without clearing, a reel
    // already seen before the refresh would never count again this session.
    _played.clear();
    await ref.read(reelsNotifierProvider.notifier).refresh();
  }

  /// Whether the reels were on screen at the last build — the tab is up and
  /// nothing is pushed over it. App resume only restarts playback when they
  /// were; otherwise a reel would start talking behind the feed.
  bool _visible = false;

  /// Backgrounding the app must stop the audio. iOS does not do this for us —
  /// AVPlayer keeps going, and a reel talking from a pocket is the worst
  /// version of this bug.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Something has to start it again. Nothing else will: the cache only
      // acts when the page or the list changes, and neither did while the app
      // was away. `resumeCurrent` respects a pause the viewer made by hand.
      if (_visible) _videos.resumeCurrent();
      return;
    }
    // Includes `inactive`, which iOS fires for Control Centre and the app
    // switcher. Pausing there is the conservative choice: a reel talking from
    // a pocket is the worst version of this.
    _videos.pauseAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videos.removeListener(_onVideos);
    _videos.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _countPlay(String reelId) {
    if (!mounted || !_played.add(reelId)) return;
    ref.read(reelsNotifierProvider.notifier).markPlayed(reelId);
  }

  @override
  Widget build(BuildContext context) {
    // `listen`, not `watch`: a re-tap is an event, and watching a counter would
    // rebuild the whole player every time anyone touched any tab.
    // Only the tab's own player: a pushed one is not what the tab button
    // points at. `standalone` never changes for a mounted screen, so the
    // listen is made on every build or on none.
    if (!widget.standalone) {
      ref.listen<int>(
        shellRetapProvider(ShellBranch.reels),
        (_, __) => _retap(),
      );
    }

    final reels = ref.watch(reelsNotifierProvider);
    // Whatever branch renders below. The list can be null (loading), empty, or
    // gone (a failed refresh) — and every one of those has to reach the pause
    // below, which is why this sits here rather than inside `data:`. A refresh
    // that fails now unmounts the player while its audio keeps going.
    final list = reels.valueOrNull ?? const <Reel>[];

    // A refresh can return a shorter list than the page the user was on.
    final index = list.isEmpty
        ? 0
        : (_index < list.length ? _index : list.length - 1);

    // `StatefulShellRoute.indexedStack` keeps this screen mounted behind
    // the other tabs, so "am I on screen" has to come from the shell —
    // see `shellBranchProvider`. Without it a reel keeps playing, audio
    // and all, while the user reads the feed.
    // Two conditions, not one. The branch index says which TAB is up; it
    // does not change when a route is pushed ON TOP of this one — and
    // tapping a reel's author does exactly that. Without `isCurrent` the
    // reel keeps playing, audio and all, behind the profile page.
    final onReelsTab = widget.standalone ||
        ref.watch(shellBranchProvider) == ShellBranch.reels;
    final onTop = ModalRoute.of(context)?.isCurrent ?? true;
    final visible = onReelsTab && onTop && list.isNotEmpty;

    // Media is stored HOST-LESS — `<guid>/playlist.m3u8` on Stream, or
    // `reels/<uuid>.mp4` in the storage zone for anything published before
    // Stream — so the raw value is not something a player can open. This
    // resolver reads the path to decide which CDN it belongs to; seeded rows
    // carrying absolute URLs pass straight through either way.
    final resolve = ref.watch(streamAwareUrlResolverProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visible = visible;
      if (!visible) {
        _videos.pauseAll();
        return;
      }
      // Below the visibility guard: a rebuild while the tab is hidden —
      // a loadMore landing, a like elsewhere — would otherwise post a
      // play for a reel nobody is watching.
      _countPlay(list[index].id);
      _videos.setIndex(
        index: index,
        ids: [for (final r in list) r.id],
        urls: {for (final r in list) r.id: resolve(r.videoUrl)},
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          reels.when(
            loading: () => const ReelsSkeleton(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(reelsNotifierProvider.notifier).refresh(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                // Scrollable, so the pull that refreshes the wall also works on
                // the page that says there is nothing on it — on a full-screen
                // surface with no app bar, a dead end is a dead end.
                return RefreshIndicator(
                  onRefresh: () =>
                      pullRefresh(ref.refresh(reelsNotifierProvider.future)),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.7,
                        child: Center(
                          child: Text(
                            context.l10n.emptyTitle,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Pull down on the first reel to refresh: the pager is a vertical
              // scrollable, so a RefreshIndicator works over it.
              return RefreshIndicator(
                onRefresh: () =>
                    pullRefresh(ref.refresh(reelsNotifierProvider.future)),
                child: PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  // `PageView` applies its own page physics on top of whatever
                  // it is given; this only has to restore the overscroll that a
                  // RefreshIndicator needs and a pager would otherwise eat.
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: rows.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    // Fetch ahead by two so the next swipe lands on a reel that
                    // is already there — a full-screen pager has no room for a
                    // spinner between pages.
                    if (i >= rows.length - 3) {
                      ref.read(reelsNotifierProvider.notifier).loadMore();
                    }
                  },
                  itemBuilder: (context, i) => _ReelPage(
                    reel: rows[i],
                    videos: _videos,
                    isCurrent: i == index,
                    standalone: widget.standalone,
                  ),
                ),
              );
            },
          ),
          // Loading, failed or empty: no reel page, so no top row and no back
          // button on it. A pushed player still needs a way out of those.
          if (widget.standalone && list.isEmpty)
            const SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: BackButton(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReelPage extends ConsumerWidget {
  const _ReelPage({
    required this.reel,
    required this.videos,
    required this.isCurrent,
    required this.standalone,
  });

  /// Draws a back button ahead of the title. See [ReelsScreen.standalone].
  final bool standalone;

  final Reel reel;
  final ReelVideoCache videos;

  /// Only the page in view gets the tap controls. A neighbour is initialised
  /// and paused; letting a tap through to it would play two reels at once.
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The backend inlines the author on every reel row, so the reel itself is
    // the fallback when the directory — which is paged, and need not hold this
    // person at all — misses.
    final author = resolveAuthor(ref, reel.authorId, reel.author);
    // Host-less, like the video — the poster silently failed to load without
    // this, and the errorBuilder swallowed it so nothing said so.
    // The STREAM-aware resolver, like the video below: a reel published since
    // Stream arrived keeps both its playlist and its poster under the video's
    // guid, served by the library's own CDN rather than the storage zone.
    final thumbnail = ref.watch(streamAwareUrlResolverProvider)(
      // `posterPath`, not the stored column: Stream writes the poster during
      // transcoding, so a reel published seconds ago has an empty one and the
      // path has to be derived from the video's guid.
      reel.posterPath,
    );
    final notifier = ref.read(reelsNotifierProvider.notifier);
    // Read here, in build: `_isMine` watches the signed-in person, and a watch
    // inside a tap callback is not allowed.
    final mine = _isMine(ref, reel);

    final controller = videos.controllerFor(reel.id);
    final playing = controller?.value.isPlaying ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        ReelVideo(controller: controller, thumbnailUrl: thumbnail),
        // Tap anywhere to pause or resume; the rail's own buttons sit above
        // this and swallow their taps before they reach it.
        if (isCurrent)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => videos.togglePlay(reel.id),
            ),
          ),
        // Scrims. A reel can be a white wall or a sunlit street, and white text
        // on either is unreadable — so the two places text lives get a gradient
        // of their own rather than the whole frame being dimmed, which would
        // dull the video everywhere it is not needed.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _Scrim(height: 170, fromTop: true),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _Scrim(height: 320, fromTop: false),
        ),
        Stack(
          fit: StackFit.expand,
          children: [
          SafeArea(
            child: Stack(
              children: [
                // Only while paused, and only on the page in view. It used to
                // sit over every reel permanently, which read as "this never
                // plays" — which, until now, was true.
                if (isCurrent && !playing) const Center(child: _PlayGlyph()),
                PositionedDirectional(
                  top: 16,
                  start: 16,
                  end: 16,
                  child: Row(
                    children: [
                      if (standalone) ...[
                        // Follows the reading direction, so in Arabic it
                        // points right — the way back.
                        const BackButton(color: Colors.white),
                        const SizedBox(width: 4),
                      ],
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
                      // Your own reel: delete or undo the repost. Anyone
                      // else's: report it (App Store guideline 1.2).
                      IconButton(
                        onPressed: () => mine
                            ? _showOwnReelOptions(context, reel)
                            : showReportSheet(
                                context,
                                target: ReportTarget.reel,
                                targetId: reel.id,
                              ),
                        icon: Icon(
                          mine
                              ? Icons.more_vert_rounded
                              : Icons.outlined_flag_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: mine ? l10n.reelOptions : l10n.reportReel,
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
                        label: reel.commentCount > 0
                            ? ArabicNumbers.compact(reel.commentCount)
                            : l10n.reelComment,
                        color: Colors.white,
                        onTap: () => showReelCommentsSheet(
                          context,
                          reel: reel,
                          reelIsMine: mine,
                          onCountChanged: (delta) =>
                              notifier.adjustCommentCount(reel.id, delta),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _RailAction(
                        icon: Icons.repeat_rounded,
                        label: reel.shareCount > 0
                            ? ArabicNumbers.compact(reel.shareCount)
                            : l10n.reelShare,
                        // Green rather than the like's pink: a repost is not a
                        // second kind of like, and two filled icons in the same
                        // colour on one rail read as one state.
                        color: reel.shared
                            ? const Color(0xFF42D392)
                            : Colors.white,
                        onTap: () async {
                          final wasShared = reel.shared;
                          final result = await notifier.toggleShare(reel.id);
                          if (!context.mounted) return;
                          result.when(
                            success: (_) => showRungToast(
                              context,
                              wasShared
                                  ? l10n.toastReelUnreposted
                                  : l10n.toastReelReposted,
                            ),
                            failure: (e) => showRungToast(
                              context,
                              arabicMessageForException(e),
                              success: false,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      // Reels start muted — autoplaying sound into a room is
                      // the fastest way to make somebody close an app — so
                      // there has to be a way to turn it on.
                      _RailAction(
                        icon: videos.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        label: videos.muted ? l10n.reelUnmute : l10n.reelMute,
                        color: Colors.white,
                        onTap: () => videos.toggleMute(reel.id),
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
                      // **Above the name, not below it.** A repost shows the
                      // reposter's avatar and handle, because the row in this
                      // wall is theirs — so without this line the video reads
                      // as their work. Said first, in the order somebody
                      // reads: whose this is, then who is showing it to you.
                      if (reel.isRepost &&
                          (reel.sharedAuthorName ?? '').isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            final original = reel.sharedAuthorId;
                            if (original == null) return;
                            context.push('/profile/$original');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.repeat_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.feedRepostedBy(reel.sharedAuthorName!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      GestureDetector(
                        onTap: () => context.push('/profile/${reel.authorId}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RungAvatar(
                              seed: reel.authorId,
                              initials: author.initials,
                              icon: author.accountType.icon,
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
                            // onDark: this row sits on a scrim over video,
                            // where both colour tokens are chosen against a
                            // light surface and the accent one disappears.
                            NameBadges(
                              verified: author.verified,
                              subscribed: author.subscribed,
                              size: 13,
                              onDark: true,
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
      ],
    );
  }
}

/// Whether the signed-in person published [reel] (or, for a repost, made it).
/// Case-insensitive: one Guid can arrive in two casings from two payloads.
bool _isMine(WidgetRef ref, Reel reel) {
  final me = ref.watch(currentPersonProvider).valueOrNull?.id;
  return me != null && me.toLowerCase() == reel.authorId.toLowerCase();
}

/// The ⋯ sheet on your own reel: delete it, or — for your repost of someone
/// else's — take the repost back.
Future<void> _showOwnReelOptions(BuildContext context, Reel reel) async {
  final l10n = context.l10n;
  final remove = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = sheetContext.rung;
      return SafeArea(
        child: ListTile(
          leading: Icon(
            reel.isRepost ? Icons.repeat_rounded : Icons.delete_outline_rounded,
            color: c.red,
          ),
          title: Text(
            reel.isRepost ? l10n.reelUndoRepost : l10n.reelDelete,
            style: TextStyle(color: c.red),
          ),
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
      );
    },
  );
  if (remove != true || !context.mounted) return;

  // Only an original asks first: it takes every repost of it down too, and
  // there is no getting it back. Undoing a repost is one tap to redo.
  if (!reel.isRepost) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reelDeleteConfirm),
        content: Text(l10n.reelDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(color: dialogContext.rung.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  // The page this sheet was opened from leaves the pager the moment the
  // delete lands, taking its context with it — so the toast and the grid
  // refresh go through the screen, which stays.
  final screen = context.findAncestorStateOfType<_ReelsScreenState>();
  if (screen == null) return;
  final result =
      await screen.ref.read(reelsNotifierProvider.notifier).remove(reel.id);
  if (!screen.mounted) return;
  result.when(
    success: (_) {
      // The profile grid this reel sits in. The profile player also does this
      // through its notifier; twice is harmless, and the wall needs it here.
      screen.ref.invalidate(profileReelsProvider(reel.authorId));
      showRungToast(
        screen.context,
        reel.isRepost ? l10n.toastReelUnreposted : l10n.toastReelDeleted,
      );
    },
    failure: (e) => showRungToast(
      screen.context,
      arabicMessageForException(e),
      success: false,
    ),
  );
}

/// A black gradient that fades to nothing, behind the text at one end of the
/// frame.
///
/// `IgnorePointer`, because the frame's tap-to-pause sits underneath it and a
/// scrim that swallowed taps would make half the screen inert.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.height, required this.fromTop});

  final double height;

  /// Dark at the top fading down, or dark at the bottom fading up.
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
            // Three stops, not two: a straight black-to-transparent ramp leaves
            // a visible edge where it ends, and the middle stop is what makes
            // it read as light falling off instead of a rectangle.
            colors: [
              Colors.black.withValues(alpha: fromTop ? 0.55 : 0.75),
              Colors.black.withValues(alpha: fromTop ? 0.18 : 0.35),
              Colors.transparent,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
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
