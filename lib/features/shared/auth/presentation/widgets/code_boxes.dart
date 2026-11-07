import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mohandis/core/theme/rung_colors.dart';

/// Six separate boxes over one real text field.
///
/// The field itself is invisible and fills the row, so the OS still treats
/// this as an ordinary input — the keyboard opens, a pasted code lands, and
/// iOS offers "From Messages" above it, none of which survives a row of six
/// independent controllers with focus hopping between them.
///
/// Shared rather than private to one screen: a code is entered twice in this
/// app — once to prove the phone at sign-up, once to confirm an e-mail as a
/// second factor — and the two have to look and behave identically.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final int length;
  final bool enabled;
  final bool hasError;

  /// False where the boxes appear under something the person must read or
  /// fill in first — an e-mail address, say — so the keyboard does not cover
  /// it the moment the screen opens.
  final bool autofocus;

  /// Gap between boxes, and the width a box takes when there is room for it.
  static const double _gap = 8;
  static const double _maxBox = 46;
  static const double _minBox = 30;

  @override
  Widget build(BuildContext context) {
    // Read here rather than inside the LayoutBuilder below: nothing in this
    // widget needs a theme lookup during the layout phase, and this codebase
    // has been bitten before by work done inside a layout callback.
    final c = context.rung;

    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          // Underneath, and transparent rather than absent: an Offstage or
          // zero-sized field cannot be focused, which is the whole point of it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: autofocus,
                keyboardType: TextInputType.number,
                maxLength: length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // Without this iOS never offers the code from Messages.
                autofillHints: const [AutofillHints.oneTimeCode],
                onChanged: onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // On top, and deaf to touches, so a tap anywhere on the row reaches
          // the field below and opens the keyboard.
          IgnorePointer(
            // Six 46px boxes and five 8px gaps is 316px, and both screens that
            // use this add a 16px gutter on each side — 348px of demand on a
            // 320pt phone, which is a RenderFlex overflow on the first screen
            // of sign-up. The boxes shrink instead.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final box = constraints.maxWidth.isFinite
                    ? (((constraints.maxWidth - _gap * (length - 1)) / length)
                          .clamp(_minBox, _maxBox))
                    : _maxBox;
                return AnimatedBuilder(
                  animation: Listenable.merge([controller, focusNode]),
                  builder: (context, _) {
                    final digits = controller.text;
                    // LTR regardless of the page: a code is read left to
                    // right, and the first digit typed must land in the
                    // first box.
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < length; i++) ...[
                            if (i > 0) const SizedBox(width: _gap),
                            _box(c, digits, i, box),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(RungColors c, String digits, int index, double width) {
    final filled = index < digits.length;
    // The box the next digit will land in, highlighted only while the field
    // actually holds focus — otherwise a dismissed keyboard leaves the row
    // looking like it is still waiting for a keystroke.
    final isNext = focusNode.hasFocus && index == digits.length;

    final border = hasError ? c.red : (filled || isNext ? c.accent : c.line);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: width,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: filled || isNext ? 1.6 : 1),
      ),
      child: Text(
        filled ? digits[index] : '',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: hasError ? c.red : c.ink,
        ),
      ),
    );
  }
}
