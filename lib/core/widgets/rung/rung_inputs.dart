import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// The neutral search field used on the top bar, jobs, messages, and search.
///
/// Pass [onTap] with no [controller] for the read-only "tap to open search"
/// affordance the feed top bar uses; pass a [controller] for a live field.
class RungSearchField extends StatelessWidget {
  const RungSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.height = 40,
    this.radius = 11,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final readOnly = controller == null && onChanged == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 17, color: c.ink3),
            const SizedBox(width: 9),
            Expanded(
              child: readOnly
                  ? Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      autofocus: autofocus,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: 14, color: c.ink),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: hint,
                        hintStyle: TextStyle(fontSize: 14, color: c.ink3),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled form field used across edit-profile and the apply flow.
class RungField extends StatelessWidget {
  const RungField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.height,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final int maxLines;
  final double? height;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Standard `TextFormField` validator. Supplying one drops the fixed row
  /// height — an error message needs room under the box, and a 44px cage
  /// clips it.
  final String? Function(String?)? validator;

  final ValueChanged<String>? onSubmitted;

  /// Lets the OS offer saved credentials. Worth setting on every auth field:
  /// without it, iOS will not offer to save the password at all.
  final Iterable<String>? autofillHints;

  final bool enabled;

  /// Hard character cap, matching whatever the server column allows.
  ///
  /// The counter is suppressed below — it would sit under the box and undo the
  /// fixed row height every other field in a form shares. The cap is here to
  /// stop a save failing on the server's length check, not to nag while
  /// someone types.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    // A fixed-height multiline field fills its box via `expands`, which
    // Flutter requires be paired with null min/max lines.
    final fillsBox = height != null && maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.ink3,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height:
              height ??
              (maxLines > 1 || validator != null ? null : 44),
          child: TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            enabled: enabled,
            maxLength: maxLength,
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            maxLines: obscureText ? 1 : (fillsBox ? null : maxLines),
            expands: fillsBox,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(fontSize: 14, color: c.ink),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bordered row with a title, subtitle, and a switch — the edit-profile
/// "open to work" / "private profile" toggles.
class RungToggleTile extends StatelessWidget {
  const RungToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool value;
  /// Null disables the switch. Passing a no-op callback instead would leave it
  /// looking fully interactive — Material reads non-null as enabled — so taps
  /// during an in-flight write would land on nothing and a drag would flip the
  /// thumb and spring back with no explanation.
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: RungRadius.mdAll,
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A one-of-many field that opens a sheet, rather than a row of chips.
///
/// Chips are right when the options are few, short, and worth seeing at a
/// glance — a filter row. They are wrong when a form asks several such
/// questions in a column: three options each, three questions, and the form is
/// nine rows deep before it has asked anything the person has to type. This
/// costs one row per question whatever the list grows to.
///
/// Built to match [RungField] and the account-type and discipline pickers, so
/// a form mixing typed and chosen answers reads as one control repeated.
class RungSelectField<T> extends StatelessWidget {
  const RungSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.subtitleOf,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;

  /// Optional mark for each option, drawn in a tinted square. Null draws none,
  /// and the rows close up rather than leaving an empty column.
  final IconData Function(T)? iconOf;

  /// Optional second line per option, for a choice whose name does not say
  /// what it means.
  final String Function(T)? subtitleOf;

  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final icon = iconOf?.call(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: label,
          value: labelOf(value),
          child: InkWell(
            onTap: enabled ? () => _open(context) : null,
            borderRadius: RungRadius.mdAll,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: enabled ? c.surface : c.surface2,
                borderRadius: RungRadius.mdAll,
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    _Mark(icon: icon, size: 30),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      labelOf(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, size: 20, color: c.ink3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final c = sheetContext.rung;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(RungRadius.lg),
              ),
            ),
            // Sized to its content, not to a fraction of the screen: these
            // lists are three or four rows, and a sheet that opens at three
            // quarters leaves a hole under the last one.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: RungSpace.sm),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: RungSpace.sm),
                for (final option in values)
                  _Option<T>(
                    label: labelOf(option),
                    subtitle: subtitleOf?.call(option),
                    icon: iconOf?.call(option),
                    selected: option == value,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
                const SizedBox(height: RungSpace.md),
              ],
            ),
          ),
        );
      },
    );

    // Null is a dismissal. A select always has a value, so there is no
    // "cleared" state to fall back to and nothing to report.
    if (chosen != null) onChanged(chosen);
  }
}

class _Option<T> extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RungSpace.gutter,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                _Mark(icon: icon!, size: 36, on: selected),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? c.accent : c.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Always holds its width, so the labels beside it do not shift
              // as the selection moves down the list.
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(Icons.check_rounded, size: 22, color: c.accent)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An option's icon in a tinted square — accent-filled while it is the chosen
/// one.
class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.size, this.on = false});

  final IconData icon;
  final double size;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? c.accent : c.accentSoft,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(icon, size: size * 0.55, color: on ? Colors.white : c.accent),
    );
  }
}
