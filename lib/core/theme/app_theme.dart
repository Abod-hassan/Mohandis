import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'rung_colors.dart';
import 'rung_tokens.dart';

/// Rung's Material theme, built entirely from the design-system tokens in
/// `rung_colors.dart` / `rung_tokens.dart`.
///
/// Widgets SHALL NOT re-declare `fontFamily` — it is set once here and
/// inherited (ARCHITECTURE.md §16.3).
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(RungColors.light, Brightness.light);

  static ThemeData dark() => _build(RungColors.dark, Brightness.dark);

  static ThemeData _build(RungColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.accent,
      onSecondary: Colors.white,
      error: c.red,
      onError: Colors.white,
      errorContainer: c.redSoft,
      onErrorContainer: c.red,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface2,
      surfaceContainer: c.surface2,
      surfaceContainerHigh: c.surface3,
      surfaceContainerHighest: c.surface3,
      onSurfaceVariant: c.ink2,
      outline: c.line2,
      outlineVariant: c.line,
    );

    final text = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: RungType.family,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.surface,
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      textTheme: text,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: RungType.styled(RungType.heading).copyWith(
          color: c.ink,
        ),
        shape: Border(bottom: BorderSide(color: c.line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.surface3,
          disabledForegroundColor: c.ink3,
          // `Size.fromHeight` is `Size(double.infinity, 48)` — an infinite
          // MINIMUM width. That is what makes buttons fill their parent, and
          // it is safe in every bounded parent because `enforce` clamps it to
          // the parent's width.
          //
          // It is NOT safe in an unbounded-width slot — a Row's non-flex
          // child, or anything inside a horizontal scroll view. There nothing
          // clamps it, the button asks to be laid out at `minWidth: Infinity`,
          // `BoxConstraints.debugAssertIsValid` throws, and that frame's layout
          // is abandoned: the rest of the subtree is never laid out, painted or
          // hit-tested again. Any button placed directly in a Row must override
          // `minimumSize` — see PhoneNumberField and the people list.
          minimumSize: const Size.fromHeight(48),
          textStyle: RungType.styled(RungType.label).copyWith(
            fontSize: 15,
          ),
          shape: const RoundedRectangleBorder(borderRadius: RungRadius.pill),
        ),
      ),
      // The FAB, themed once for the three screens that raise one.
      //
      // Unthemed it fell through to Material 3's default, which paints an
      // extended FAB in `secondaryContainer` — a pale wash with accent-coloured
      // text. That reads as a disabled chip, not as the primary action on a
      // screen whose entire content is an empty state telling you to press it.
      // It takes the accent fill and white foreground every other primary
      // control in this app uses, so "the main thing to do here" looks the same
      // wherever it appears.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        splashColor: Colors.white.withValues(alpha: 0.16),

        // Lifted off the page. M3 defaults an extended FAB to elevation 3 and a
        // 16px rounded rect; against this bg the shadow was invisible and the
        // shape read as another card rather than as something floating over
        // the list it scrolls above.
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 3,

        // A stadium, like every other primary button here. Applied to the plain
        // circular FAB too, where a stadium on a square simply IS a circle — so
        // one entry covers both without a second theme.
        shape: const StadiumBorder(),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedIconLabelSpacing: 10,
        // The weight goes INSIDE styled(), not after it. `styled` reads
        // `fontWeight` to choose which Cairo file to load — a w800 applied
        // afterwards would leave it on the label's own weight and let Flutter
        // synthesise the difference, which is the faux bold this whole helper
        // exists to avoid.
        extendedTextStyle: RungType.styled(
          RungType.label.copyWith(fontWeight: FontWeight.w800),
        ).copyWith(
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          // Infinite minimum width — see the note on filledButtonTheme above.
          // A button placed directly in a Row must override this.
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: c.accent, width: 1.5),
          textStyle: RungType.styled(RungType.label).copyWith(
            fontSize: 15,
          ),
          shape: const RoundedRectangleBorder(borderRadius: RungRadius.pill),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: RungType.styled(RungType.label),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: RungType.styled(RungType.body).copyWith(
          color: c.ink3,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.line2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.red, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        side: BorderSide(color: c.line),
        labelStyle: RungType.styled(RungType.caption).copyWith(
          color: c.ink2,
        ),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: RungType.styled(RungType.label).copyWith(
          color: c.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: RungRadius.mdAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surface3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.line2,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(RungColors c) {
    TextStyle s(TextStyle base, Color color) =>
        RungType.styled(base).copyWith(color: color);
    return TextTheme(
      displaySmall: s(RungType.display, c.ink),
      headlineSmall: s(RungType.title, c.ink),
      titleLarge: s(RungType.title, c.ink),
      titleMedium: s(RungType.heading, c.ink),
      titleSmall: s(RungType.label, c.ink),
      bodyLarge: s(RungType.body.copyWith(fontSize: 15), c.ink),
      bodyMedium: s(RungType.body, c.ink),
      bodySmall: s(RungType.caption, c.ink2),
      labelLarge: s(RungType.label, c.ink),
      labelMedium: s(RungType.caption, c.ink2),
      labelSmall: s(RungType.micro, c.ink3),
    );
  }
}
