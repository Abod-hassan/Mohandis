import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/rung_colors.dart';

/// The 52px hairline-bordered header used by every pushed screen.
///
/// [preferredSize] is the bare 52px toolbar; `Scaffold` adds the status-bar
/// inset on top of it, so the widget itself lays out as
/// `SafeArea(top) + 52`. Never hard-code the total height here — doing so
/// makes the inner `SafeArea` eat the toolbar and clip the leading control.
///
/// The leading control defaults to a back chevron. `Icons.chevron_left` is
/// declared with `matchTextDirection: true`, so Flutter mirrors it under RTL
/// and it renders pointing right — the correct back affordance in Arabic.
/// Pass [leading] for the "إلغاء" text button the modal screens use.
class RungAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RungAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions = const [],
    this.showBack = true,
    this.titleStyle,
    this.background,
  }) : assert(
          title == null || titleWidget == null,
          'Pass either title or titleWidget, not both.',
        );

  final String? title;

  /// Rich title content (avatar + name stacks, search fields). Occupies the
  /// same expanded slot as [title] so it sits flush against the back button
  /// instead of being pushed to the far edge by the no-title [Spacer].
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBack;
  final TextStyle? titleStyle;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      decoration: BoxDecoration(
        color: background ?? c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else if (showBack)
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/feed'),
                    icon: const Icon(Icons.chevron_left, size: 24),
                    color: c.ink,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  )
                else
                  const SizedBox(width: 10),
                if (titleWidget != null)
                  Expanded(child: titleWidget!)
                else if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle ??
                          Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  const Spacer(),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon button on a neutral surface — used in headers and rails.
class RungIconButton extends StatelessWidget {
  const RungIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
    this.background,
    this.foreground,
    this.badge,
    this.shape = BoxShape.rectangle,
    this.radius = 11,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? background;
  final Color? foreground;
  final Widget? badge;
  final BoxShape shape;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final button = Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          shape == BoxShape.circle ? size : radius,
        ),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background ?? c.surface2,
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
          ),
          child: Icon(icon, size: size * 0.52, color: foreground ?? c.ink2),
        ),
      ),
    );

    if (badge == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(top: -2, start: -4, child: badge!),
      ],
    );
  }
}
