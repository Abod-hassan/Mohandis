import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/story.dart';
import '../notifiers/stories_notifier.dart';
import '../notifiers/story_groups.dart';

/// Full-bleed story viewer with an auto-advancing progress bar. Holding the
/// card pauses; the bar completing closes the story the way the design's
/// 24-hour cards behave.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 6);

  late final AnimationController _progress;

  bool _started = false;

  /// The author's stories, oldest first — or the single story this screen was
  /// opened on, when the rail does not hold it.
  ///
  /// Null only before the first build has resolved either.
  List<Story>? _group;

  /// Which of [_group] is on screen.
  int _index = 0;

  /// The stories already marked seen this session, so re-entering a story by
  /// tapping back does not re-POST the view.
  final Set<String> _viewed = <String>{};

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener(_onProgressStatus);
  }

  /// Records the view for whichever story is showing.
  ///
  /// Deferred to after the frame because it writes to a notifier the rail is
  /// watching, and once per story id because the viewer rebuilds on every
  /// progress tick.
  void _markSeen(String storyId) {
    if (_closing || !_viewed.add(storyId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closing) return;
      ref.read(storiesNotifierProvider.notifier).markSeen(storyId);
    });
  }

  /// The bar runs from the first frame that has a story on it, not from
  /// `initState`: a story fetched on its own would otherwise spend its six
  /// seconds behind a spinner and close as it arrived. Once only — a rebuild
  /// while the user is holding the card must not restart it.
  void _startProgress() {
    if (!mounted || _started) return;
    _started = true;
    _progress.forward();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) _advance(1);
  }

  /// Moves [delta] stories through the author's set, closing off the end.
  ///
  /// Stepping back from the first story closes too rather than doing nothing:
  /// a tap that visibly does nothing reads as a frozen screen, and the way out
  /// of the first story is the way you came in.
  void _advance(int delta) {
    if (_closing) return;
    final group = _group;
    final next = _index + delta;
    if (group == null || next < 0 || next >= group.length) {
      _close();
      return;
    }
    setState(() {
      _index = next;
      _started = false;
    });
    _progress
      ..reset()
      ..stop();
  }

  @override
  void dispose() {
    _progress
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    super.dispose();
  }

  /// Guards the exit. `mounted` stays true for the whole ~300ms pop
  /// transition, and the progress controller keeps ticking through it — so a
  /// story that completes just after the X is tapped would call this a second
  /// time and pop the feed out from under the user as well.
  bool _closing = false;

  /// Opens the story author's profile, over the viewer.
  ///
  /// The clock STOPS first, and that is the whole point of routing this through
  /// the screen rather than pushing from the header. The progress controller
  /// keeps ticking behind a pushed route, and six seconds later `_advance`
  /// would run off the end of the group and call `_close()` — which pops
  /// whatever is on top. That is the profile the person is reading, not the
  /// story underneath it.
  Future<void> _openAuthor(String authorId) async {
    _progress.stop();
    await context.push('/profile/$authorId');
    if (!mounted || _closing) return;

    // Resumed where it paused rather than restarted: coming back to a story
    // that begins again is a different story from the one that was left.
    _progress.forward();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _progress.stop();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/feed');
    }
  }

  /// Set once, on the first build that resolves a group.
  ///
  /// The route carries the story the rail was tapped on — the first UNSEEN one
  /// of that author's — and the viewer has to start there, not at the oldest.
  /// Only once: re-deriving it after `markSeen` has flipped the flags would
  /// snap the screen back every time the person advances.
  bool _entryPinned = false;

  Widget _viewer(List<Story> stories, {required bool grouped}) {
    _group = stories;

    // Pinned only from a real group. The single-story fallback is a list of
    // one whose index is trivially 0 — burning the pin there would mean that
    // when the rail finally loads, the group arrives with the pin already
    // spent and the screen jumps back to the author's OLDEST story.
    if (grouped && !_entryPinned) {
      _entryPinned = true;
      final at = stories.indexWhere((s) => s.id == widget.storyId);
      if (at >= 0) _index = at;
    }

    // Clamped, not trusted: `markSeen` rewrites the rail while this screen is
    // open, and a refresh can drop an expired story out from under the index.
    final index = _index.clamp(0, stories.length - 1);
    if (index != _index) _index = index;
    final story = stories[index];

    _markSeen(story.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProgress());

    return _StoryBody(
      story: story,
      progress: _progress,
      // The whole set, so the bar is segmented — one length per story, filled
      // behind the current one. A single bar over four stories would say the
      // person is a quarter of the way through one story.
      total: stories.length,
      index: index,
      onClose: _close,
      onPauseChanged: (paused) =>
          paused ? _progress.stop() : _progress.forward(),
      onStep: _advance,
      onOpenAuthor: () => _openAuthor(story.authorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesNotifierProvider);
    final group = storyGroupFor(
      ref.watch(storyGroupsProvider),
      widget.storyId,
    );

    final Widget body;
    if (group != null) {
      body = _viewer(group.stories, grouped: true);
    } else if (stories.isLoading) {
      body = const LoadingView();
    } else {
      // The rail is scoped to followed authors and drops expired rows, so it
      // is not a superset of what the viewer can be asked to open: a story
      // reached from a notification or a shared link is read on its own, and
      // is a set of exactly one.
      body = ref
          .watch(storyByIdProvider(widget.storyId))
          .when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(storyByIdProvider(widget.storyId)),
            ),
            data: (story) => _viewer([story], grouped: false),
          );
    }

    return Scaffold(backgroundColor: Colors.black, body: body);
  }
}

