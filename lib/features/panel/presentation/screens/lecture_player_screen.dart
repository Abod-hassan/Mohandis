import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';

/// Plays one lecture.
///
/// Pops `true` once the position reaches the end — including by dragging the
/// scrubber there. That is deliberate: the panel is a progress tracker, not a
/// proctor, and the control it replaces was a self-declared "أنهيت المحاضرة"
/// button. Enforcing genuine watch time would mean accumulating played seconds
/// and is a different feature.
///
/// The caller writes the progress, not this screen: the write has to survive
/// the player being closed, and it belongs next to the rest of the course state
/// rather than behind a route the system may pop.
class LecturePlayerScreen extends ConsumerStatefulWidget {
  const LecturePlayerScreen({super.key, required this.lecture});

  final Lecture lecture;

  @override
  ConsumerState<LecturePlayerScreen> createState() =>
      _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends ConsumerState<LecturePlayerScreen> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _reportedDone = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    // Resolving needs a ref read, which is safe in initState but the storage
    // zone may still be loading — so this runs after the first frame, by which
    // point `imageUrlResolverProvider` has the zone or its fallback base.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    // The post-frame callback still runs for a route popped inside the first
    // frame, and reading `ref` after disposal throws out of a future nobody is
    // awaiting — an unhandled zone error rather than a visible failure.
    if (!mounted) return;

    final resolved = ref.read(imageUrlResolverProvider)(widget.lecture.contentUrl);
    if (resolved == null || resolved.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }

    if (!mounted) {
      // Popped while the first frame was loading. Nothing owns the controller
      // yet, so it has to be released here or it leaks a decoder.
      await controller.dispose();
      return;
    }

    controller.addListener(_onTick);
    setState(() => _controller = controller);
    await controller.play();
  }

  /// Fires on every position change.
  ///
  /// Also what keeps the play/pause icon honest: nothing else rebuilds this
  /// screen, so a pause the user did not cause — buffering, another app taking
  /// audio focus — would otherwise leave the button showing the wrong state and
  /// doing the opposite of what it says.
  void _onTick() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;

    if (value.isPlaying != _playing && mounted) {
      setState(() => _playing = value.isPlaying);
    }

    if (_reportedDone) return;

    final duration = value.duration;
    if (duration <= Duration.zero) return;
    if (value.position < duration) return;

    _reportedDone = true;
    if (!mounted) return;

    // `mounted` stays true for the whole exit transition, so a video that
    // crosses its end while the user is already backing out would pop a SECOND
    // route — taking the course screen with it and dropping them on the panel.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: RungAppBar(title: widget.lecture.title),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(RungSpace.gutter),
                child: Text(
                  l10n.coursePlayerError,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.ink3),
                ),
              )
            : controller == null
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Column(
                children: [
                  // Expanded, not sized by the aspect ratio alone: a portrait
                  // clip on a narrow phone wants more height than the viewport
                  // has, and a Column would overflow rather than shrink it.
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  // LTR on purpose, inside an RTL app: a scrubber is a timeline,
                  // and time runs left to right whatever the script does. Mirrored
                  // it would put the start of the lecture on the right.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: c.accent,
                            bufferedColor: c.surface3,
                            backgroundColor: c.line,
                          ),
                        ),
                        IconButton(
                          iconSize: 44,
                          color: Colors.white,
                          // No setState here: the listener above owns _playing,
                          // so the icon follows the controller whether the
                          // change came from this button or from the platform.
                          onPressed: () => _playing
                              ? controller.pause()
                              : controller.play(),
                          icon: Icon(
                            _playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
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
