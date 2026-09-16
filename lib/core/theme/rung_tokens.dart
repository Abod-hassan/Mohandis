import 'package:flutter/material.dart';

/// Non-colour design tokens: type scale, 4px spacing scale, corner radii,
/// elevation, and motion. Colours live in `rung_colors.dart`.
class RungType {
  RungType._();

  /// The single family used app-wide. Bundled in `assets/fonts/`.
  ///
  /// Tajawal: Arabic and Latin from one typeface, so the mixed strings all over
  /// this app (names beside usernames, hashtags, counts) stop coming from two
  /// faces that disagree about x-height.
  ///
  /// Weights are declared in pubspec.yaml. Two things differ from the family
  /// this replaced: Tajawal has a real ExtraBold, so w800 headings no longer
  /// borrow Bold; and it has no SemiBold, so w600 — this app's meta weight for
  /// timestamps, counts and chips — is mapped onto Medium.
  static const String family = 'Tajawal';

  static const display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.1,
  );
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static const heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const body = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
}

/// 4px base spacing scale.
class RungSpace {
  RungSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;

  /// Standard horizontal screen gutter.
  static const double gutter = 16;

  /// Height of the thick divider the design uses between feed cards.
  static const double sectionGap = 8;
}

/// Corner radii. `full` is expressed as a very large value so it can be
/// dropped into `BorderRadius.circular` for pill shapes.
class RungRadius {
  RungRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 22;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}

/// Subtle, cool-tinted elevation. `e2` is accent-tinted for primary buttons.
class RungElevation {
  RungElevation._();

  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x591E50D2),
      blurRadius: 18,
      spreadRadius: -4,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x660F172A),
      blurRadius: 30,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];
}

/// Motion — calm and purposeful. 200–350ms, standard-decelerate easing.
class RungMotion {
  RungMotion._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve easing = Curves.easeOutCubic;
}

/// Brand gradients reused by the auth hero, avatars, and cover art.
class RungGradients {
  RungGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF16368C), Color(0xFF1E50D2), Color(0xFF22B8A0)],
    stops: [0, 0.52, 1],
  );

  static const LinearGradient storyRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E50D2), Color(0xFF22B8A0)],
  );

  /// The palette avatars and company logos cycle through. Index by a stable
  /// hash of the entity id so the same person always gets the same colours.
  static const List<List<Color>> avatarPalette = [
    [Color(0xFF1E50D2), Color(0xFF3F7FF5)],
    [Color(0xFF0E7C6B), Color(0xFF22B8A0)],
    [Color(0xFF7B3FE4), Color(0xFFA06BF5)],
    [Color(0xFFC2410C), Color(0xFFF97316)],
    [Color(0xFF0F172A), Color(0xFF475569)],
    [Color(0xFFBE185D), Color(0xFFEC4899)],
    [Color(0xFF0369A1), Color(0xFF0EA5E9)],
    [Color(0xFFB45309), Color(0xFFD97706)],
    [Color(0xFF4338CA), Color(0xFF6366F1)],
  ];

  static LinearGradient forSeed(String seed) {
    final pair = avatarPalette[seed.hashCode.abs() % avatarPalette.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: pair,
    );
  }
}
