import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// The accent verification rosette shown beside a name.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: context.rung.accent,
      semanticLabel: 'موثّق',
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
        count > 99 ? '٩٩+' : _arabic(count),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  static String _arabic(int value) => value
      .toString()
      .split('')
      .map((d) => String.fromCharCode(d.codeUnitAt(0) + 0x0660 - 0x30))
      .join();
}
