import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/services/media_upload_service.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';
import '../widgets/company_sections.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();
  final _about = TextEditingController();
  final _website = TextEditingController();
  /// The founding DATE, held as state rather than text.
  ///
  /// It used to be a numeric TextField, which let somebody type 20155, or 0,
  /// or a year in the future, and left the app parsing a string back into a
  /// number on every save. A picker cannot produce any of those.
  DateTime? _foundedOn;
  final _specialties = TextEditingController();

  /// Matches `Specialties`' varchar(1000) server-side.
  static const int _kSpecialtiesMaxLength = 1000;

  /// Null means "not stated" — the same thing `CompanySize.unspecified` means
  /// on the wire, kept as the enum so the chip row has something to compare.
  CompanySize _companySize = CompanySize.unspecified;

  /// Which form to draw. Read from the loaded profile rather than from
  /// `isCompanyAccountProvider` so the fields and the values being hydrated
  /// into them always come from the same record.
  bool _isCompany = false;

  bool _openToWork = false;
  bool _isPrivate = false;
  bool _hydrated = false;
  bool _saving = false;

  /// Which image is mid-upload, so only that control shows a spinner.
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  /// Picks a photo, uploads it, and writes the resulting path to [field].
  ///
  /// Saved on its own rather than folded into the form's Save: the photo is
  /// already on the CDN by the time the picker closes, and leaving it unsaved
  /// would lose it if the person backed out. [field] is the key `updateMe`
  /// maps — `avatarUrl` or `coverUrl`.
  Future<void> _pickAndSaveImage({
    required String field,
    required void Function(bool) setBusy,
  }) async {
    final uploader = ref.read(mediaUploadServiceProvider);
    // Unreachable while the controls are gated on `canPickPhoto` below; kept
    // so a future caller can't reach the picker without an uploader behind it.
    if (uploader == null) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // A banner is wider than an avatar, so this is sized for the larger of
        // the two rather than per field — it is still a fraction of an original.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => setBusy(true));
    final upload = await uploader.uploadImage(picked.path);
    if (!mounted) return;

    if (upload.isFailure) {
      setState(() => setBusy(false));
      showRungToast(
        context,
        arabicMessageForException(upload.errorOrNull!),
        success: false,
      );
      return;
    }

    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .save({field: upload.valueOrNull});

    if (!mounted) return;
    setState(() => setBusy(false));
    result.when(
      success: (_) => showRungToast(context, context.l10n.toastProfileUpdated),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _headline,
      _industry,
      _location,
      _about,
      _website,
      _specialties,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Seeds the form once, the first time both the person and profile land.
  /// Re-seeding on every rebuild would stomp on what the user is typing.
  void _hydrate(Profile profile) {
    if (_hydrated) return;
    final me = ref.read(currentPersonProvider).valueOrNull;
    if (me == null) return;

    _name.text = me.name;
    _headline.text = me.headline;
    _location.text = me.location;
    _industry.text = profile.industry;
    _about.text = profile.about;
    _openToWork = profile.openToWork;
    _isPrivate = profile.isPrivate;

    _isCompany = profile.isCompany;
    _website.text = profile.website ?? '';
    _foundedOn = profile.foundedOn;
    // Joined with newlines, which is how the field is edited and how the
    // server stores it — the split on read tolerates commas as well.
    _specialties.text = profile.specialties.join('\n');
    _companySize = profile.companySize;

    _hydrated = true;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final result =
        await ref.read(profileNotifierProvider('me').notifier).save({
      'name': _name.text.trim(),
      'headline': _headline.text.trim(),
      'industry': _industry.text.trim(),
      'location': _location.text.trim(),
      'about': _about.text.trim(),
      'isPrivate': _isPrivate,
      // A company is never "open to work"; sending the flag would set a
      // person's status on a company page.
      if (!_isCompany) 'openToWork': _openToWork,
      if (_isCompany) ...{
        'website': _website.text.trim(),
        'companySize': _companySize,
        // Null clears it. "Not stated" and a real date stay distinguishable
        // because the column is nullable and the picker can be cleared.
        'foundedOn': _foundedOn,
        'specialties': _specialties.text.trim(),
      },
    });

    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        showRungToast(context, context.l10n.toastProfileUpdated);
        if (context.canPop()) context.pop();
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final profile = ref.watch(profileNotifierProvider('me'));
    final me = ref.watch(currentPersonProvider).valueOrNull;
    // No uploader configured for this flavour means no photo control at all —
    // the same rule the sign-up screen follows. A camera button that cannot
    // upload is worse than no button.
    final canPickPhoto = ref.watch(mediaUploadServiceProvider) != null;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        leading: TextButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile/me'),
          style: TextButton.styleFrom(foregroundColor: c.ink2),
          child: Text(l10n.actionCancel),
        ),
        title: l10n.editProfileTitle,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.accent,
                    ),
                  )
                : Text(l10n.actionSave),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (data) {
          _hydrate(data);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(gradient: RungGradients.brand),
                    ),
                    if (data.coverUrl != null)
                      Image.network(
                        ref.watch(imageUrlResolverProvider)(data.coverUrl) ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    if (canPickPhoto)
                      Center(
                        child: _uploadingCover
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : _CircleAction(
                                icon: Icons.photo_camera_outlined,
                                onTap: () => _pickAndSaveImage(
                                  field: 'coverUrl',
                                  setBusy: (v) => _uploadingCover = v,
                                ),
                                tooltip: l10n.editProfileChangeCover,
                              ),
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -34),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RungSpace.gutter,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RungAvatar(
                          seed: me?.id ?? 'me',
                          initials: me?.initials ?? '—',
                          size: 76,
                          borderColor: c.surface,
                          borderWidth: 4,
                          imageUrl: ref.watch(imageUrlResolverProvider)(
                            data.avatarUrl,
                          ),
                        ),
                        if (canPickPhoto)
                          PositionedDirectional(
                            bottom: 0,
                            end: 0,
                            // Was a bare Container — it looked like a button
                            // and did nothing.
                            child: Semantics(
                            button: true,
                            label: l10n.editProfileChangePhoto,
                            child: InkWell(
                              onTap: _uploadingAvatar
                                  ? null
                                  : () => _pickAndSaveImage(
                                        field: 'avatarUrl',
                                        setBusy: (v) => _uploadingAvatar = v,
                                      ),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.surface, width: 2),
                                ),
                                child: _uploadingAvatar
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.edit,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RungSpace.gutter,
                  0,
                  RungSpace.gutter,
                  RungSpace.lg,
                ),
                child: Column(
                  children: [
                    RungField(
                      label: l10n.editProfileFullName,
                      controller: _name,
                    ),
                    const SizedBox(height: RungSpace.md),
                    RungField(
                      label: l10n.editProfileHeadline,
                      controller: _headline,
                    ),
                    const SizedBox(height: RungSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RungField(
                            label: l10n.editProfileIndustry,
                            controller: _industry,
                          ),
                        ),
                        const SizedBox(width: RungSpace.sm),
                        Expanded(
                          child: RungField(
                            label: l10n.editProfileLocation,
                            controller: _location,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RungSpace.md),
                    RungField(
                      label: l10n.editProfileAbout,
                      controller: _about,
                      maxLines: 5,
                      height: 110,
                    ),

                    // ── Company ─────────────────────────────────────────
                    if (_isCompany) ...[
                      const SizedBox(height: RungSpace.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RungField(
                              label: l10n.companyJobCompanyWebsite,
                              controller: _website,
                              keyboardType: TextInputType.url,
                            ),
                          ),
                          const SizedBox(width: RungSpace.sm),
                          Expanded(
                            child: _FoundedOnField(
                              value: _foundedOn,
                              onChanged: (v) => setState(() => _foundedOn = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RungSpace.md),
                      _CompanySizeField(
                        selected: _companySize,
                        onSelect: (v) => setState(() => _companySize = v),
                      ),
                      const SizedBox(height: RungSpace.md),
                      RungField(
                        label: l10n.companySpecialties,
                        hint: l10n.companySpecialtiesHint,
                        controller: _specialties,
                        maxLines: 4,
                        height: 96,
                        // The column is varchar(1000). Capped at the field
                        // rather than left to fail on save, where the server's
                        // refusal reaches the person as an opaque error after
                        // they have already written too much.
                        maxLength: _kSpecialtiesMaxLength,
                      ),
                    ] else ...[
                      const SizedBox(height: RungSpace.md),
                      RungToggleTile(
                        title: l10n.editProfileOpenToWorkTitle,
                        subtitle: l10n.editProfileOpenToWorkSubtitle,
                        leading: RungDot(color: c.green),
                        value: _openToWork,
                        onChanged: (v) => setState(() => _openToWork = v),
                      ),
                    ],
                    const SizedBox(height: RungSpace.md),
                    RungToggleTile(
                      title: l10n.editProfilePrivateTitle,
                      subtitle: l10n.editProfilePrivateSubtitle,
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x40FFFFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Headcount band, as a wrapping chip row.
///
/// Tapping the selected band clears it back to "not stated", which is how an
/// optional choice gets un-made without a separate control — the same gesture
/// the job form's optional chips use.
class _CompanySizeField extends StatelessWidget {
  const _CompanySizeField({required this.selected, required this.onSelect});

  final CompanySize selected;
  final ValueChanged<CompanySize> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.companySize,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in CompanySize.values)
              // `unspecified` has no chip — it is the state you reach by
              // deselecting, not one you pick.
              if (size.isStated)
                RungFilterChip(
                  label: size.label(context) ?? '',
                  selected: size == selected,
                  onTap: () => onSelect(
                    size == selected ? CompanySize.unspecified : size,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

/// The company's founding date, picked rather than typed.
///
/// Tapping opens the platform date picker; the long-press clears it, because a
/// picker with no way back leaves "not stated" unreachable once somebody has
/// answered by accident.
class _FoundedOnField extends StatelessWidget {
  const _FoundedOnField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year, 1, 1),
          // Far enough back for any company that exists, and capped at today:
          // a founding date in the future is not a thing.
          firstDate: DateTime(1800),
          lastDate: now,
        );
        if (picked != null) onChanged(DateTime(picked.year, picked.month, picked.day));
      },
      onLongPress: value == null ? null : () => onChanged(null),
      borderRadius: BorderRadius.circular(RungRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.companyFounded,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null ? l10n.fieldNotSet : formatDayArabic(value!),
          style: TextStyle(
            fontSize: 14,
            color: value == null ? c.ink3 : c.ink,
          ),
        ),
      ),
    );
  }
}
