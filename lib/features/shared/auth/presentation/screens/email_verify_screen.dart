import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../notifiers/auth_notifier.dart';
import '../notifiers/pending_email.dart';
import '../widgets/code_boxes.dart';

/// The optional second factor: attach a confirmed e-mail to the account.
///
/// Optional and never blocking, by design. The phone is the identity — it is
/// proved at sign-up and it is what recovers the account — so nothing here
/// gates anything. What a confirmed address buys is a second way in
/// (`/api/Auth/Email/VerifyCode` only signs in an address that has been
/// confirmed) and a channel that survives losing the number.
///
/// Reachable from two places for two reasons: from the profile step, once,
/// while the address someone typed at sign-up is still in hand; and from
/// Settings, forever, which is where a person goes looking for it later.
class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  /// The address a code was actually sent to. Null until one has been sent —
  /// which is also what decides which of the two steps is on screen, so a
  /// half-edited field can never be confirmed against a code sent elsewhere.
  String? _sentTo;

  bool _busy = false;
  String? _error;

  int _cooldown = 0;
  Timer? _cooldownTimer;

  /// Matches `_AuthScreenState._emailShape`. Shape only — whether the mailbox
  /// exists is answered by the code arriving in it.
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  static const _resendCooldown = 60;
  static const _codeLength = 6;

  @override
  void initState() {
    super.initState();
    // Prefilled with whatever they typed at sign-up, when they came straight
    // here from the profile step. Empty otherwise — from Settings this is a
    // blank form, and it is also how someone CHANGES the address.
    final pending = ref.read(pendingEmailProvider);
    if (pending != null) _email.text = pending;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    // The form only exists on the address step — `_formKey.currentState` is
    // null once the code step has replaced it, and validating unconditionally
    // made every Resend a silent no-op. A resend goes to the address the code
    // was already sent to, not to whatever the field happens to hold.
    if (_sentTo == null && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final address = _sentTo ?? _email.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .sendEmailCode(address);
    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      success: (_) {
        setState(() {
          _sentTo = address;
          _code.clear();
        });
        _startCooldown();
      },
      failure: (e) => setState(() => _error = arabicMessageForException(e)),
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _confirm() async {
    final address = _sentTo;
    if (address == null || _busy) return;

    final code = _code.text.trim();
    if (code.length < _codeLength) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .confirmEmail(email: address, code: code);

    if (!mounted) return;

    result.when(
      success: (_) {
        // The offer is spent whether it came from sign-up or from Settings.
        ref.read(pendingEmailProvider.notifier).dismiss();
        // Cleared before leaving rather than left to disposal: on a cold deep
        // link straight to this route there is nothing to pop to, and a screen
        // that stays behind with `_busy` set is frozen — spinner on, boxes
        // disabled, and no way to try anything again.
        setState(() => _busy = false);
        showRungToast(context, context.l10n.emailVerifyDone);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/feed');
        }
      },
      failure: (e) => setState(() {
        _busy = false;
        _error = arabicMessageForException(e);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.emailVerifyTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            RungSpace.gutter,
            RungSpace.lg,
            RungSpace.gutter,
            RungSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sentTo == null
                        ? Icons.shield_outlined
                        : Icons.mark_email_unread_outlined,
                    size: 32,
                    color: c.accent,
                  ),
                ),
              ),
              const SizedBox(height: RungSpace.md),
              if (_sentTo == null)
                _addressStep(c, l10n)
              else
                _codeStep(c, l10n, _sentTo!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressStep(RungColors c, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.emailVerifyIntro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.ink2, height: 1.6),
          ),
          const SizedBox(height: RungSpace.lg),

          RungField(
            label: l10n.authEmail,
            hint: l10n.authEmailHint,
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _send(),
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return l10n.authRequiredField;
              if (!_emailShape.hasMatch(v)) return l10n.authEmailInvalid;
              return null;
            },
          ),

          _errorSlot(c),

          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy ? const _ButtonSpinner() : Text(l10n.emailVerifySend),
          ),
        ],
      ),
    );
  }

  Widget _codeStep(RungColors c, AppLocalizations l10n, String address) {
    final canResend = _cooldown <= 0 && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.authVerifyCodeTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: RungSpace.xs),
        Text(
          l10n.authVerifySentTo,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.ink3, height: 1.5),
        ),
        Text(
          address,
          textAlign: TextAlign.center,
          // An address reads left-to-right even on an RTL page.
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
        const SizedBox(height: RungSpace.lg),

        CodeBoxes(
          controller: _code,
          focusNode: _codeFocus,
          length: _codeLength,
          enabled: !_busy,
          hasError: _error != null,
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
            if (value.length == _codeLength) _confirm();
          },
        ),

        _errorSlot(c),

        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const _ButtonSpinner()
              : Text(l10n.authVerifyConfirm),
        ),
        const SizedBox(height: RungSpace.md),

        // A Wrap, not a Row: these are two inflexible Texts plus a countdown
        // suffix, and at a large text scale on a narrow phone a Row of them
        // overflows. Wrapping to a second line is the right answer here.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(
              l10n.authVerifyNoCode,
              style: TextStyle(fontSize: 13, color: c.ink3),
            ),
            GestureDetector(
              onTap: canResend ? _send : null,
              child: Text(
                _cooldown > 0
                    ? '${l10n.authVerifyResend} ($_cooldown)'
                    : l10n.authVerifyResend,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: canResend ? c.accent : c.ink3,
                ),
              ),
            ),
          ],
        ),

        // The way back to the field, for a typo in the address itself — the
        // one mistake resending the same code cannot fix.
        Center(
          child: TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _sentTo = null;
                    _error = null;
                    _code.clear();
                  }),
            child: Text(l10n.emailVerifyChangeAddress),
          ),
        ),
      ],
    );
  }

  /// Reserved height, so an error appearing does not shove the button down
  /// under the thumb that is already reaching for it — a MINIMUM rather than a
  /// fixed one, because at a large text scale two lines of 12.5pt do not fit
  /// in 34 and a fixed box clips them.
  Widget _errorSlot(RungColors c) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 34),
    child: Center(
      child: _error == null
          ? const SizedBox.shrink()
          : Text(
              _error!,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 12.5, color: c.red, height: 1.4),
            ),
    ),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(Colors.white),
    ),
  );
}
