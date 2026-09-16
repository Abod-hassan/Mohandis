import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// Selectable filter chip — accent-filled when on, outlined when off.
/// Used by the jobs work-mode row and the search tab row.
class RungFilterChip extends StatelessWidget {
  const RungFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Jobs filters carry an outline when unselected; search tabs use a filled
  /// neutral surface instead.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: RungRadius.pill,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? c.accent
                : outlined
                    ? c.surface
                    : c.surface2,
            borderRadius: RungRadius.pill,
            border: outlined
                ? Border.all(
                    color: selected ? c.accent : c.line2,
                    width: 1.5,
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : c.ink2,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Static metadata chip — salary, work mode, skill tag, job type.
class RungTagChip extends StatelessWidget {
  const RungTagChip({
    super.key,
    required this.label,
    this.emphasis = RungTagEmphasis.neutral,
    this.bordered = false,
  });

  final String label;
  final RungTagEmphasis emphasis;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final (fg, bg) = switch (emphasis) {
      RungTagEmphasis.accent => (c.accent, c.accentSoft),
      RungTagEmphasis.neutral => (c.ink2, c.surface2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: bordered ? Border.all(color: c.line) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

enum RungTagEmphasis { accent, neutral }

/// Inline hashtag rendered in accent, as seen under post text.
class RungHashtag extends StatelessWidget {
  const RungHashtag({super.key, required this.tag, this.onTap});

  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        tag,
        style: TextStyle(
          color: context.rung.accent,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}
