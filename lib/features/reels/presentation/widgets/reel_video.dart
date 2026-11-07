import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The playing surface of one reel.
///
/// Owns nothing: the controller is created and destroyed by `ReelVideoCache`,
/// because a reel's video has to start buffering BEFORE its page is built — a
/// pager that only initialises on arrival shows a black frame on every swipe.
///
/// **Three layers, and the order is the whole design.** Black underneath,
/// because a reel is full-bleed video and anything else shows at the edges of
/// a clip that does not match the screen's aspect. The poster over it, held
/// until the video has actually drawn a frame. The spinner over that, visible
/// only while there is nothing to watch yet.
///
/// **No background colour.** It used to paint a seeded gradient under the
/// poster, which looked like a design element and was really an admission that
/// there was nothing to show — and it was what a reel with no poster sat on for
/// the whole of its buffering.
class ReelVideo extends StatelessWidget {
  const ReelVideo({
    super.key,
    required this.controller,
    required this.thumbnailUrl,
  });

  final VideoPlayerController? controller;

  /// Bunny Stream's generated poster, already resolved to a URL.
  ///
  /// Null until Stream has transcoded the video, which takes a few seconds
  /// after publishing — and permanently null for a reel uploaded before Stream
  /// existed. Neither is an error; the spinner simply has nothing behind it.
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl!,
              fit: BoxFit.cover,
              // Black underneath is the fallback; a broken-image glyph across
              // a full-bleed reel would read as a crash. A 404 here is the
              // normal state for a few seconds after publishing, while Stream
              // is still making the poster.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

          if (c != null)
            // Listens to the controller itself, so the swap from poster to
            // video happens on the frame the video starts — not whenever the
            // screen next happens to rebuild.
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (_, value, __) {
                // "Initialised" is not "has drawn": the texture stays black
                // until the first decoded frame, which is exactly the black a
                // swipe landed on. Past zero means a frame is on the texture;
                // until then the poster keeps the page.
                final ready = value.isInitialized &&
                    value.size.width > 0 &&
                    value.position > Duration.zero;

                if (!ready) {
                  // Over the poster, not instead of it. A reel that has a
                  // still to show should show it WITH the spinner — the
                  // spinner says "coming", the still says what is coming.
                  return const _Buffering();
                }

                // `cover`, like every other vertical-video feed: a portrait
                // phone and a landscape clip share no aspect ratio, and
                // letterboxing a reel wastes the half of the screen the format
                // exists to fill.
                return FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(c),
                  ),
                );
              },
            )
          else
            // No controller yet — the cache has not reached this page. Same
            // state from the viewer's side as a buffering one, so it looks the
            // same rather than sitting inert.
            const _Buffering(),
        ],
      ),
    );
  }
}

/// The one thing on screen while a reel has nothing to play.
///
/// Deliberately small and white: it sits over a photographic poster, where a
/// tinted or oversized indicator competes with the image it is waiting on.
/// Indeterminate, because HLS reports no meaningful fraction before the first
/// segment lands — a progress bar that sat at zero and then jumped would say
/// less than a spinner.
class _Buffering extends StatelessWidget {
  const _Buffering();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Colors.white,
      ),
    ),
  );
}
