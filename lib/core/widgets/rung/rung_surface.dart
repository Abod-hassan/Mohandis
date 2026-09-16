import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// The bordered, softly-elevated card the whole app is built from.
class RungCard extends StatelessWidget {
  const RungCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.radius = RungRadius.md,
    this.elevated = true,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final decorated = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
        boxShadow: elevated ? RungElevation.e1 : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return decorated;
  }
}

/// Full-bleed surface block separated from its neighbours by the design's
/// 8px background gap. Used for the stacked profile / network sections.
class RungSection extends StatelessWidget {
  const RungSection({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(RungSpace.gutter),
    this.gapBelow = RungSpace.sectionGap,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final double gapBelow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: gapBelow),
      color: c.surface,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: RungSpace.sm),
          ],
          child,
        ],
      ),
    );
  }
}

/// Uppercase-ish section label sitting above a grouped card
/// ("التعلّم", "الخدمات", "أدواتي").
class RungSectionLabel extends StatelessWidget {
  const RungSectionLabel(
    this.label, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      RungSpace.gutter,
      20,
      RungSpace.gutter,
      10,
    ),
  });

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: TextStyle(
          color: context.rung.ink3,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Card that groups a vertical run of [RungNavRow]s with hairline dividers.
class RungGroupedCard extends StatelessWidget {
  const RungGroupedCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, color: c.line));
      }
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(RungRadius.md + 2),
        border: Border.all(color: c.line),
        boxShadow: RungElevation.e1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// A single row inside a [RungGroupedCard] — icon tile, title, subtitle,
/// optional badge, and a disclosure chevron. `Icons.chevron_right` mirrors
/// under RTL (`matchTextDirection: true`), so it renders pointing left.
class RungNavRow extends StatelessWidget {
  const RungNavRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
    this.titleSuffix,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? badge;
  final Widget? titleSuffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: enabled ? c.ink : c.ink2,
                            ),
                          ),
                        ),
                        if (titleSuffix != null) ...[
                          const SizedBox(width: 6),
                          titleSuffix!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: c.ink3),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
              if (enabled) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: c.ink3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
