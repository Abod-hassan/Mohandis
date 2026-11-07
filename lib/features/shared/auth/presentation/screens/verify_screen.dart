import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/registration.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/pending_email.dart';
import '../notifiers/registration_draft.dart';
import '../widgets/code_boxes.dart';

/// Step 2 of sign-up: prove the phone — or the e-mail, when no phone was
/// given — then spend the token.
///
/// **One channel per sign-up.** `CreateWithContact` takes exactly one
/// registration token, and a token proves exactly one channel. The phone wins
/// when both were given; the e-mail is then handed to [pendingEmailProvider]
/// on the way out and offered as the second factor on the profile step.
///
/// E-mail-only sign-up exists for App Store guideline 5.1.1(v) — a phone
/// number may not be required when another verified channel works. Such an
/// account recovers its password through the e-mail channel of
/// `ForgotPasswordScreen`.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();

  bool _busy = false;
  String? _error;

  /// Seconds left before the code can be sent again. The server throttles
  /// resends (`otp_resend_too_soon`), so the button is disabled rather than
  /// letting someone earn an error by tapping.
  int _cooldown = 0;
  Timer? _cooldownTimer;

  static const _resendCooldown = 60;
  static const _codeLength = 6;

  @override
  void initState() {
    super.initState();
    // After the frame — sending a code reads a provider and sets state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(registrationDraftProvider) != null) _send();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final draft = ref.read(registrationDraftProvider);
    if (draft == null || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final result = draft.verifiesByEmail
        ? await repository.sendEmailCode(draft.email!)
        : await repository.sendPhoneCode(draft.phone!);

    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      success: (_) => _startCooldown(),
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
    final draft = ref.read(registrationDraftProvider);
    if (draft == null || _busy) return;

    final code = _code.text.trim();
    if (code.length < _codeLength) return;

    // Read before the draft is spent: `completeRegistration` clears it the
    // moment the account exists, and this is the only copy of the address.
    final email = draft.email;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final verified = draft.verifiesByEmail
        ? await repository.verifyEmailCode(email: draft.email!, code: code)
        : await repository.verifyPhoneCode(phone: draft.phone!, otp: code);

    if (!mounted) return;

    final outcome = verified.valueOrNull;
    if (outcome == null) {
      setState(() {
        _busy = false;
        _error = arabicMessageForException(verified.errorOrNull!);
      });
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);

    // The two outcomes share a wire shape and mean opposite things — see
    // VerificationOutcome. A session means this number already had an
    // account: let them in rather than refusing a duplicate.
    switch (outcome) {
      case VerifiedSession(:final session):
        await notifier.adoptSession(session);

      case RegistrationToken(:final token):
        final created = await notifier.completeRegistration(
          draft: draft,
          registrationToken: token,
        );
        if (!mounted) return;
        if (created.isFailure) {
          setState(() {
            _busy = false;
            _error = arabicMessageForException(created.errorOrNull!);
            // The OTP was redeemed by the call BEFORE this one, so it is
            // spent whatever happened next. Leaving the digits sitting in the
            // boxes invites a second tap on Confirm, which re-posts a burned
            // code and answers "wrong code" — hiding the real reason, which
            // is the one already on screen.
            _code.clear();
          });
          return;
        }
        // A brand-new account, and they gave us an address for it. Only now
        // is there a session to attach it to.
        // Not when the e-mail WAS the channel: the registration token already
        // proved it, and the server attached it to the account.
        if (!draft.verifiesByEmail && email != null && email.isNotEmpty) {
          ref.read(pendingEmailProvider.notifier).offer(email);
        }
    }

    // Either way there is a session now, and the router's redirect takes it
    // from here. Popping first stops this screen being the thing the feed is
    // pushed on top of.
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final draft = ref.watch(registrationDraftProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.authVerifyTitle),
      // A draft is the whole input of this screen. Without one — a deep link,
      // a restore after the process was killed — there is nothing to verify
      // and no way to reconstruct it, so say so instead of rendering a form
      // that cannot submit.
      body: draft == null
          ? EmptyView(
              title: l10n.authVerifyTitle,
              message: l10n.authVerifyNoDraft,
              icon: Icons.verified_user_outlined,
              // The app bar's back button has nothing to pop to when this
              // route was opened cold, so the way out is spelled out.
              action: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: RungSpace.lg,
                  ),
                ),
                onPressed: () => context.go('/auth'),
                child: Text(l10n.authVerifyRestart),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  RungSpace.gutter,
                  RungSpace.lg,
                  RungSpace.gutter,
                  RungSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: _codeEntry(draft, c, l10n),
              ),
            ),
    );
  }

  Widget _codeEntry(
    RegistrationDraft draft,
    RungColors c,
    AppLocalizations l10n,
  ) {
    final canResend = _cooldown <= 0 && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: RungSpace.sm),

        // The badge does the work a paragraph would otherwise have to: it says
        // "a message is on its way" before anything is read.
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
              draft.verifiesByEmail
                  ? Icons.mark_email_unread_outlined
                  : Icons.sms_outlined,
              size: 32,
              color: c.accent,
            ),
          ),
        ),
        const SizedBox(height: RungSpace.md),

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
          draft.verifiesByEmail ? draft.email! : draft.phone!,
          textAlign: TextAlign.center,
          // A number reads left-to-right even on an RTL page. Without this
          // `+9647…` renders as `9647…+`.
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
            // Submit itself once the last digit lands — a code screen that
            // still wants a button press after the code is complete is a step
            // nobody wants.
            if (value.length == _codeLength) _confirm();
          },
        ),

        // Reserved height, so an error appearing does not shove the button
        // down under the thumb already reaching for it — a MINIMUM rather
        // than a fixed one, because two lines of scaled 12.5pt do not fit in
        // 34 and a fixed box clips them.
        ConstrainedBox(
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
        ),

        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(l10n.authVerifyConfirm),
        ),
        const SizedBox(height: RungSpace.md),

        // One sentence rather than two competing buttons: the question, then
        // the action, then the countdown that explains why it is inert.
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

        // Says why there is no e-mail option here, to someone who just typed
        // an address into the form and is now looking at a phone code.
        if (draft.hasEmail && !draft.verifiesByEmail) ...[
          const SizedBox(height: RungSpace.md),
          Text(
            l10n.authVerifyEmailLater,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: c.ink3, height: 1.5),
          ),
        ],
      ],
    );
  }
}
