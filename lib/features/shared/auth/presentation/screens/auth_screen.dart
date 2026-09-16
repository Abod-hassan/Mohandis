import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/services/media_upload_service.dart';
import 'package:flutter_mobile_template/core/services/tenant_store.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/user.dart';
import '../notifiers/auth_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    // Kicked off as the screen opens so the tenant is usually resolved before
    // anyone finishes typing. Sign-in and sign-up both need it: they run
    // before any JWT exists, and the server has no other way to know which
    // tenant the write belongs to.
    //
    // After the frame: reading a provider during initState would fire while
    // the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(tenantProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _userName.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn;
      // Clear validation errors left over from the other mode's fields —
      // "required" on a field that is no longer on screen reads as a bug.
      _formKey.currentState?.reset();
      _genderError = null;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Resized before it leaves the device: an avatar is rendered at ~80px,
        // and uploading a 12MP original costs the person's data for nothing.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _photoPath = picked.path);
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final signingUp = _mode == _AuthMode.signUp;

    // The chips live outside the Form, so their validation is manual. Shown
    // inline under the row rather than as a toast — a toast about a control
    // that is still on screen just makes people hunt for it.
    final isCompany = _accountType == AccountType.company;
    setState(
      () => _genderError = signingUp && !isCompany && _gender == null
          ? context.l10n.authGenderRequired
          : null,
    );

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _genderError != null) return;

    // Dismisses the keyboard so the result toast isn't hidden behind it.
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final notifier = ref.read(authNotifierProvider.notifier);

    if (signingUp) {
      // The photo goes up first, and a failure stops the submit: no account
      // has been created yet, so nothing is half-done, and silently dropping
      // the photo someone chose is worse than making them retry.
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

      await notifier.register(
        fullName: _fullName.text.trim(),
        userName: _userName.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        accountType: _accountType,
        // Null for a company, and null is what goes on the wire — the contact
        // form takes gender as optional. `_gender!` here threw the moment the
        // gender row stopped being drawn for them.
        gender: _gender,
        imageUrl: imageUrl,
      );
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
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
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
                        maxHeight: math.max(
                          0,
                          constraints.maxHeight - _minHeroHeight,
                        ),
                      ),
                      child: _Sheet(
                        mode: _mode,
                        formKey: _formKey,
                        userName: _userName,
                        password: _password,
                        fullName: _fullName,
                        phone: _phone,
                        accountType: _accountType,
                        onAccountType: (type) => setState(() {
                          _accountType = type;
                          // Clear the answer with the question. Left set, a
                          // company would silently register as ذكر because the
                          // person tapped it before switching type — and the
                          // error would outlive the row that explains it.
                          if (type == AccountType.company) {
                            _gender = null;
                            _genderError = null;
                          }
                        }),
                        gender: _gender,
                        // No deselect: once answered there is no third state to
                        // go back to, and the form requires an answer.
                        onGender: (value) => setState(() => _gender = value),
                        genderError: _genderError,
                        photoPath: _photoPath,
                        canPickPhoto:
                            ref.watch(mediaUploadServiceProvider) != null,
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
/// ~420px column inside a scroll view, which meant that when the sheet grew —
/// sign-up mode, or a small device — the hero silently clipped to its first
/// child and looked broken rather than deliberately small. Now each element
/// earns its place only if there is room: the stats go first, then the body
/// copy, then the headline, leaving the logo alone as the floor.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        // Thresholds are the measured cost of each block plus its gap, and
        // they only hold because the text below is line-bounded: an Arabic
        // headline that wraps to three lines, or body copy to four, would
        // blow past them. Budget at the full composition: 48 padding + 66
        // logo + 26 + 78 title (2 lines) + 14 + 70 body (3 lines) + 26 + 44
        // stats = 372, inside 380.
        final showStats = height >= 380;
        final showBody = height >= 305;
        final showTitle = height >= 220;
        final tight = height < 170;

        final logoSize = tight ? 52.0 : 66.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 34,
            vertical: tight ? 12 : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: Text(
                  'ر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tight ? 27 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showTitle) ...[
                const SizedBox(height: 26),
                Text(
                  l10n.authHeroTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.15,
                  ),
                ),
              ],
              if (showBody) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    l10n.authHeroBody,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xD1FFFFFF),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              if (showStats) ...[
                const SizedBox(height: 26),
                Row(
                  children: [
                    _Stat(
                      value: l10n.authStatProfessionalsValue,
                      label: l10n.authStatProfessionalsLabel,
                    ),
                    const SizedBox(width: 20),
                    _Stat(
                      value: l10n.authStatJobsValue,
                      label: l10n.authStatJobsLabel,
                    ),
                    const SizedBox(width: 20),
                    _Stat(
                      value: l10n.authStatTrustValue,
                      label: l10n.authStatTrustLabel,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  bool get _signingUp => mode == _AuthMode.signUp;

  /// Registering an organisation rather than a person. Changes what the name
  /// field asks for and removes the gender question entirely.
  bool get _isCompany => accountType == AccountType.company;

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
                    Text(
                      l10n.authAccountType,
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
                          label: l10n.authAccountIndividual,
                          selected: accountType == AccountType.individual,
                          onTap: () => onAccountType(AccountType.individual),
                        ),
                        const SizedBox(width: RungSpace.xs),
                        RungFilterChip(
                          label: l10n.authAccountCompany,
                          selected: accountType == AccountType.company,
                          onTap: () => onAccountType(AccountType.company),
                        ),
                      ],
                    ),
                    const SizedBox(height: RungSpace.md),

                    RungField(
                      // The field holds the same value either way — it is what
                      // the account is called — so only the wording changes.
                      label: _isCompany
                          ? l10n.authCompanyName
                          : l10n.authFullName,
                      hint: _isCompany
                          ? l10n.authCompanyNameHint
                          : l10n.authFullNameHint,
                      controller: fullName,
                      textInputAction: TextInputAction.next,
                      autofillHints: _isCompany
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
                  const SizedBox(height: RungSpace.sm),

                  if (_signingUp) ...[
                    RungField(
                      label: l10n.authPhone,
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        if (digits.isEmpty) return l10n.authRequiredField;
                        if (digits.length < 7) return l10n.authPhoneInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: RungSpace.sm),
                  ],

                  RungField(
                    label: l10n.authPassword,
                    controller: password,
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
                      // Identity rejects anything shorter, and its error text
                      // is English — catch it here instead.
                      if (_signingUp && text.length < 6) {
                        return l10n.authPasswordTooShort;
                      }
                      return null;
                    },
                  ),

                  // A company has no gender. Hidden rather than disabled: an
                  // inert ذكر/أنثى row on a company sign-up is a question the
                  // form is still asking and nobody can answer.
                  if (_signingUp && !_isCompany) ...[
                    const SizedBox(height: RungSpace.md),
                    Text(
                      l10n.authGender,
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
                  Text(
                    l10n.authTerms,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.5, color: c.ink3),
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
