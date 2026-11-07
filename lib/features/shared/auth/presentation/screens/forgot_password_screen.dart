import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/api/token_refresher.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/dial_codes.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/registration.dart';
import '../notifiers/auth_notifier.dart';
import '../widgets/auth_fields.dart';
import '../widgets/code_boxes.dart';

/// Forgot password: prove a channel, then set a new one.
///
/// There is no reset link and no reset token to carry around. The module
/// deleted the link flow — it never sent, pointed at a hardcoded internal IP,
/// and leaked account existence — and replaced it with something simpler:
/// proving a phone or an e-mail issues a REAL session stamped with the
/// `RecoveryVerified` role, and `ResetPassword` accepts that role as authority
/// to replace the account's own password with no old password. The target is
/// read from the token, so a session for one account can never reset another.
///
/// The consequence worth knowing: **the person is signed in from the moment
/// the code is accepted**, one step before they have a new password. That is
/// why `/auth/forgot` is exempt from the router's "authenticated users do not
/// belong under /auth" rule — without the exemption the redirect fires on the
/// session landing and strands them one step short of the thing they came for.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { identify, code, password }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifyKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _codeFocus = FocusNode();

  DialCode _dial = kDefaultDialCode;
  VerifyChannel _channel = VerifyChannel.phone;
  _Step _step = _Step.identify;

  /// The identifier a code was actually sent to, in the form the server keys
  /// it by — E.164 for a phone. Set only on a successful send, and the sole
  /// input to the verify call, so an edited field can never be confirmed
  /// against a code that went somewhere else.
  String? _sentTo;

  bool _busy = false;
  String? _error;

  /// True once the code was accepted and a session was adopted.
  ///
  /// Tracked separately from `_step` because it is the thing that makes
  /// leaving dangerous, and it outlives any one step: tapping "start again"
  /// returns to the identify step while the session is still live, and from
  /// there an ordinary back would land in the app with nothing reset. Every
  /// exit consults this, not the step.
  bool _recovered = false;

  int _cooldown = 0;
  Timer? _cooldownTimer;

  /// Matches `_AuthScreenState._emailShape`.
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  static const _resendCooldown = 60;
  static const _codeLength = 6;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    // The identify form is gone once the code step replaces it, so validating
    // unconditionally would make Resend a silent no-op.
    if (_sentTo == null && !(_identifyKey.currentState?.validate() ?? false)) {
      return;
    }

    final target =
        _sentTo ??
        (_channel.isPhone
            ? PhoneFormat.e164(_dial, _phone.text)
            : _email.text.trim());

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final result = _channel.isPhone
        ? await repository.sendPhoneCode(target)
        : await repository.sendEmailCode(target);

    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      success: (_) {
        setState(() {
          _sentTo = target;
          _step = _Step.code;
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

  Future<void> _confirmCode() async {
    final target = _sentTo;
    if (target == null || _busy) return;

    final code = _code.text.trim();
    if (code.length < _codeLength) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final verified = _channel.isPhone
        ? await repository.verifyPhoneCode(phone: target, otp: code)
        : await repository.verifyEmailCode(email: target, code: code);

    if (!mounted) return;

    final outcome = verified.valueOrNull;
    if (outcome == null) {
      setState(() {
        _busy = false;
        _error = arabicMessageForException(verified.errorOrNull!);
      });
      return;
    }

    switch (outcome) {
      case VerifiedSession(:final session):
        await ref.read(authNotifierProvider.notifier).adoptSession(session);
        if (!mounted) return;
        setState(() {
          _busy = false;
          _recovered = true;
          _step = _Step.password;
        });

      case RegistrationToken():
        // There is nothing to recover. The same call that signs an existing
        // account in answers a REGISTRATION token when the identifier belongs
        // to nobody — deliberately not adopted, since that token authorises
        // creating an account and this person asked to get back into one.
        setState(() {
          _busy = false;
          _code.clear();
          _error = _channel.isPhone
              ? context.l10n.forgotNoAccountPhone
              : context.l10n.forgotNoAccountEmail;
        });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!(_passwordKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(password: _password.text);

    if (!mounted) return;

    // The session in hand was minted by ValidateOTP with
    // `recoveryVerified: true` and lives for a DAY, during which it can
    // replace this account's password again with no old password.
    // `RefreshToken` re-mints without that claim, so one rotation closes the
    // window — and if the rotation does NOT happen, the window must not be
    // carried into the app. The password is changed either way, so the
    // fallback is to sign out and let them in with it.
    var rotated = false;
    if (result.isSuccess) {
      rotated =
          await ref.read(tokenRefresherProvider).refresh() ==
          RefreshOutcome.refreshed;
      if (!mounted) return;
    }

    result.when(
      success: (_) {
        setState(() {
          _busy = false;
          // The session has served its purpose and is an ordinary one now.
          _recovered = false;
        });
        showRungToast(context, context.l10n.forgotDone);
        if (!rotated) {
          // See above: never into the app on a recovery token.
          final router = GoRouter.of(context);
          ref.read(authNotifierProvider.notifier).logout().whenComplete(
            () => router.go('/auth'),
          );
          return;
        }
        // `go`, not `pop`. A pop does NOT re-run the router's redirect —
        // go_router only consults it on a navigation or a refreshListenable
        // tick, and nothing changes here — so popping would leave someone who
        // just reset their password looking at the sign-in form, signed in.
        context.go('/feed');
      },
      failure: (e) => setState(() {
        _busy = false;
        _error = arabicMessageForException(e);
        // The one failure that cannot be retried from this step: the token
        // lost its RecoveryVerified claim (a refresh rotated it), so the
        // server now wants the old password — the thing they do not have.
        // Proving the channel again is the only way forward, so the step goes
        // back rather than leaving a button that can no longer succeed.
        if (_recoveryExpired(e)) {
          _step = _Step.identify;
          _sentTo = null;
          _code.clear();
        }
      }),
    );
  }

  /// Back to proving a channel, dropping the session on the way.
  ///
  /// No confirmation: this is someone choosing to redo the flow, not leaving
  /// it. The sign-out is not optional though — the identify step needs no
  /// session, and a live recovery token sitting behind it is the same hole
  /// `_abandon` closes, reached by a different door.
  Future<void> _restart() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_recovered) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _recovered = false;
      _step = _Step.identify;
      _sentTo = null;
      _error = null;
      _code.clear();
    });
  }

  /// Leaving the recovery without setting a password.
  ///
  /// The session in hand was minted by the OTP and exists for exactly one
  /// purpose — authorising this reset. Walking away from the reset while
  /// keeping the session is the bug this whole branch exists to prevent: it
  /// is sign-in-by-OTP wearing a password-reset label, and it leaves the
  /// forgotten password working. So it is confirmed, and then it signs out.
  Future<void> _abandon() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.forgotLeaveTitle),
        content: Text(l10n.forgotLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.forgotLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Captured before the await: `logout` publishes a null session, and the
    // frame that unmounts this screen can land during the call.
    final router = GoRouter.of(context);
    await ref.read(authNotifierProvider.notifier).logout();
    // Explicit, because the redirect will not move us: with no session,
    // `/auth/forgot` is an ordinary unauthenticated auth route and is left
    // exactly where it is.
    router.go('/auth');
  }

  /// True when the server refused because the recovery proof is gone rather
  /// than because the password itself was rejected.
  bool _recoveryExpired(Object error) =>
      error.toString().toLowerCase().contains('current password is required');

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    // Once the code is accepted there IS a session — proving the phone is what
    // issues one. Leaving with it must NOT drop the person into the app: that
    // would turn forgot-password into sign-in-by-OTP, with the forgotten
    // password still the live one and nothing reset. So every way out from
    // here abandons the recovery and signs them back out.
    //
    // PopScope catches the system gesture; the app bar's own control is
    // replaced below, because `context.pop()` goes through `Navigator.pop`,
    // which does not consult PopScope at all.
    return PopScope(
      canPop: !_recovered,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _abandon();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: RungAppBar(
          title: l10n.forgotTitle,
          leading: _recovered
              ? IconButton(
                  onPressed: _busy ? null : _abandon,
                  icon: const Icon(Icons.chevron_left, size: 24),
                  color: c.ink,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                )
              : null,
        ),
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
                    child: Icon(_stepIcon, size: 32, color: c.accent),
                  ),
                ),
                const SizedBox(height: RungSpace.md),
                switch (_step) {
                  _Step.identify => _identifyStep(c, l10n),
                  _Step.code => _codeStep(c, l10n, _sentTo!),
                  _Step.password => _passwordStep(c, l10n),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _stepIcon => switch (_step) {
    _Step.identify => Icons.lock_reset_outlined,
    _Step.code => _channel.isPhone
        ? Icons.sms_outlined
        : Icons.mark_email_unread_outlined,
    _Step.password => Icons.password_outlined,
  };

  Widget _identifyStep(RungColors c, AppLocalizations l10n) {
    return Form(
      key: _identifyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotIntro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.ink2, height: 1.6),
          ),
          const SizedBox(height: RungSpace.md),

          Row(
            children: [
              // `onTap` is non-nullable on this chip, so "disabled" is a
              // callback that declines rather than an absent one.
              RungFilterChip(
                label: l10n.authPhone,
                selected: _channel.isPhone,
                onTap: () => _setChannel(VerifyChannel.phone),
              ),
              const SizedBox(width: RungSpace.xs),
              RungFilterChip(
                label: l10n.authEmail,
                selected: !_channel.isPhone,
                onTap: () => _setChannel(VerifyChannel.email),
              ),
            ],
          ),
          const SizedBox(height: RungSpace.md),

          if (_channel.isPhone)
            PhoneNumberField(
              controller: _phone,
              code: _dial,
              onCode: (code) => setState(() => _dial = code),
              enabled: !_busy,
              validator: (value) {
                final national = PhoneFormat.national(_dial, value ?? '');
                if (national.isEmpty) return l10n.authRequiredField;
                if (national.length < _dial.minNsnLength) {
                  return l10n.authPhoneInvalid;
                }
                return null;
              },
            )
          else
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
                final text = (value ?? '').trim();
                if (text.isEmpty) return l10n.authRequiredField;
                return _emailShape.hasMatch(text)
                    ? null
                    : l10n.authEmailInvalid;
              },
            ),

          _errorSlot(c),

          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy ? const _ButtonSpinner() : Text(l10n.forgotSend),
          ),
        ],
      ),
    );
  }

  /// Swaps which field is on screen. What was typed into the other one is
  /// KEPT — someone who flips to e-mail and back should find their number
  /// still there — and it is harmless: the hidden field leaves the tree, so
  /// its validator no longer runs.
  void _setChannel(VerifyChannel channel) {
    if (_busy || channel == _channel) return;
    setState(() {
      _channel = channel;
      _error = null;
    });
  }

  Widget _codeStep(RungColors c, AppLocalizations l10n, String target) {
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
          target,
          textAlign: TextAlign.center,
          // A number or an address reads left-to-right even on an RTL page.
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
            if (value.length == _codeLength) _confirmCode();
          },
        ),

        _errorSlot(c),

        FilledButton(
          onPressed: _busy ? null : _confirmCode,
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

        // The way back, for a typo in the number itself — the one mistake
        // resending the same code cannot fix. Also how someone who used the
        // wrong channel switches.
        Center(
          child: TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _step = _Step.identify;
                    _sentTo = null;
                    _error = null;
                    _code.clear();
                  }),
            child: Text(l10n.forgotChangeTarget),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(RungColors c, AppLocalizations l10n) {
    return Form(
      key: _passwordKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotSetTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: RungSpace.xs),
          Text(
            l10n.forgotSetSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.ink3, height: 1.5),
          ),
          const SizedBox(height: RungSpace.lg),

          RungField(
            label: l10n.forgotNewPassword,
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) return l10n.authRequiredField;
              // Identity's policy, checked here because its own rejection
              // arrives as English prose after a round-trip.
              if (text.length < 8) return l10n.authPasswordTooShort;
              final weak =
                  !RegExp(r'[0-9]').hasMatch(text) ||
                  !RegExp(r'[a-z]').hasMatch(text) ||
                  !RegExp(r'[A-Z]').hasMatch(text);
              return weak ? l10n.authPasswordWeak : null;
            },
          ),
          const SizedBox(height: RungSpace.sm),

          RungField(
            label: l10n.forgotConfirmPassword,
            controller: _confirm,
            enabled: !_busy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _save(),
            validator: (value) => (value ?? '') == _password.text
                ? null
                : l10n.forgotPasswordMismatch,
          ),

          _errorSlot(c),

          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const _ButtonSpinner() : Text(l10n.forgotSave),
          ),

          // The escape hatch. Without it this step has exactly one button, and
          // if the recovery proof has gone stale that button can never
          // succeed — see `_recoveryExpired`.
          Center(
            child: TextButton(
              onPressed: _busy ? null : _restart,
              child: Text(l10n.authVerifyRestart),
            ),
          ),
        ],
      ),
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
