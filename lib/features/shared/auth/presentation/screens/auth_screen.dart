import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/config/legal_links.dart';
import 'package:mohandis/core/utils/pick_cropped_image.dart';
import 'package:mohandis/core/api/session_expiry.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/services/tenant_store.dart';
import 'package:mohandis/core/utils/dial_codes.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_field.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/user.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/registration_draft.dart';
import '../widgets/auth_fields.dart';

/// Onboarding, sign-in and sign-up. The gradient hero sells the product; the
/// sheet carries the form, which switches between the two modes in place
/// rather than pushing a second screen.
///
/// **Registration is three backend calls** (contact → user → login), all
/// behind `AuthNotifier.register`. From here it is one submit.
enum _AuthMode { signIn, signUp }

/// Height the hero always keeps, however tall the sheet wants to be.
///
/// Enough for the compact composition — the logo tile and its breathing room.
/// Below this the brand strip stops reading as a header and starts looking
/// like a clipped mistake, which is exactly what it did when the sheet was
/// allowed to claim a fixed 82% of the screen.
const double _minHeroHeight = 132;

/// Where a completed sign-up form goes to prove an identity. Declared here
/// rather than imported from the router so the screen keeps no dependency on
/// the route table.
const String _verifyRoute = '/auth/verify';
const String _forgotRoute = '/auth/forgot';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  AccountType _accountType = AccountType.individual;
  /// Null until the person picks. The server enum has an `Unspecified` member
  /// but the app does not offer it, so this has to be answered before submit.
  Gender? _gender;

  /// Local path of the picked photo. Uploaded at submit time, not at pick
  /// time — an abandoned sign-up should not leave a file in the storage zone.
  String? _photoPath;

  /// Inline validation message for the gender row, which sits outside the Form.
  String? _genderError;

  bool _busy = false;

  /// The country the phone field is set to. Iraq until someone changes it.
  DialCode _dial = kDefaultDialCode;

  FieldAvailability _userNameState = FieldAvailability.idle;
  FieldAvailability _phoneState = FieldAvailability.idle;
  FieldAvailability _emailState = FieldAvailability.idle;

  Timer? _userNameDebounce;
  Timer? _phoneDebounce;
  Timer? _emailDebounce;

  /// Guards against a controller notification that is not a text change.
  /// `TextEditingController` also notifies when the cursor moves, and probing
  /// the server every time somebody taps into the middle of their own username
  /// is a request per tap for an answer we already have.
  String _lastUserNameProbe = '';
  String _lastPhoneProbe = '';
  String _lastEmailProbe = '';

  /// Which probe is the current one. A slow answer for a name the person has
  /// since typed past must not overwrite the answer for what is on screen now.
  int _userNameSeq = 0;
  int _phoneSeq = 0;
  int _emailSeq = 0;

  /// Long enough that typing a name does not fire a request per letter, short
  /// enough that the answer is there before a finger reaches the next field.
  static const _probeDebounce = Duration(milliseconds: 450);

  /// Below this there is nothing worth asking about — and the server refuses
  /// to answer anyway, so a shorter probe is a round-trip for a `too_short`.
  /// The phone's floor is per-country; see [DialCode.minNsnLength].
  static const _minUserNameProbe = 3;

  // ── Availability probes ──────────────────────────────────────────────────

  void _onUserNameChanged() {
    final value = _userName.text.trim();
    if (value == _lastUserNameProbe) return;
    _lastUserNameProbe = value;
    _userNameDebounce?.cancel();

    // Only sign-up asks. On sign-in the whole point is that the name already
    // exists, and a red "taken" under the field someone is signing in with
    // would be exactly backwards.
    if (_mode != _AuthMode.signUp || value.length < _minUserNameProbe) {
      _setUserNameState(FieldAvailability.idle);
      return;
    }

    _setUserNameState(FieldAvailability.checking);
    _userNameDebounce = Timer(_probeDebounce, () => _probeUserName(value));
  }

  Future<void> _probeUserName(String value) async {
    final seq = ++_userNameSeq;
    final asked = _mode;
    final result = await ref
        .read(authRepositoryProvider)
        .checkIdentity(userName: value);
    if (!mounted ||
        seq != _userNameSeq ||
        asked != _mode ||
        _userName.text.trim() != value) {
      return;
    }
    _setUserNameState(
      result.when(
        success: (a) => a.userNameTaken
            ? FieldAvailability.taken
            : FieldAvailability.available,
        // Not `taken`. A probe we could not complete says nothing about the
        // name, and the registration call downstream is the real authority.
        failure: (_) => FieldAvailability.unknown,
      ),
    );
  }

  void _onPhoneChanged() {
    final value = _phone.text.trim();
    if (value == _lastPhoneProbe) return;
    _lastPhoneProbe = value;
    _restartPhoneProbe();
  }

  /// Also called when the country changes: the same local digits under a
  /// different dial code are a different number, so the previous answer no
  /// longer applies to what the field now means.
  void _restartPhoneProbe() {
    _phoneDebounce?.cancel();
    // Normalised exactly the way the transmitted value is — see
    // PhoneFormat.national — so the probe and the registration agree on what
    // the field contains.
    final national = PhoneFormat.national(_dial, _phone.text);

    if (_mode != _AuthMode.signUp || national.length < _dial.minNsnLength) {
      _setPhoneState(FieldAvailability.idle);
      return;
    }

    final e164 = PhoneFormat.e164(_dial, _phone.text);
    _setPhoneState(FieldAvailability.checking);
    _phoneDebounce = Timer(_probeDebounce, () => _probePhone(e164));
  }

  Future<void> _probePhone(String e164) async {
    final seq = ++_phoneSeq;
    final asked = _mode;
    final result = await ref
        .read(authRepositoryProvider)
        .checkIdentity(phone: e164);
    if (!mounted ||
        seq != _phoneSeq ||
        asked != _mode ||
        PhoneFormat.e164(_dial, _phone.text) != e164) {
      return;
    }
    _setPhoneState(
      result.when(
        success: (a) => a.phoneTaken
            ? FieldAvailability.taken
            : FieldAvailability.available,
        failure: (_) => FieldAvailability.unknown,
      ),
    );
  }

  /// Shape check only — the server is the authority on whether an address is
  /// real, and a regex strict enough to be worth trusting rejects valid
  /// addresses. This exists to stop a typo becoming a wasted round-trip.
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  void _onEmailChanged() {
    final value = _email.text.trim();
    if (value == _lastEmailProbe) return;
    _lastEmailProbe = value;
    _emailDebounce?.cancel();

    // Optional field: empty is a perfectly good answer, not a problem to
    // report. Only a well-formed address is worth asking the server about.
    if (_mode != _AuthMode.signUp || !_emailShape.hasMatch(value)) {
      _setEmailState(FieldAvailability.idle);
      return;
    }

    _setEmailState(FieldAvailability.checking);
    _emailDebounce = Timer(_probeDebounce, () => _probeEmail(value));
  }

  Future<void> _probeEmail(String value) async {
    final seq = ++_emailSeq;
    final asked = _mode;
    final result = await ref
        .read(authRepositoryProvider)
        .checkIdentity(email: value);
    if (!mounted ||
        seq != _emailSeq ||
        asked != _mode ||
        _email.text.trim() != value) {
      return;
    }
    _setEmailState(
      result.when(
        // Only a CONFIRMED address counts as taken server-side — an
        // unconfirmed one cannot sign in, so it must not block a new account.
        success: (a) =>
            a.emailTaken ? FieldAvailability.taken : FieldAvailability.available,
        failure: (_) => FieldAvailability.unknown,
      ),
    );
  }

  void _setEmailState(FieldAvailability next) {
    if (_emailState == next || !mounted) return;
    _publish(() => _emailState = next);
  }

  void _setUserNameState(FieldAvailability next) {
    if (_userNameState == next || !mounted) return;
    _publish(() => _userNameState = next);
  }

  void _setPhoneState(FieldAvailability next) {
    if (_phoneState == next || !mounted) return;
    _publish(() => _phoneState = next);
  }

  /// Applies a state change, deferring it to after the frame if we are inside
  /// one.
  ///
  /// These two setters are reached from a `TextEditingController` listener,
  /// and a controller can notify while a field is being built — mounting one,
  /// `Form.reset()`, an autofill landing. A `setState` from inside the frame's
  /// build or layout pass is not a rebuild, it is a re-entrancy: at best
  /// "setState() called during build", at worst `layout()` re-entered on a
  /// render object already laying itself out, which abandons the rest of the
  /// subtree un-laid-out for good.
  ///
  /// Nothing here is urgent enough to be worth that. An availability hint is
  /// allowed to appear one frame later.
  void _publish(VoidCallback mutate) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final insideFrame =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (!insideFrame) {
      setState(mutate);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(mutate);
    });
  }

  @override
  void initState() {
    super.initState();
    _userName.addListener(_onUserNameChanged);
    _phone.addListener(_onPhoneChanged);
    _email.addListener(_onEmailChanged);
    // Kicked off as the screen opens so the tenant is usually resolved before
    // anyone finishes typing. Sign-in and sign-up both need it: they run
    // before any JWT exists, and the server has no other way to know which
    // tenant the write belongs to.
    //
    // After the frame: reading a provider during initState would fire while
    // the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tenantProvider.notifier).ensureLoaded();
      _announceExpiredSession();
    });
  }

  /// Says why the person is looking at this form when they did not ask to be.
  ///
  /// An expired session drops them here from wherever they were, and a login
  /// screen that appears with no explanation reads as the app having lost
  /// their account. Read here rather than listened for, because the expiry
  /// happened on the screen BEFORE this one — by the time this widget exists
  /// the change is already in the past, and a listener would never fire.
  void _announceExpiredSession() {
    final expiry = ref.read(sessionExpiryProvider);
    if (!expiry.noticePending) return;
    ref.read(sessionExpiryProvider.notifier).acknowledge();

    final reason = expiry.reason;
    final generic = context.l10n.authSessionExpired;

    // The specific sentence ONLY for the two refusals that mean something the
    // person can act on: this phone was removed from the account, or the
    // session was ended elsewhere.
    //
    // Deliberately not the general mapper on the whole string. Its rules are
    // substring matches written for other screens, and they misfire here:
    // "Refresh Token is expired." contains `expired` and would come out as
    // "the verification code expired, request a new one", and "User not
    // found." as "no account with this number". Every other refusal gets this
    // screen's own generic line, which at least says where they are.
    final r = reason ?? '';
    final message =
        (r.contains('device_revoked') || r.contains('session_revoked'))
            ? arabicErrorFor(r)
            : generic;

    // In a DEBUG build the server's own words go underneath, and the toast
    // stays up long enough to read them. This is the only place a refused
    // refresh ever reaches a screen, and "signed out again" with nothing else
    // is the report that could not be acted on.
    if (kDebugMode && reason != null) {
      debugPrint('[auth] session ended: $reason');
      showRungToast(
        context,
        '$message\n$reason',
        success: false,
        duration: const Duration(seconds: 10),
      );
      return;
    }
    showRungToast(context, message, success: false);
  }

  @override
  void dispose() {
    _userNameDebounce?.cancel();
    _phoneDebounce?.cancel();
    _emailDebounce?.cancel();
    _userName.removeListener(_onUserNameChanged);
    _phone.removeListener(_onPhoneChanged);
    _email.removeListener(_onEmailChanged);
    _userName.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn;
      // Clear validation errors left over from the other mode's fields —
      // "required" on a field that is no longer on screen reads as a bug.
      _formKey.currentState?.reset();
      _genderError = null;
      // Sign-in does not probe, so entering it must clear whatever sign-up
      // left under the username — and entering sign-up has to start asking
      // about a name that is already typed in.
      _userNameState = FieldAvailability.idle;
      _phoneState = FieldAvailability.idle;
      _emailState = FieldAvailability.idle;
      _lastUserNameProbe = '';
      _lastPhoneProbe = '';
      _lastEmailProbe = '';
      // Bumping the sequence retires any probe already awaiting a response.
      // The staleness guards compare text and sequence, and a request sent in
      // sign-up for a name that is re-typed in sign-in satisfies both — the
      // answer would land in a mode that never asked the question.
      _userNameSeq++;
      _phoneSeq++;
      _emailSeq++;
    });
    // The form's `reset()` above clears the fields, so in practice these find
    // nothing to ask about. They are here so that stops being load-bearing:
    // the state is derived from the fields either way.
    _onUserNameChanged();
    _onPhoneChanged();
    _onEmailChanged();
  }

  Future<void> _pickPhoto() async {
    try {
      // Cropped square and resized before it leaves the device — see
      // ImageCropShape.avatar for the size.
      final localPath =
          await pickCroppedImage(context, shape: ImageCropShape.avatar);
      if (localPath == null || !mounted) return;
      setState(() => _photoPath = localPath);
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final signingUp = _mode == _AuthMode.signUp;

    // Gender is optional (App Store guideline 5.1.1(v): an app may not require
    // personal information its core function does not need). Skipping the
    // chips is a complete answer, and null is what goes on the wire — the
    // contact form takes gender as optional.
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    // A value the server has already told us is taken. The inline hints under
    // the fields say so, but a submit that visibly does nothing reads as a
    // broken button — so the reason is repeated where the finger just was.
    //
    // Only a definite `taken` blocks. `unknown` — a probe that timed out or
    // never reached the host — goes through, because the registration call is
    // the authority and refusing on our own failed lookup would lock someone
    // out of signing up over a dropped packet.
    if (signingUp && _userNameState == FieldAvailability.taken) {
      showRungToast(context, context.l10n.authUserNameTaken, success: false);
      return;
    }
    if (signingUp && _phoneState == FieldAvailability.taken) {
      showRungToast(context, context.l10n.authPhoneTaken, success: false);
      return;
    }
    if (signingUp && _emailState == FieldAvailability.taken) {
      showRungToast(context, context.l10n.authEmailTaken, success: false);
      return;
    }

    // Dismisses the keyboard so the result toast isn't hidden behind it.
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final notifier = ref.read(authNotifierProvider.notifier);

    if (signingUp) {
      // The photo goes up first, and a failure stops the submit: nothing has
      // been created yet, so nothing is half-done, and silently dropping the
      // photo someone chose is worse than making them retry. It also has to
      // happen HERE rather than after verification — the picked file is a path
      // into the photo library, and by the time the code screen is done with
      // it that path may no longer resolve.
      String? imageUrl;
      final path = _photoPath;
      final uploader = ref.read(mediaUploadServiceProvider);
      if (path != null && uploader != null) {
        final upload = await uploader.uploadImage(path);
        if (!mounted) return;
        if (upload.isFailure) {
          setState(() => _busy = false);
          showRungToast(
            context,
            arabicMessageForException(upload.errorOrNull!),
            success: false,
          );
          return;
        }
        imageUrl = upload.valueOrNull;
      }

      // No account is created here. Registration against this backend is
      // prove-an-identity THEN create, so the form's job ends with a draft and
      // the verify screen spends it.
      ref
          .read(registrationDraftProvider.notifier)
          .start(
            RegistrationDraft(
              fullName: _fullName.text.trim(),
              userName: _userName.text.trim(),
              // E.164 and nothing else. See PhoneFormat — the field's digits
              // mean nothing without the country the picker is sitting on.
              // Null when the person signs up with an e-mail only.
              phone: PhoneFormat.national(_dial, _phone.text).isEmpty
                  ? null
                  : PhoneFormat.e164(_dial, _phone.text),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              password: _password.text,
              accountType: _accountType,
              // Null for a company, and null is what goes on the wire — the
              // contact form takes gender as optional.
              gender: _gender,
              imageUrl: imageUrl,
            ),
          );

      if (!mounted) return;
      setState(() => _busy = false);
      await context.push(_verifyRoute);
      return;
    } else {
      await notifier.login(
        userName: _userName.text.trim(),
        password: _password.text,
      );
    }

    if (!mounted) return;
    setState(() => _busy = false);

    ref.read(authNotifierProvider).whenOrNull(
      data: (session) {
        if (session == null) return;
        // The router redirect moves us to the feed; the toast rides along.
        showRungToast(
          context,
          signingUp
              ? context.l10n.authAccountCreated(session.user.name)
              : context.l10n.authWelcomeBack(session.user.name),
        );
      },
      error: (e, _) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    // This read used to sit inside the LayoutBuilder's builder below, which
    // made it a provider subscription created during the layout phase — and
    // creating it starts `storageZoneProvider`'s network call, whose answer
    // then arrived as a rebuild mid-layout. That is gone now for a more
    // general reason; see `viewport`.
    final canPickPhoto = ref.watch(mediaUploadServiceProvider) != null;

    // What a LayoutBuilder around this subtree used to report, computed the
    // same way it computed it: the screen minus the top inset the SafeArea
    // below eats. `resizeToAvoidBottomInset: false` keeps the keyboard out of
    // it, so this is stable for the life of the screen.
    //
    // A LayoutBuilder runs its builder during the LAYOUT phase, which meant
    // the entire sign-up form — every field, every controller, every provider
    // read — was BUILT inside layout. Anything in there that marks an element
    // dirty then re-enters `layout()` on a render object that is already
    // laying itself out, which `RenderObject.layout` asserts against
    // (`!_debugDoingThisLayout`). Layout aborts at that point and the rest of
    // the form is never laid out, painted or hit-tested again — the scrambled
    // sheet, the "RenderBox was not laid out" storm and the per-frame
    // semantics assertions were all that one abort. Reading the height from
    // MediaQuery instead puts the form back in the ordinary build phase, where
    // marking something dirty is simply a rebuild.
    final media = MediaQuery.of(context);
    final viewport = media.size.height - media.padding.top;

    return Scaffold(
      // The sheet scrolls itself, so the layout must not also be resized from
      // under it — otherwise the hero collapses to a negative height when the
      // keyboard opens.
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: RungGradients.brand),
        child: Stack(
          children: [
            // Soft highlight in the upper corner, as in the design.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.56, -0.76),
                    radius: 0.9,
                    colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              // No LayoutBuilder here, deliberately — see `viewport` above.
              child: Column(
                  children: [
                    const Expanded(child: _Hero()),
                    // The sheet sizes to its content, but never past the point
                    // where the hero would have nothing left to render.
                    // Sign-in is short and leaves the full hero; sign-up is
                    // tall, takes most of the screen, and scrolls inside
                    // itself. Clamped at zero because a viewport shorter than
                    // the floor — a desktop window, Android freeform — would
                    // otherwise build a negative constraint and assert.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0, viewport - _minHeroHeight),
                      ),
                      child: _Sheet(
                        mode: _mode,
                        formKey: _formKey,
                        userName: _userName,
                        password: _password,
                        fullName: _fullName,
                        phone: _phone,
                        email: _email,
                        emailState: _emailState,
                        dial: _dial,
                        onDial: (code) {
                          setState(() => _dial = code);
                          // The same digits under a different country are a
                          // different number — the previous answer no longer
                          // describes what the field now means.
                          _restartPhoneProbe();
                        },
                        userNameState: _userNameState,
                        phoneState: _phoneState,
                        accountType: _accountType,
                        onAccountType: (type) => setState(() {
                          _accountType = type;
                          // Clear the answer with the question. Left set, a
                          // business would silently register as ذكر because the
                          // person tapped it before switching type — and the
                          // error would outlive the row that explains it.
                          if (type.isBusiness) {
                            _gender = null;
                            _genderError = null;
                          }
                        }),
                        gender: _gender,
                        // Optional, so a second tap on the chosen chip takes the
                        // answer back — otherwise there would be no way to undo
                        // an accidental tap and leave it unanswered.
                        onGender: (value) => setState(
                          () => _gender = _gender == value ? null : value,
                        ),
                        genderError: _genderError,
                        photoPath: _photoPath,
                        canPickPhoto: canPickPhoto,
                        onPickPhoto: _pickPhoto,
                        onRemovePhoto: () => setState(() => _photoPath = null),
                        busy: _busy,
                        onSubmit: _submit,
                        onSwitchMode: _switchMode,
                        surface: c.surface,
                      ),
                    ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gradient brand panel above the sheet.
///
/// **Composes down to fit whatever height it is given.** It used to be a fixed
/// ~420px column inside a scroll view, so when the sheet grew — sign-up mode,
/// a small device — the hero clipped to its first child and looked broken
/// rather than deliberately small.
///
/// It SHRINKS rather than dropping things. An earlier version hid the line
/// under the headline as soon as the sheet grew past a threshold, so the same
/// screen read differently from one moment to the next — sign-in showed the
/// promise, typing a wrong password took it away. The logo and the type step
/// down through four sizes instead, and both lines of copy stay to the last
/// one.
class _Hero extends StatelessWidget {
  const _Hero();

  /// One step of the ladder: how big everything is at this height.
  ///
  /// The budgets are padding + each block at its worst wrap: the headline over
  /// two lines at `height: 1.15`, the body over two at `height: 1.55`. They are
  /// deliberately under the threshold they sit at — the previous set matched it
  /// exactly, and a body that wrapped one line further overflowed by 4px.
  static ({double logo, double title, double body, int bodyLines, bool showBody})
      _step(double height) {
    // 48 + 78 + 26 + 69 + 14 + 45 = 280
    if (height >= 330) {
      return (logo: 78, title: 30, body: 14.5, bodyLines: 3, showBody: true);
    }
    // 48 + 70 + 20 + 62 + 12 + 43 = 255
    if (height >= 265) {
      return (logo: 70, title: 27, body: 14, bodyLines: 3, showBody: true);
    }
    // 24 + 58 + 12 + 51 + 8 + 40 = 193
    if (height >= 205) {
      return (logo: 58, title: 22, body: 13, bodyLines: 3, showBody: true);
    }
    // The floor, which is `_minHeroHeight` (132): 24 + 48 + 12 + 42 = 126, and
    // one line of copy under it only where there is room — 153.
    return (
      logo: 48,
      title: 18,
      body: 12,
      bodyLines: 1,
      showBody: height >= 165,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = _step(constraints.maxHeight);
        final tight = constraints.maxHeight < 265;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 34,
            vertical: tight ? 12 : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RungAppLogo(size: step.logo),
              SizedBox(height: tight ? 12 : 26),
              Text(
                l10n.authHeroTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: step.title,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.15,
                ),
              ),
              if (step.showBody) ...[
                SizedBox(height: tight ? 8 : 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    l10n.authHeroBody,
                    maxLines: step.bodyLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xD1FFFFFF),
                      fontSize: step.body,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.mode,
    required this.formKey,
    required this.userName,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.emailState,
    required this.dial,
    required this.onDial,
    required this.userNameState,
    required this.phoneState,
    required this.accountType,
    required this.onAccountType,
    required this.gender,
    required this.onGender,
    required this.genderError,
    required this.photoPath,
    required this.canPickPhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.busy,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.surface,
  });

  final _AuthMode mode;
  final GlobalKey<FormState> formKey;
  final TextEditingController userName;
  final TextEditingController password;
  final TextEditingController fullName;
  final TextEditingController phone;

  /// Optional second channel. A person may verify with either this or the
  /// phone, but the phone is still what the account is created with —
  /// `CreateWithContact` requires one.
  final TextEditingController email;
  final FieldAvailability emailState;

  /// The country the phone field is prefixed with, and the way to change it.
  final DialCode dial;
  final ValueChanged<DialCode> onDial;

  /// What the server last said about the username and the phone. Rendered
  /// under each field; only the screen's state knows how they got there.
  final FieldAvailability userNameState;
  final FieldAvailability phoneState;

  final AccountType accountType;
  final ValueChanged<AccountType> onAccountType;
  final Gender? gender;
  final ValueChanged<Gender> onGender;
  final String? genderError;
  final String? photoPath;

  /// False until the backend has answered with a usable storage zone — and
  /// false for good on a deployment that has none. The control is hidden
  /// rather than offering an upload that cannot succeed.
  final bool canPickPhoto;

  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final Color surface;

  /// Same shape test the state class uses for its probe — see
  /// `_AuthScreenState._emailShape`.
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  bool get _signingUp => mode == _AuthMode.signUp;

  /// Registering an organisation rather than a person. Changes what the name
  /// field asks for and removes the gender question entirely.
  /// "Is this account a business?" — a company, a contractor, a craftsman or
  /// the owner of machinery. Everything this form varies (the name field's
  /// wording, the autofill hint, whether gender is asked) splits on that, not
  /// on company specifically.
  bool get _isBusiness => accountType.isBusiness;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    String? required(String? value) =>
        (value == null || value.trim().isEmpty) ? l10n.authRequiredField : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // The sheet owns keyboard avoidance: its own scroll view plus the
      // viewInsets padding, so a focused field is always reachable without
      // squeezing the hero above it. Its maximum height is set by the parent,
      // which knows how much the hero needs.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            26,
            24,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _signingUp ? l10n.authSignUpTitle : l10n.authSignInTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RungSpace.md),

                  if (_signingUp && canPickPhoto) ...[
                    Center(
                      child: _PhotoPicker(
                        path: photoPath,
                        onPick: busy ? null : onPickPhoto,
                        onRemove: busy ? null : onRemovePhoto,
                      ),
                    ),
                    const SizedBox(height: RungSpace.md),
                  ],

                  if (_signingUp) ...[
                    // ABOVE the name, because it decides what the name field is
                    // asking for. Underneath it, somebody types their own name
                    // into a box labelled "الاسم الكامل", picks شركة, and the
                    // question they already answered changes behind them.
                    // One row that opens a sheet, not five buttons: the
                    // buttons cost five rows of a form that still has to fit a
                    // name, a handle, a phone and an email, and they had no
                    // room to say what any of the five kinds actually does.
                    AccountTypeField(
                      value: accountType,
                      onChanged: onAccountType,
                      enabled: !busy,
                    ),
                    const SizedBox(height: RungSpace.md),

                    RungField(
                      // The field holds the same value either way — it is what
                      // the account is called — so only the wording changes.
                      label: accountType.nameLabel(context),
                      hint: accountType.nameHint(context),
                      controller: fullName,
                      enabled: !busy,
                      textInputAction: TextInputAction.next,
                      autofillHints: _isBusiness
                          ? const [AutofillHints.organizationName]
                          : const [AutofillHints.name],
                      validator: required,
                    ),
                    const SizedBox(height: RungSpace.sm),
                  ],

                  RungField(
                    label: l10n.authUserName,
                    hint: _signingUp ? l10n.authUserNameHint : null,
                    controller: userName,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return l10n.authRequiredField;
                      if (_signingUp && text.length < 3) {
                        return l10n.authUserNameTooShort;
                      }
                      return null;
                    },
                  ),
                  if (_signingUp)
                    AvailabilityHint(
                      state: userNameState,
                      takenLabel: l10n.authUserNameTaken,
                    ),
                  const SizedBox(height: RungSpace.sm),

                  if (_signingUp) ...[
                    // Phone OR e-mail (App Store guideline 5.1.1(v)): the code
                    // goes to whichever is given, the phone when both are.
                    Padding(
                      padding: const EdgeInsets.only(bottom: RungSpace.xs),
                      child: Text(
                        l10n.authPhoneOrEmailHint,
                        style: TextStyle(fontSize: 12, height: 1.5, color: c.ink3),
                      ),
                    ),
                    PhoneNumberField(
                      controller: phone,
                      code: dial,
                      onCode: onDial,
                      enabled: !busy,
                      validator: (value) {
                        // Normalised through the same function that builds the
                        // transmitted value: the trunk zero and any pasted
                        // country code are dialling, not identity, and counting
                        // them let `0770…` in Kuwait pass a check its national
                        // number fails.
                        final national = PhoneFormat.national(dial, value ?? '');
                        // Empty is fine when an e-mail carries the sign-up.
                        if (national.isEmpty) {
                          return email.text.trim().isEmpty
                              ? l10n.authPhoneOrEmailRequired
                              : null;
                        }
                        // Per country, not one floor for all of them — eight
                        // digits is a whole Kuwaiti number and most of an Iraqi
                        // one.
                        if (national.length < dial.minNsnLength) {
                          return l10n.authPhoneInvalid;
                        }
                        return null;
                      },
                    ),
                    AvailabilityHint(
                      state: phoneState,
                      takenLabel: l10n.authPhoneTaken,
                    ),
                    const SizedBox(height: RungSpace.sm),

                    RungField(
                      label: l10n.authEmail,
                      hint: l10n.authEmailHint,
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final text = (value ?? '').trim();
                        // Optional — an empty box is a complete answer. Only a
                        // filled one has to be well formed.
                        if (text.isEmpty) return null;
                        return _emailShape.hasMatch(text)
                            ? null
                            : l10n.authEmailInvalid;
                      },
                    ),
                    AvailabilityHint(
                      state: emailState,
                      takenLabel: l10n.authEmailTaken,
                    ),
                    const SizedBox(height: RungSpace.sm),
                  ],

                  RungField(
                    label: l10n.authPassword,
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!busy) onSubmit();
                    },
                    autofillHints: [
                      _signingUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return l10n.authRequiredField;
                      if (!_signingUp) return null;
                      // Identity's policy, checked here because its own
                      // rejection arrives as English prose after a round-trip:
                      // at least 8 characters with a digit, a lowercase and an
                      // uppercase letter. Symbols are allowed, not required.
                      if (text.length < 8) return l10n.authPasswordTooShort;
                      final weak =
                          !RegExp(r'[0-9]').hasMatch(text) ||
                          !RegExp(r'[a-z]').hasMatch(text) ||
                          !RegExp(r'[A-Z]').hasMatch(text);
                      return weak ? l10n.authPasswordWeak : null;
                    },
                  ),

                  // A business has no gender — it is a page, not a person.
                  // Hidden rather than disabled: an inert ذكر/أنثى row on a
                  // company sign-up is a question the form is still asking and
                  // nobody can answer.
                  if (_signingUp && !_isBusiness) ...[
                    const SizedBox(height: RungSpace.md),
                    Text(
                      l10n.authGenderOptional,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.ink3,
                      ),
                    ),
                    const SizedBox(height: RungSpace.xs),
                    Row(
                      children: [
                        RungFilterChip(
                          label: l10n.authGenderMale,
                          selected: gender == Gender.male,
                          onTap: () => onGender(Gender.male),
                        ),
                        const SizedBox(width: RungSpace.xs),
                        RungFilterChip(
                          label: l10n.authGenderFemale,
                          selected: gender == Gender.female,
                          onTap: () => onGender(Gender.female),
                        ),
                      ],
                    ),
                    if (genderError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          genderError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: RungSpace.md),
                  FilledButton(
                    onPressed: busy ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _signingUp
                                ? l10n.authSubmitSignUp
                                : l10n.authSubmitSignIn,
                          ),
                  ),
                  // Under the submit button, where someone who has just
                  // failed to sign in is already looking. Sign-in only: on the
                  // sign-up form it would offer to recover an account this
                  // person is in the middle of saying they do not have.
                  if (!_signingUp) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: busy ? null : () => context.push(_forgotRoute),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: c.accent,
                      ),
                      child: Text(l10n.authForgotPassword),
                    ),
                  ],
                  const SizedBox(height: 11),
                  TextButton(
                    onPressed: busy ? null : onSwitchMode,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: c.ink,
                    ),
                    child: Text(
                      _signingUp
                          ? l10n.authSwitchToSignIn
                          : l10n.authSwitchToSignUp,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // The privacy policy is a link here, not just a mention: the
                  // stores require it to be reachable before an account is
                  // made, and "you agree to" a page you cannot open is no
                  // agreement at all.
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 11, height: 1.5, color: c.ink3),
                      children: [
                        TextSpan(text: l10n.authTermsLead),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => openTerms(context),
                            child: Text(
                              l10n.authTermsLink,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: c.accent,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: c.accent,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(text: l10n.authTermsAnd),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => openPrivacyPolicy(context),
                            child: Text(
                              l10n.authTermsPrivacy,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: c.accent,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: c.accent,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(text: l10n.authTermsTail),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular avatar well for the sign-up photo.
///
/// Shows the picked file straight off disk — there is nothing uploaded yet at
/// this point, and there is no remote URL to render until submit.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final picked = path;

    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface2,
              border: Border.all(color: c.line2, width: 1.5),
              image: picked == null
                  ? null
                  : DecorationImage(
                      image: FileImage(File(picked)),
                      fit: BoxFit.cover,
                    ),
            ),
            child: picked == null
                ? Icon(Icons.photo_camera_outlined, size: 26, color: c.ink3)
                : null,
          ),
        ),
        const SizedBox(height: RungSpace.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onPick,
              style: TextButton.styleFrom(foregroundColor: c.accent),
              child: Text(
                picked == null ? l10n.authPhotoPick : l10n.authPhotoChange,
              ),
            ),
            if (picked != null)
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(foregroundColor: c.ink3),
                child: Text(l10n.authPhotoRemove),
              ),
          ],
        ),
      ],
    );
  }
}
