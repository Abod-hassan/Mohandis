import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// Gradient monogram avatar. The gradient is derived from [seed] (the
/// person's id) so the same person keeps the same colours everywhere —
/// feed, thread header, search result, story rail.
///
/// [ringState] renders the story ring: an accent→teal gradient when the
/// story is unseen, a flat neutral ring once viewed.
enum StoryRingState { none, unseen, seen }

class RungAvatar extends StatelessWidget {
  const RungAvatar({
    super.key,
    required this.seed,
    required this.initials,
    this.size = 44,
    this.ringState = StoryRingState.none,
    this.borderColor,
    this.borderWidth = 0,
    this.imageUrl,
  });

  final String seed;
  final String initials;
  final double size;
  final StoryRingState ringState;

  /// A fully-resolved photo URL, or null for the monogram.
  ///
  /// Pass the CDN URL, not the stored path — `imageUrlResolverProvider` turns
  /// one into the other. The monogram stays underneath and shows through while
  /// the image loads and if it fails, so a dead link degrades to initials
  /// rather than to a broken-image glyph.
  final String? imageUrl;

  /// Solid ring drawn immediately around the avatar — the design uses a
  /// surface-coloured one where an avatar overlaps a cover image.
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    final monogram = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RungGradients.forSeed(seed),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? c.surface,
                width: borderWidth,
              )
            : null,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            initials,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.34,
              height: 1,
            ),
          ),
        ),
      ),
    );

    final url = imageUrl?.trim();
    final avatar = url == null || url.isEmpty
        ? monogram
        : Stack(
            fit: StackFit.passthrough,
            children: [
              monogram,
              Positioned.fill(
                child: Padding(
                  // Inside the border, so a photo never covers the surface ring
                  // an avatar overlapping a cover image relies on.
                  padding: EdgeInsets.all(borderWidth),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      // Both fall through to the monogram already painted below.
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          );

    if (ringState == StoryRingState.none) return avatar;

    const ringWidth = 2.5;
    return Container(
      padding: const EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringState == StoryRingState.unseen
            ? RungGradients.storyRing
            : null,
        color: ringState == StoryRingState.seen ? c.line2 : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.surface, width: ringWidth),
        ),
        child: avatar,
      ),
    );
  }
}

/// Group-conversation avatar — a people glyph on the brand gradient.
class RungGroupAvatar extends StatelessWidget {
  const RungGroupAvatar({super.key, this.size = 50});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B3FE4), Color(0xFF1E50D2)],
        ),
      ),
      child: Icon(Icons.groups_outlined, color: Colors.white, size: size * 0.48),
    );
  }
}

/// Square company / school logo tile with a monogram.
class RungLogoTile extends StatelessWidget {
  const RungLogoTile({
    super.key,
    required this.seed,
    required this.monogram,
    this.size = 50,
    this.radius = 12,
  });

  final String seed;
  final String monogram;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RungGradients.forSeed(seed),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        monogram,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          height: 1,
        ),
      ),
    );
  }
}
