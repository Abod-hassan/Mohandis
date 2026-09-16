import 'package:flutter/material.dart';

/// Rung's colour vocabulary, exposed as a `ThemeExtension` so every widget
/// reads tokens off `Theme.of(context)` instead of hard-coding hex values.
///
/// Token names mirror the design system 1:1 (`--surface-2` → [surface2],
/// `--ink-3` → [ink3]) so a design change can be traced straight to code.
@immutable
class RungColors extends ThemeExtension<RungColors> {
  const RungColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.line2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentSoft2,
    required this.green,
    required this.greenSoft,
    required this.amber,
    required this.amberSoft,
    required this.red,
    required this.redSoft,
    required this.gold,
  });

  /// Light theme tokens — the design system's default.
  static const light = RungColors(
    bg: Color(0xFFEEF1F6),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F7FB),
    surface3: Color(0xFFEAEEF5),
    line: Color(0xFFE4E8F0),
    line2: Color(0xFFD5DBE6),
    ink: Color(0xFF111827),
    ink2: Color(0xFF48546B),
    ink3: Color(0xFF8592A6),
    accent: Color(0xFF1E50D2),
    accentInk: Color(0xFF163A97),
    accentSoft: Color(0xFFE7EDFC),
    accentSoft2: Color(0xFFD3E0FB),
    green: Color(0xFF178A55),
    greenSoft: Color(0xFFE0F2E9),
    amber: Color(0xFFB0740C),
    amberSoft: Color(0xFFFAF0D8),
    red: Color(0xFFC43D2E),
    redSoft: Color(0xFFFBE6E2),
    gold: Color(0xFFC98A12),
  );

  /// Dark theme tokens — full parity with [light]; every token has a
  /// counterpart so no widget needs a brightness branch.
  static const dark = RungColors(
    bg: Color(0xFF0C1017),
    surface: Color(0xFF161C26),
    surface2: Color(0xFF1D2530),
    surface3: Color(0xFF252E3B),
    line: Color(0xFF28313E),
    line2: Color(0xFF333E4D),
    ink: Color(0xFFEEF2F8),
    ink2: Color(0xFFA7B4C6),
    ink3: Color(0xFF6F7D90),
    accent: Color(0xFF5A86F0),
    accentInk: Color(0xFF8BADF7),
    accentSoft: Color(0xFF1B2740),
    accentSoft2: Color(0xFF22345A),
    green: Color(0xFF39BF82),
    greenSoft: Color(0xFF12241D),
    amber: Color(0xFFE0A53C),
    amberSoft: Color(0xFF2A2213),
    red: Color(0xFFF0796A),
    redSoft: Color(0xFF2A1815),
    gold: Color(0xFFE0A53C),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color line2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color accentSoft2;
  final Color green;
  final Color greenSoft;
  final Color amber;
  final Color amberSoft;
  final Color red;
  final Color redSoft;
  final Color gold;

  @override
  RungColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? line2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? accentSoft2,
    Color? green,
    Color? greenSoft,
    Color? amber,
    Color? amberSoft,
    Color? red,
    Color? redSoft,
    Color? gold,
  }) {
    return RungColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentSoft2: accentSoft2 ?? this.accentSoft2,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      red: red ?? this.red,
      redSoft: redSoft ?? this.redSoft,
      gold: gold ?? this.gold,
    );
  }

  @override
  RungColors lerp(ThemeExtension<RungColors>? other, double t) {
    if (other is! RungColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return RungColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      surface3: c(surface3, other.surface3),
      line: c(line, other.line),
      line2: c(line2, other.line2),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentSoft: c(accentSoft, other.accentSoft),
      accentSoft2: c(accentSoft2, other.accentSoft2),
      green: c(green, other.green),
      greenSoft: c(greenSoft, other.greenSoft),
      amber: c(amber, other.amber),
      amberSoft: c(amberSoft, other.amberSoft),
      red: c(red, other.red),
      redSoft: c(redSoft, other.redSoft),
      gold: c(gold, other.gold),
    );
  }
}

extension RungColorsX on BuildContext {
  /// Shorthand for the active [RungColors]. Falls back to light tokens so a
  /// widget rendered outside `AppTheme` (a bare `pumpWidget` in a test) still
  /// paints instead of throwing.
  RungColors get rung =>
      Theme.of(this).extension<RungColors>() ?? RungColors.light;
}
