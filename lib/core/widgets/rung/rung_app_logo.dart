import 'package:flutter/material.dart';

/// The app's own mark, as shown inside the app — splash and the sign-in hero.
///
/// Not to be confused with [RungLogoTile] in `rung_avatar.dart`, which is a
/// generated monogram tile standing in for a COMPANY that has no avatar. This
/// one is the product's identity and is always the same image.
///
/// The artwork carries its own transparency, so it is clipped rather than
/// boxed: painting a background behind it would show as a hard square over the
/// brand gradient both callers sit on.
class RungAppLogo extends StatelessWidget {
  const RungAppLogo({super.key, this.size = 96, this.radius});

  final double size;

  /// Corner rounding. Null derives it from [size] at [_radiusRatio], so the
  /// mark keeps one silhouette at every size rather than looking boxier as it
  /// grows, which is what a fixed radius does.
  final double? radius;

  /// iOS squircle territory. Rounder than the fixed 22-on-78 it replaced,
  /// without tipping into a circle and clipping the helmet.
  static const double _radiusRatio = 0.30;

  /// How much larger than its box the artwork is drawn, so it reaches the
  /// rounded edge on every side.
  ///
  /// Measured, not guessed: in the 512px master the opaque pixels run from
  /// (23, 29) to (467, 473) — a 444px mark inside a 512px canvas, so roughly
  /// 13% of every side is transparent padding. Painted at exactly [size] that
  /// padding becomes a visible gap, and the mark reads small and square inside
  /// its own clip. 512 / 444 = 1.153; 1.16 covers it with a hair to spare.
  ///
  /// The overflow is safe to clip away: the artwork's own corners are rounded
  /// at about 17% of its side, well inside [_radiusRatio], so the clip always
  /// cuts through opaque pixels and never leaves a transparent notch.
  static const double _artScale = 1.16;

  double get _r => radius ?? size * _radiusRatio;

  @override
  Widget build(BuildContext context) {
    final art = size * _artScale;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_r),
        // OverflowBox, so drawing the image larger than the box does not also
        // make the widget larger — the extra is painted and then clipped.
        child: OverflowBox(
          maxWidth: art,
          maxHeight: art,
          child: Image.asset(
            'assets/icon/app_logo.png',
            width: art,
            height: art,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            // The splash is the first frame of the app. If the asset is
            // somehow missing, a monogram is a far better failure than a red
            // error box across the launch screen. Sized to the BOX, not the
            // scaled art, so its border is not clipped off.
            errorBuilder: (context, _, __) => SizedBox(
              width: size,
              height: size,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(_r),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: Text(
                  'ر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
