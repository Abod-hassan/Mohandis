import 'package:flutter/material.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import 'account_type_labels.dart';

/// The نوع الحساب control: one row showing the current kind, a sheet behind it
/// holding all five.
///
/// Five kinds laid out as buttons cost five rows before the form has asked its
/// first question, and the sign-up sheet has to fit a name, a handle, a phone
/// and an email above the fold. A row that opens a sheet costs one, whatever
/// the list grows to — and the sheet has the space to say what each kind
/// actually does, which the buttons never had.
///
/// Built like [DisciplineField] on purpose: these are the only two pickers in
/// the form, and a user who has tapped one should recognise the other.
class AccountTypeField extends StatelessWidget {
  const AccountTypeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final AccountType value;
  final ValueChanged<AccountType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.authAccountType,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: context.l10n.authAccountType,
          value: value.label(context),
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
                  _Mark(type: value, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value.label(context),
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
    final chosen = await showModalBottomSheet<AccountType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountTypeSheet(selected: value),
    );
    // Null is a dismissal, not a clearing: an account always has a kind, and
    // there is no empty state to fall back to.
    if (chosen == null) return;
    onChanged(chosen);
  }
}

class _AccountTypeSheet extends StatelessWidget {
  const _AccountTypeSheet({required this.selected});

  final AccountType selected;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    // Not a DraggableScrollableSheet: five rows have a known height, and a
    // sheet that opens at three quarters of the screen for five rows leaves a
    // hole under the last one.
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RungRadius.lg),
          ),
        ),
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
              context.l10n.authAccountTypeSheetTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: RungSpace.sm),
            for (final type in AccountType.values)
              _Row(
                type: type,
                selected: type == selected,
                onTap: () => Navigator.of(context).pop(type),
              ),
            const SizedBox(height: RungSpace.md),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
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
            vertical: 10,
          ),
          child: Row(
            children: [
              _Mark(type: type, size: 40, on: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label(context),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? c.accent : c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.summary(context),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Always occupies its width, so the text beside it does not
              // shift left and right as the selection moves down the list.
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

/// The type's icon in a tinted square — accent while it is the chosen one.
class _Mark extends StatelessWidget {
  const _Mark({required this.type, required this.size, this.on = false});

  final AccountType type;
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
      child: Icon(
        type.icon,
        size: size * 0.55,
        color: on ? Colors.white : c.accent,
      ),
    );
  }
}
