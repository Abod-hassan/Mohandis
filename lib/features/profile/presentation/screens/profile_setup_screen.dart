import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/utils/pick_cropped_image.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/auth/presentation/notifiers/pending_email.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../widgets/account_type_labels.dart';
import '../widgets/discipline_picker.dart';
import '../widgets/governorate_picker.dart';

import '../../data/profile_setup_store.dart';
import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';

/// The step straight after registration: give the empty profile something to
/// show. Reached only via the router's `profileSetupPendingProvider` rule, and
/// left only by saving or skipping — both clear the flag, which is what
/// releases the redirect and lands the person on the feed.
///
/// The account exists at this point (contact + Identity user + session), and
/// the social profile has been auto-provisioned with the name from the
/// contact. Everything here is an edit to that row, so nothing is lost if the
/// person skips.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _headline = TextEditingController();
  final _about = TextEditingController();
  final _location = TextEditingController();
  final _industry = TextEditingController();

  /// The chosen discipline — الاختصاص. [_industry] still carries its NAME, for
  /// everything that compares industries as text.
  int? _disciplineId;

  /// The chosen governorate — المحافظة. [_location] carries its NAME, for
  /// everything that reads a location as text.
  int? _governorateId;
  final _website = TextEditingController();

  bool _openToWork = false;
  bool _saving = false;
  /// Whose profile the fields were filled from — null until they have been.
  ///
  /// An id rather than a bool, because "already filled" is not the question;
  /// "filled from THIS account" is. `profileNotifierProvider` is not
  /// autoDispose, and signing in as someone else invalidates it rather than
  /// discarding it — Riverpod rebuilds it carrying the previous value, and
  /// `AsyncValue.when` shows that value while the new one loads (its
  /// `skipLoadingOnRefresh` defaults to true). So the first frame after a
  /// switch handed this screen the PREVIOUS account's profile, a bool flag
  /// latched on it, and the fresh profile arriving a moment later was ignored:
  /// the new account opened on the old one's headline and bio.
  String? _hydratedFor;

  /// Which attachment is mid-upload, so only that control shows a spinner.
  bool _uploadingAvatar = false;
  bool _uploadingCv = false;

  /// The file name of a CV picked in this session, shown until the profile
  /// refetches — `cvUrl` is a storage path and reads as nothing to a human.
  String? _cvName;

  /// Same ceiling the job application uses. A CV that will not upload is a
  /// worse outcome than one that has to be shrunk first.
  static const int _maxCvBytes = 10 * 1024 * 1024;

  /// Anything that must not be interrupted by Save or Skip. The photo and the
  /// CV write to the same profile row this form does, and `updateMe` reads
  /// before it writes — so two of them in flight can repaint the screen from
  /// a copy taken before the other landed.
  bool get _busy => _saving || _uploadingAvatar || _uploadingCv;

  @override
  void dispose() {
    _headline.dispose();
    _about.dispose();
    _location.dispose();
    _industry.dispose();
    _website.dispose();
    super.dispose();
  }

  /// Seeds the fields from whatever the profile already has — once. Re-running
  /// on every rebuild would overwrite what the person is typing.
  void _hydrate(Profile profile) {
    // Once per account. Re-running for the SAME account would overwrite what
    // the person is typing whenever a save republishes the profile; running
    // again for a DIFFERENT one is the whole point — every field is assigned
    // below, empty values included, so nothing from before survives.
    if (_hydratedFor == profile.personId) return;
    _headline.text = profile.headline;
    _about.text = profile.about;
    _location.text = profile.location;
    _industry.text = profile.industry;
    _disciplineId = profile.disciplineId;
    _governorateId = profile.governorateId;
    _website.text = profile.website ?? '';
    _openToWork = profile.openToWork;
    _hydratedFor = profile.personId;
  }

  /// Picks a photo, uploads it, and saves it as the profile's avatar.
  ///
  /// Saved on its own rather than folded into this screen's Save, for the same
  /// reason edit-profile does it: the file is on the CDN by the time the
  /// picker closes, and a skip would otherwise throw it away.
  Future<void> _pickAvatar() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) return;

    final String? localPath;
    try {
      localPath = await pickCroppedImage(context, shape: ImageCropShape.avatar);
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }
    if (localPath == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final upload = await uploader.uploadImage(localPath);
      if (!mounted) return;
      if (upload.isFailure) {
        showRungToast(
          context,
          arabicMessageForException(upload.errorOrNull!),
          success: false,
        );
        return;
      }

      final saved = await ref
          .read(profileNotifierProvider('me').notifier)
          .save({'avatarUrl': upload.valueOrNull});
      if (!mounted) return;
      saved.when(
        success: (_) {},
        failure: (e) => showRungToast(
          context,
          arabicMessageForException(e),
          success: false,
        ),
      );
    } finally {
      // In a `finally` rather than on each exit, because not every failure
      // arrives as a `Result`: `MediaUploadService` probes the file with
      // `existsSync()` OUTSIDE its own try/catch, so a FileSystemException
      // escapes as a raw throw. A flag left true disables this control for
      // the life of the screen, with the spinner stuck on it.
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  /// Picks a CV and writes it to the profile. Mirrors the job application's
  /// picker — same extensions, same ceiling, same `cv/` folder, so a retention
  /// rule written against `posts/` can never reach one.
  Future<void> _pickCv() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) return;

    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }

    final file = picked?.files.isNotEmpty == true ? picked!.files.first : null;
    if (file?.path == null || !mounted) return;
    if (file!.size > _maxCvBytes) {
      showRungToast(
        context,
        context.l10n.composerDocumentTooLarge(_maxCvBytes ~/ (1024 * 1024)),
        success: false,
      );
      return;
    }

    setState(() {
      _uploadingCv = true;
      _cvName = file.name;
    });

    // The name is shown optimistically while the upload runs; it is kept only
    // if the profile actually ended up holding the file, so the row never
    // claims an attachment that was never written.
    var attached = false;
    try {
      final upload = await uploader.uploadDocument(file.path!, folder: 'cv');
      if (!mounted) return;
      if (upload.isFailure) {
        showRungToast(
          context,
          arabicMessageForException(upload.errorOrNull!),
          success: false,
        );
        return;
      }

      final saved = await ref
          .read(profileNotifierProvider('me').notifier)
          .save({'cvUrl': upload.valueOrNull});
      if (!mounted) return;
      saved.when(
        success: (_) => attached = true,
        failure: (e) => showRungToast(
          context,
          arabicMessageForException(e),
          success: false,
        ),
      );
    } finally {
      // Same reasoning as `_pickAvatar`.
      if (mounted) {
        setState(() {
          _uploadingCv = false;
          if (!attached) _cvName = null;
        });
      }
    }
  }

  /// Clearing the flag is what releases the router; it then sends us to the
  /// feed on its own.
  ///
  /// [toSuggestions] overrides that landing for somebody who actually filled
  /// the form in: a network with nobody in it has nothing to show, so the
  /// useful next screen is people to connect to rather than a feed of three
  /// suggested posts. A SKIP goes straight to the feed — somebody who declined
  /// to say who they are is not asking to be introduced to anyone.
  Future<void> _leave({bool toSuggestions = false}) async {
    // The router is captured BEFORE the await, and `mounted` is deliberately
    // not consulted afterwards.
    //
    // `complete()` sets its state synchronously and only then awaits
    // SharedPreferences — so the refresh listener fires, the redirect sends
    // this screen to `/feed`, and the frame that unmounts it can land during
    // that platform round trip. Reading `context` after the await would then
    // be reading a dead element, and guarding on `mounted` would silently skip
    // the navigation that is the whole point of the flag.
    final router = GoRouter.of(context);
    await ref.read(profileSetupPendingProvider.notifier).complete();
    if (!toSuggestions) return;
    // After the flag, so the redirect no longer bounces this back.
    router.go('/welcome/connect');
  }

  Future<void> _save(AccountType accountType) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .save({
          'headline': _headline.text.trim(),
          'about': _about.text.trim(),
          'location': _location.text.trim(),
          'governorateId': _governorateId,
          'industry': _industry.text.trim(),
          'disciplineId': _disciplineId,
          // Every business page has a website field; only a person is
          // "open to work". Split on the reading, not on `company`, or a
          // contractor loses its website and gains a seeker's flag.
          if (accountType.isBusiness) 'website': _website.text.trim(),
          if (!accountType.isBusiness) 'openToWork': _openToWork,
        });

    if (!mounted) return;
    setState(() => _saving = false);

    await result.when(
      success: (_) async {
        if (!mounted) return;
        showRungToast(context, context.l10n.setupSaved);
        await _leave(toSuggestions: true);
      },
      failure: (e) async {
        if (!mounted) return;
        // Stays on the screen: the edits are still in the fields, and the
        // flag is untouched, so a retry costs one tap.
        showRungToast(context, arabicMessageForException(e), success: false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final profile = ref.watch(profileNotifierProvider('me'));
    final pendingEmail = ref.watch(pendingEmailProvider);
    // No uploader configured for this flavour means no photo or CV control at
    // all — the same rule sign-up and edit-profile follow. A camera button
    // that cannot upload is worse than no button.
    final canUpload = ref.watch(mediaUploadServiceProvider) != null;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        title: l10n.setupTitle,
        actions: [
          TextButton(
            // Also blocked while a photo or CV is in flight: both write to the
            // same profile row, and leaving mid-upload abandons it.
            onPressed: _busy ? null : _leave,
            style: TextButton.styleFrom(foregroundColor: c.ink2),
            child: Text(l10n.setupSkip),
          ),
        ],
      ),
      // `isLoading` is ALSO true while a refresh carries the previous value —
      // exactly the state that holds another account's profile after a switch.
      // A skeleton until the fresh one lands; see [_hydratedFor].
      body: profile.isLoading
          ? const FormSkeleton(fields: 5)
          : profile.when(
        loading: () => const FormSkeleton(fields: 5),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (data) {
          _hydrate(data);
          final type = data.accountType;
          // "Is this a business?" — company, contractor, craftsman, machinery
          // owner. What this form varies is which wording and which fields it
          // shows, and that splits on business/individual, not on company.
          final isCompany = type.isBusiness;
          // …except the specialty list, which three of the five kinds have and
          // two do not. A contractor and a company describe themselves in
          // their own words; the others pick from a list of their own.
          final disciplineLabel = type.disciplineLabel(context);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              RungSpace.gutter,
              RungSpace.md,
              RungSpace.gutter,
              RungSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              if (canUpload) ...[
                Center(
                  child: _AvatarWell(
                    seed: data.personId,
                    // From the profile already loaded, not a second
                    // provider: `currentPersonProvider` is cold on this route
                    // (no shell above it has warmed it), so reading it here
                    // showed a "؟" monogram to a person whose name we are
                    // holding, then popped to their initials a moment later.
                    initials: data.person.initials,
                    imageUrl: ref.watch(imageUrlResolverProvider)(
                      data.avatarUrl,
                    ),
                    busy: _uploadingAvatar,
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                  ),
                ),
                const SizedBox(height: RungSpace.md),
              ],
              Text(
                isCompany ? l10n.setupSubtitleCompany : l10n.setupSubtitle,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink3),
              ),
              const SizedBox(height: RungSpace.lg),

              // The one moment the address they typed at sign-up is still in
              // hand AND there is a session to attach it to. Offered, never
              // imposed: dismissing it costs one tap and the flag that holds
              // this person on this screen is untouched either way.
              if (pendingEmail != null) ...[
                _EmailOfferCard(
                  email: pendingEmail,
                  onConfirm: () => context.push('/settings/email'),
                  onDismiss: () =>
                      ref.read(pendingEmailProvider.notifier).dismiss(),
                ),
                const SizedBox(height: RungSpace.lg),
              ],

              RungField(
                label: l10n.setupHeadline,
                hint: isCompany
                    ? l10n.setupHeadlineHintCompany
                    : l10n.setupHeadlineHint,
                controller: _headline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: RungSpace.md),

              RungField(
                label: l10n.setupAbout,
                hint: isCompany
                    ? l10n.setupAboutHintCompany
                    : l10n.setupAboutHint,
                controller: _about,
                maxLines: 5,
                height: 120,
              ),
              const SizedBox(height: RungSpace.md),

              // The governorate, from the tenant's list — this replaced the
              // typed address. Companies keep the free-text box: a branch
              // address is not one of eighteen names.
              if (isCompany)
                RungField(
                  label: l10n.setupLocation,
                  hint: l10n.setupLocationHint,
                  controller: _location,
                  textInputAction: TextInputAction.next,
                )
              else
                GovernorateField(
                  label: l10n.setupGovernorate,
                  hint: l10n.setupGovernorateHint,
                  selectedId: _governorateId,
                  selectedName: _location.text,
                  onChanged: (governorate) => setState(() {
                    _governorateId = governorate?.id;
                    // The name rides along in the old field. Clearing leaves
                    // whatever was typed before the list existed alone.
                    if (governorate != null) _location.text = governorate.nameAr;
                  }),
                ),
              const SizedBox(height: RungSpace.md),

              // The specialty, from the tenant's list for this kind of
              // account: engineering branches, trades, or machinery. A company
              // and a contractor keep the free-text field — a construction
              // firm is not "هندسة مدنية", it employs people who are.
              if (disciplineLabel == null)
                RungField(
                  label: l10n.setupIndustry,
                  hint: l10n.setupIndustryHint,
                  controller: _industry,
                  textInputAction: TextInputAction.next,
                )
              else
                DisciplineField(
                  accountType: type,
                  label: disciplineLabel,
                  hint: l10n.setupDisciplineHint,
                  selectedId: _disciplineId,
                  selectedName: _industry.text,
                  onChanged: (discipline) => setState(() {
                    _disciplineId = discipline?.id;
                    // The name rides along in the old field, so a profile saved
                    // here still answers "same field as me" for everyone.
                    // Clearing the discipline leaves whatever was typed there
                    // before the list existed alone rather than erasing it.
                    if (discipline != null) _industry.text = discipline.nameAr;
                  }),
                ),

              if (isCompany) ...[
                const SizedBox(height: RungSpace.md),
                RungField(
                  label: l10n.setupWebsite,
                  controller: _website,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
              ] else ...[
                const SizedBox(height: RungSpace.md),
                RungToggleTile(
                  title: l10n.setupOpenToWork,
                  subtitle: l10n.setupOpenToWorkSubtitle,
                  value: _openToWork,
                  onChanged: (value) => setState(() => _openToWork = value),
                ),
              ],

              // Experience, education and skills are collections with their
              // own endpoints, not fields on this row — so they are links to
              // the editors that already exist rather than forms duplicated
              // here. The counts are what make an empty one worth tapping.
              //
              // Individual accounts only: a company has postings and an
              // "about", not a CV and a degree.
              if (!isCompany) ...[
                const SizedBox(height: RungSpace.lg),
                Text(
                  l10n.setupCareerTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.ink3,
                  ),
                ),
                const SizedBox(height: RungSpace.xs),
                _CareerRow(
                  icon: Icons.work_outline,
                  label: l10n.profileExperience,
                  count: data.experience.length,
                  onTap: () => context.push('/profile/me/experience'),
                ),
                _CareerRow(
                  icon: Icons.school_outlined,
                  label: l10n.profileEducation,
                  count: data.education.length,
                  onTap: () => context.push('/profile/me/education'),
                ),
                _CareerRow(
                  icon: Icons.bolt_outlined,
                  label: l10n.profileSkills,
                  count: data.skills.length,
                  onTap: () => context.push('/profile/me/skills'),
                ),
                if (canUpload)
                  _CareerRow(
                    icon: Icons.description_outlined,
                    label: l10n.setupCv,
                    // A storage path means nothing to a human, so the state is
                    // the file's name when we have it and "attached" when the
                    // profile came back with one from an earlier session.
                    trailing:
                        _cvName ??
                        ((data.cvUrl ?? '').isEmpty
                            ? null
                            : l10n.setupCvOnFile),
                    busy: _uploadingCv,
                    onTap: _uploadingCv ? null : _pickCv,
                  ),
              ],

              const SizedBox(height: RungSpace.lg),
              FilledButton(
                onPressed: _busy ? null : () => _save(data.accountType),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.setupSave),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The optional-second-factor offer, as it appears on the profile step.
///
/// A card rather than a banner: it is a thing to decide about, it names the
/// address so a typo is caught here rather than by a code that never arrives,
/// and it carries its own way out. Nothing on this screen depends on it.
class _EmailOfferCard extends StatelessWidget {
  const _EmailOfferCard({
    required this.email,
    required this.onConfirm,
    required this.onDismiss,
  });

  final String email;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungCard(
      padding: const EdgeInsets.all(RungSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.shield_outlined, size: 19, color: c.accent),
              ),
              const SizedBox(width: RungSpace.sm),
              Expanded(
                child: Text(
                  l10n.setupSecureTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Non-flex children of a Row get maxWidth: infinity, so at a
              // large text scale this can claim more room than is left.
              Flexible(
                child: Text(
                  l10n.setupSecureOptional,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: RungSpace.sm),
          Text(
            l10n.setupSecureBody,
            style: TextStyle(fontSize: 12.5, color: c.ink2, height: 1.6),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // An address reads left-to-right even inside an RTL column.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: RungSpace.sm),
          Row(
            children: [
              // Non-flex children of a Row, and the theme gives every button a
              // minimum width of infinity — see `app_theme.dart`. Both of
              // these override it, which is what keeps this row laying out.
              FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: RungSpace.md,
                  ),
                ),
                child: Text(l10n.setupSecureAction),
              ),
              const SizedBox(width: RungSpace.xs),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  foregroundColor: c.ink3,
                ),
                child: Text(l10n.setupSecureDismiss),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The tappable avatar on the profile step.
///
/// A monogram until there is a photo, which is what `RungAvatar` already does
/// — this only adds the camera badge and the busy state over it.
class _AvatarWell extends StatelessWidget {
  const _AvatarWell({
    required this.seed,
    required this.initials,
    required this.imageUrl,
    required this.busy,
    required this.onTap,
  });

  final String seed;
  final String initials;
  final String? imageUrl;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.authPhotoPick,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          // Directional, matching where edit-profile puts the same badge.
          // `Alignment.bottomLeft` coincides with it only in Arabic, and this
          // app ships an English locale as well.
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            RungAvatar(
              seed: seed,
              initials: initials,
              size: 92,
              imageUrl: imageUrl,
            ),
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
              child: busy
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of the career section: an icon, a label, and either how many
/// entries there are or what is attached.
class _CareerRow extends StatelessWidget {
  const _CareerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.trailing,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? count;
  final String? trailing;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    // "أضف" rather than "0" for an empty one: a zero reads as a value that has
    // been recorded, and this is an invitation.
    final value = trailing ??
        (count == null || count == 0 ? l10n.actionAdd : '$count');

    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(RungRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: RungSpace.sm,
          horizontal: 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.ink3),
            const SizedBox(width: RungSpace.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // `Expanded`, not `Flexible`, and the busy branch is a flex slot
            // too. A Row splits free space by flex: a tight Expanded label
            // beside a LOOSE Flexible value takes half the row and leaves the
            // remainder stranded after the last child — the chevron floats in
            // from the edge, by a different amount per row, and jumps when the
            // spinner (a non-flex box) replaces the value.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: busy
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.ink3,
                        ),
                      )
                    : Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: c.ink3,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            // `chevron_right`, which Flutter MIRRORS under RTL and therefore
            // renders pointing left — the forward affordance in Arabic.
            // `chevron_left` mirrors the other way and reads as "back".
            Icon(Icons.chevron_right, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}