class _StoryBody extends ConsumerWidget {
  const _StoryBody({
    required this.story,
    required this.progress,
    required this.total,
    required this.index,
    required this.onClose,
    required this.onPauseChanged,
    required this.onStep,
    required this.onOpenAuthor,
  });

  final Story story;
  final AnimationController progress;

  /// How many stories this author has, and which one is showing.
  final int total;
  final int index;

  final VoidCallback onClose;
  final ValueChanged<bool> onPauseChanged;

  /// -1 / +1 through the author's set.
  final ValueChanged<int> onStep;

  /// Opens the author's profile. The screen owns it rather than this widget,
  /// because leaving has to stop the clock first — see
  /// [_StoryViewerScreenState._openAuthor].
  final VoidCallback onOpenAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The backend inlines the author on every story row, so the story itself
    // is the fallback when the directory — which is paged, and need not hold
    // this person at all — misses.
    final author = resolveAuthor(ref, story.authorId, story.author);
    // Through the resolver, always. `mediaUrl` is the host-less path the
    // upload stored — `stories/<uuid>.jpg` — and the CDN host is deployment
    // configuration that lives in the zone. Handing the raw path to
    // Image.network asks the device to fetch a relative URL, which fails, and
    // the errorBuilder below then hides the failure behind the gradient: the
    // story renders, looking exactly like one that simply has no image.
    final media = ref.watch(imageUrlResolverProvider)(story.mediaUrl);

    return GestureDetector(
      onLongPressStart: (_) => onPauseChanged(true),
      onLongPressEnd: (_) => onPauseChanged(false),
      child: Container(
        decoration: BoxDecoration(gradient: RungGradients.forSeed(story.id)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A video story has no player here yet, and its URL is not an
            // image — loading it would only flash the error builder — so the
            // gradient stands in for it.
            if (media != null && !story.isVideo)
              Image.network(
                media,
                fit: BoxFit.cover,
                // The gradient underneath is the fallback; a broken-image
                // glyph across a full-bleed story would read as a crash.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            // Below the header and the reply row, which come later in this
            // stack and so take their own taps first. Above the image, which
            // is not interactive.
            Row(
              children: [
                // Start side steps BACK. In an RTL layout that is the right
                // half of the screen, which is the direction Arabic is read
                // from — the same gesture means the same thing in both.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onStep(-1),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onStep(1),
                  ),
                ),
              ],
            ),
            SafeArea(
              child: Stack(
                children: [
                  // IgnorePointer, because `RenderParagraph` hit-tests TRUE
                  // over its whole laid-out box. A two-line caption is a
                  // full-width band across the middle of the screen, and the
                  // stack tests this subtree before the tap zones below it —
                  // so without this, tapping the centre of a story does
                  // nothing at all and reads as a frozen screen.
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Center(
                        child: Text(
                          story.caption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 12,
                    right: 12,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: progress,
                          builder: (context, _) => Row(
                            children: [
                              for (var i = 0; i < total; i++) ...[
                                if (i > 0) const SizedBox(width: 4),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      // Behind the current one: full. Ahead:
                                      // empty. The current one animates.
                                      value: i < index
                                          ? 1.0
                                          : (i == index ? progress.value : 0.0),
                                      minHeight: 3,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Avatar AND name are one target, because they read
                            // as one thing. Opaque so the whole strip absorbs
                            // its own taps — the story's back/forward zones sit
                            // directly underneath, and a miss here used to step
                            // the story instead of opening the person.
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onOpenAuthor,
                                child: Row(
                                  children: [
                                    RungAvatar(
                                      seed: story.authorId,
                                      initials: author.initials,
                                      imageUrl:
                                          ref.watch(imageUrlResolverProvider)(
                                        author.avatarUrl,
                                      ),
                                      size: 36,
                                      borderColor: Colors.white,
                                      borderWidth: 2,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            context.l10n.storyPostedAgo(
                                              relativeTimeArabic(
                                                story.createdAt,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close, color: Colors.white),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Expanded(
                          // Opaque, and with an action of its own. A bare
                          // Container hit-tests false over everything but its
                          // glyphs, so reaching for the reply field used to
                          // fall through to the tap zone underneath — and on
                          // the last story of a group that CLOSED the viewer.
                          // `StoriesController` has no reply action yet, so
                          // the honest answer is to say so.
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                showRungToast(context, context.l10n.comingSoon),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white54,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                context.l10n.storyReplyTo(author.firstName),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          // StoriesController has no like and no reply action,
                          // so this cannot do anything yet — and it certainly
                          // must not claim a repost that never happened.
                          onPressed: () =>
                              showRungToast(context, context.l10n.comingSoon),
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 26,
                          ),
                          tooltip: context.l10n.postActionLike,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
