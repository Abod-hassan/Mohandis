import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/dial_codes.dart';
import 'package:mohandis/l10n/l10n.dart';

/// What the form currently knows about whether a value is free to register.
enum FieldAvailability {
  /// Nothing asked yet — too short, untouched, or the field is empty.
  idle,

  /// A request is in flight.
  checking,

  /// The server says free.
  available,

  /// The server says taken.
  taken,

  /// We asked and could not get an answer.
  ///
  /// Distinct from [taken] on purpose. A probe that times out must not read as
  /// "this username is yours" NOR block the form — the person is put through
  /// to submit, where the real registration call is the authority.
  unknown,
}

/// The line under a username or phone field that says whether it is free.
///
/// Sized so the row does not jump: an empty state still occupies its height,
/// because a hint that appears and pushes the rest of a form down while
/// someone is typing into it is worse than no hint.
class AvailabilityHint extends StatelessWidget {
  const AvailabilityHint({
    super.key,
    required this.state,
    required this.takenLabel,
  });

  final FieldAvailability state;

  /// "That username is taken" / "That number already has an account" — the
  /// only string that differs between the two fields.
  final String takenLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final (icon, text, color) = switch (state) {
      FieldAvailability.idle => (null, null, c.ink3),
      FieldAvailability.checking => (null, l10n.authChecking, c.ink3),
      FieldAvailability.available => (
        Icons.check_circle_outline,
        l10n.authAvailable,
        c.green,
      ),
      FieldAvailability.taken => (Icons.error_outline, takenLabel, c.red),
      // Silent. Saying "we could not check" about a field the person has not
      // failed at yet is noise about our own plumbing.
      FieldAvailability.unknown => (null, null, c.ink3),
    };

    // minHeight, not a fixed height. The hint's text inherits the theme's 1.5
    // line height, which is 17.25px at 11.5pt and overflows an 18px cage the
    // moment anyone turns text scaling up — and this form has two of these
    // rows. A floor keeps the layout from jumping without capping the text.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.textScalerOf(context).scale(18),
      ),
      child: text == null
          ? const SizedBox.shrink()
          : Row(
              children: [
                if (state == FieldAvailability.checking)
                  SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A phone input with the country's dial code in front of it.
///
/// The number leaves this widget as E.164 and only as E.164 — see
/// [PhoneFormat.e164]. Before this existed the field took whatever anyone
/// typed and sent it verbatim, which meant `0770…`, `+964 770…` and `964770…`
/// all reached the server as three different people.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.code,
    required this.onCode,
    required this.enabled,
    this.validator,
  });

  final TextEditingController controller;
  final DialCode code;
  final ValueChanged<DialCode> onCode;
  final bool enabled;
  final String? Function(String?)? validator;

  Future<void> _pick(BuildContext context) async {
    final c = context.rung;
    final picked = await showModalBottomSheet<DialCode>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RungRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: RungSpace.sm),
          children: [
            for (final option in kDialCodes)
              ListTile(
                dense: true,
                leading: Text(
                  option.flag,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(
                  option.arabicName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  option.display,
                  // The dial code is a number and reads left-to-right even in
                  // an RTL sheet; without this the `+` lands on the wrong end.
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 13.5, color: c.ink3),
                ),
                selected: option.iso == code.iso,
                selectedTileColor: c.surface3,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onCode(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.authPhone,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.ink3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed height rather than stretched: the number field grows when
            // it shows a validation message, and a country button that grew
            // with it would leave the flag floating in the middle of nothing.
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: enabled ? () => _pick(context) : null,
                style: OutlinedButton.styleFrom(
                  // MUST be set. The app's outlinedButtonTheme uses
                  // `Size.fromHeight(48)`, which is `Size(double.infinity, 48)`
                  // — an infinite MINIMUM width. In a bounded parent that is
                  // harmless: `enforce` clamps it down to the parent's width,
                  // which is exactly how every full-width button in this app
                  // gets its width. Here the parent is a Row, and a Row hands
                  // its non-flex children an UNBOUNDED width, so nothing clamps
                  // it: the button asks to be laid out at `minWidth: Infinity`,
                  // `BoxConstraints.debugAssertIsValid` throws, and layout dies
                  // there — taking the rest of the form with it, un-laid-out
                  // and unpaintable for the life of the screen.
                  //
                  // Zero because the SizedBox above already fixes the height.
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: BorderSide(color: c.line),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(RungRadius.sm),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(code.flag, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 6),
                    Text(
                      code.display,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 18, color: c.ink3),
                  ],
                ),
              ),
            ),
            const SizedBox(width: RungSpace.xs),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                // Digits only. A paste of `+964 770-182-7031` would otherwise
                // sit next to a country code that already says +964.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // The number itself is LTR even though the form is not.
                textDirection: TextDirection.ltr,
                validator: validator,
                style: TextStyle(fontSize: 14, color: c.ink),
                decoration: InputDecoration(
                  hintText: l10n.authPhoneHint,
                  hintTextDirection: TextDirection.ltr,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
