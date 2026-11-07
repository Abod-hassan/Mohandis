import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// The accent verification rosette shown beside a name.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14, this.color});

  final double size;

  /// Overrides the accent — for the handful of surfaces that are dark whatever
  /// the theme is, where a token picked for a light background disappears.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: color ?? context.rung.accent,
      semanticLabel: 'موثّق',
    );
  }
}

/// The mark beside a name, and the gap before it.
///
/// **One rosette for two different claims.** A staff-verified account and a
/// subscribed one get the same [VerifiedBadge]: a reader cannot tell them
/// apart, and that is the decision — the badge says "this account is marked",
/// not which of the two reasons marked it. The alternative, a second glyph in
/// its own colour, was built first and dropped; it is worth knowing why the
/// choice exists at all, because the two facts really are unrelated.
/// Verification is a person here deciding an account is who it says it is;
/// a subscription is a billing state that ends the day a card is declined.
/// Showing them identically means the older claim now also means "pays us",
/// and that is not something a product can walk back once people have learnt
/// it. Changing back is a one-line edit here and nowhere else.
///
/// Exists so the rule lives in ONE place. The badge is drawn on eighteen
/// surfaces — feed cards, comments, the reels rail, message threads, search
/// rows, two profile headers — and a condition written out eighteen times is
/// one that holds in seventeen.
///
/// Renders nothing at all when neither applies, including the spacing, so a
/// row of ordinary names has no stray gap in it.
class NameBadges extends StatelessWidget {
  const NameBadges({
    super.key,
    required this.verified,
    required this.subscribed,
    this.size = 14,
    this.gap = 5,
    this.onDark = false,
  });

  /// Staff-verified.
  final bool verified;

  /// Holds a live subscription. Draws the same mark as [verified].
  final bool subscribed;

  final double size;
  final double gap;

  /// For a surface that is dark whatever the theme is — a reel over video, a
  /// story's scrim — where the accent token, picked against a light
  /// background, disappears.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (!verified && !subscribed) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.only(start: gap),
      child: VerifiedBadge(size: size, color: onDark ? Colors.white : null),
    );
  }
}

/// Soft-background status pill: "متاح للعمل", "نتوظّف", "تم التقديم".
class RungStatusPill extends StatelessWidget {
  const RungStatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.leading,
    this.dense = false,
  });

  /// Green "open to work" variant.
  factory RungStatusPill.success(
    BuildContext context, {
    required String label,
    Widget? leading,
    bool dense = false,
  }) {
    final c = context.rung;
    return RungStatusPill(
      label: label,
      foreground: c.green,
      background: c.greenSoft,
      leading: leading,
      dense: dense,
    );
  }

  /// Accent "hiring" variant.
  factory RungStatusPill.accent(
    BuildContext context, {
    required String label,
    Widget? leading,
    bool dense = false,
  }) {
    final c = context.rung;
    return RungStatusPill(
      label: label,
      foreground: c.accent,
      background: c.accentSoft,
      leading: leading,
      dense: dense,
    );
  }

  final String label;
  final Color foreground;
  final Color background;
  final Widget? leading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 11,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: RungRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 5)],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small green dot used as the "open to work" leading glyph.
class RungDot extends StatelessWidget {
  const RungDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Red count badge used on the nav and the messages button.
class RungCountBadge extends StatelessWidget {
  const RungCountBadge({
    super.key,
    required this.count,
    this.background,
    this.borderColor,
  });

  final int count;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? c.red,
        borderRadius: RungRadius.pill,
        border: Border.all(color: borderColor ?? c.surface, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : _arabic(count),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  /// Western digits, like every number in the app — see `ArabicNumbers`.
  static String _arabic(int value) => value.toString();
}
