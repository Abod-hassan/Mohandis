import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/loading_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../../data/repositories/story_repository_impl.dart';
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

  /// The reply field has the keyboard. The clock is held for as long as it
  /// does — a story that moves on mid-sentence takes the half-written reply
  /// with it — and a tap on the story only dismisses the keyboard.
  bool _typing = false;

  void _onTypingChanged(bool typing) {
    _typing = typing;
    if (_closing) return;
    typing ? _progress.stop() : _progress.forward();
  }

  void _onStep(int delta) {
    if (_typing) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    _advance(delta);
  }

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
      onPauseChanged: (paused) {
        if (paused) {
          _progress.stop();
        } else if (!_typing) {
          _progress.forward();
        }
      },
      onTypingChanged: _onTypingChanged,
      onStep: _onStep,
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
    required this.onTypingChanged,
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

  /// The reply field gained or lost the keyboard.
  final ValueChanged<bool> onTypingChanged;

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
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id;
    final isMine =
        myId != null && myId.toLowerCase() == story.authorId.toLowerCase();
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
                                      icon: author.accountType.icon,
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
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  author.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              NameBadges(
                                                verified: author.verified,
                                                subscribed: author.subscribed,
                                                size: 13,
                                                onDark: true,
                                              ),
                                            ],
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
                  PositionedDirectional(
                    start: 12,
                    end: 12,
                    bottom: 12,
                    child: _StoryFooter(
                      key: ValueKey(story.id),
                      story: story,
                      isMine: isMine,
                      onTypingChanged: onTypingChanged,
                      onPauseChanged: onPauseChanged,
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

/// The strip along the bottom of a story.
///
/// Somebody else's story: a reply field (the reply lands in a direct message
/// to the author, quoting the story), a heart, and a report flag. Your own
/// story: how many people watched it and how many liked it.
///
/// Keyed by story id at the call site, so moving to the next story starts
/// from that story's own heart and an empty field.
class _StoryFooter extends ConsumerStatefulWidget {
  const _StoryFooter({
    super.key,
    required this.story,
    required this.isMine,
    required this.onTypingChanged,
    required this.onPauseChanged,
  });

  final Story story;
  final bool isMine;
  final ValueChanged<bool> onTypingChanged;
  final ValueChanged<bool> onPauseChanged;

  @override
  ConsumerState<_StoryFooter> createState() => _StoryFooterState();
}

class _StoryFooterState extends ConsumerState<_StoryFooter> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  late bool _liked = widget.story.liked;
  late int _likeCount = widget.story.likeCount;
  bool _liking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _controller.addListener(_onText);
  }

  void _onFocus() {
    widget.onTypingChanged(_focus.hasFocus);
    if (mounted) setState(() {});
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    // Leaving with the keyboard up must not leave the screen thinking a reply
    // is still being typed — the next story's clock would never start.
    if (_focus.hasFocus) widget.onTypingChanged(false);
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _controller
      ..removeListener(_onText)
      ..dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    final wasLiked = _liked;
    final wasCount = _likeCount;
    setState(() {
      _liking = true;
      _liked = !wasLiked;
      _likeCount = wasLiked ? (wasCount > 0 ? wasCount - 1 : 0) : wasCount + 1;
    });

    final result = await ref
        .read(storyRepositoryProvider)
        .toggleLike(widget.story.id);
    if (!mounted) return;
    result.when(
      success: (server) {
        setState(() {
          _liking = false;
          _liked = server.liked;
          _likeCount = server.likeCount;
        });
        ref
            .read(storiesNotifierProvider.notifier)
            .applyLike(
              widget.story.id,
              liked: server.liked,
              likeCount: server.likeCount,
            );
      },
      failure: (_) {
        setState(() {
          _liking = false;
          _liked = wasLiked;
          _likeCount = wasCount;
        });
        showRungToast(context, context.l10n.storyLikeFailed, success: false);
      },
    );
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final result = await ref
        .read(storyRepositoryProvider)
        .reply(widget.story.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      success: (_) {
        _controller.clear();
        _focus.unfocus();
        showRungToast(context, context.l10n.storyReplySent);
      },
      failure: (_) => showRungToast(
        context,
        context.l10n.storyReplyFailed,
        success: false,
      ),
    );
  }

  Future<void> _report() async {
    widget.onPauseChanged(true);
    await showReportSheet(
      context,
      target: ReportTarget.story,
      targetId: widget.story.id,
    );
    if (mounted) widget.onPauseChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (widget.isMine) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: const ShapeDecoration(
            color: Color(0x59000000),
            shape: StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 17,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.story.viewCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.favorite_rounded,
                  size: 17,
                  color: Color(0xFFFF4D67),
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canSend = _controller.text.trim().isNotEmpty && !_sending;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            enabled: !_sending,
            maxLength: 500,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendReply(),
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.storyReplyHint,
              hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: const Color(0x40000000),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.white),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.white38),
              ),
              suffixIcon: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : (canSend
                        ? IconButton(
                            onPressed: _sendReply,
                            tooltip: l10n.storyReplySend,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : null),
            ),
          ),
        ),
        // The heart and the flag drop away while typing: the field gets the
        // whole width, and a stray tap cannot like the story mid-sentence.
        if (!_focus.hasFocus) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: _toggleLike,
            tooltip: l10n.storyLike,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(_liked),
                color: _liked ? const Color(0xFFFF4D67) : Colors.white,
                size: 28,
              ),
            ),
          ),
          IconButton(
            onPressed: _report,
            tooltip: l10n.reportStory,
            icon: const Icon(
              Icons.outlined_flag_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ],
    );
  }
}
