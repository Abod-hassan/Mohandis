import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/utils/pick_cropped_image.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/image_viewer.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../notifiers/profile_notifier.dart';

/// The cover image across the top of a profile.
///
/// **An empty banner is a seeded gradient, not a grey box.** A profile with no
/// cover is the normal state, not a missing asset, and the gradient is the same
/// one that stands in for this person's avatar everywhere else — so the page
/// reads as deliberately theirs rather than half-loaded.
///
/// The owner gets a button on it; everyone else can tap a cover that exists to
/// see it full size, and nothing at all when there is none.
class ProfileBanner extends ConsumerStatefulWidget {
  /// Published because the header stacks the avatar across this edge and has
  /// to know where the edge is. A number copied into the header instead would
  /// go stale the first time this one changed, and the symptom — an avatar
  /// floating in the cover, or sunk below it — is the kind that only shows up
  /// on a device.
  static const double height = 140;

  const ProfileBanner({
    super.key,
    required this.coverUrl,
    required this.seed,
    required this.isMe,
    required this.providerKey,
  });

  /// Host-less, like every other stored asset.
  final String? coverUrl;

  /// The profile id — what the placeholder gradient is derived from, so a
  /// person's empty banner and their monogram avatar are the same colours.
  final String seed;

  final bool isMe;

  /// The key the enclosing screen read [profileNotifierProvider] with — `me`
  /// on the signed-in account's own route, their profile id when the page was
  /// reached by id. A write has to publish onto THAT instance: publishing onto
  /// the wrong one of the family saves the cover and leaves the old one drawn.
  final String providerKey;

  @override
  ConsumerState<ProfileBanner> createState() => _ProfileBannerState();
}

class _ProfileBannerState extends ConsumerState<ProfileBanner> {
  bool _busy = false;

  Future<void> _pick() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    // Cropped to the banner's own 3:1 before upload, so the person chooses
    // which strip of the photo is shown instead of finding out afterwards
    // what the layout cut off.
    final String? localPath;
    try {
      localPath = await pickCroppedImage(context, shape: ImageCropShape.banner);
    } catch (e) {
      if (mounted) {
        showRungToast(context, arabicMessageForException(e), success: false);
      }
      return;
    }
    if (localPath == null || !mounted) return;

    setState(() => _busy = true);
    final upload = await uploader.uploadImage(localPath, folder: 'covers');
    if (!mounted) return;

    final path = upload.valueOrNull;
    if (path == null) {
      setState(() => _busy = false);
      showRungToast(
        context,
        arabicMessageForException(upload.errorOrNull ?? 'upload failed'),
        success: false,
      );
      return;
    }

    await _save(path);
  }

  /// Writes the cover and publishes the profile it reads back.
  ///
  /// Goes through the notifier's `save` rather than the repository directly:
  /// that one sets the new profile as the provider's state — so the banner
  /// changes with no loading flash — and invalidates `currentPerson` and the
  /// people directory, which is what keeps the avatar and name drawn by the
  /// feed, search and messages from lagging a profile edit.
  ///
  /// Removal passes an EMPTY STRING, not null. The write goes through the
  /// Kernel's generic engine, which writes whatever column values it is handed
  /// with no module-level validation — and `''` resolves to "no image"
  /// everywhere in the app already ([imageUrlResolverProvider] returns null for
  /// it), so there is nothing to gain from betting on how a null travels.
  Future<void> _save(String path) async {
    setState(() => _busy = true);
    final result = await ref
        .read(profileNotifierProvider(widget.providerKey).notifier)
        .save({'coverUrl': path});

    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) => showRungToast(context, context.l10n.profileBannerSaved),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  Future<void> _menu() async {
    final l10n = context.l10n;
    final has = (widget.coverUrl ?? '').isNotEmpty;

    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: sheet.rung.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RungRadius.lg),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: RungSpace.sm),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(has ? l10n.profileBannerChange : l10n.profileBannerAdd),
                onTap: () => Navigator.of(sheet).pop(false),
              ),
              if (has)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: sheet.rung.red),
                  title: Text(
                    l10n.profileBannerRemove,
                    style: TextStyle(color: sheet.rung.red),
                  ),
                  onTap: () => Navigator.of(sheet).pop(true),
                ),
              const SizedBox(height: RungSpace.sm),
            ],
          ),
        ),
      ),
    );

    if (remove == null || !mounted) return;
    if (remove) {
      await _save('');
    } else {
      await _pick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = ref.watch(imageUrlResolverProvider)(widget.coverUrl);

    return SizedBox(
      height: ProfileBanner.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RungGradients.forSeed(widget.seed),
            ),
          ),
          if (url != null)
            GestureDetector(
              onTap: () => showImageViewer(context, urls: [url]),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // The gradient underneath is the fallback; a broken-image
                // glyph across the top of a profile reads as a crash.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          if (widget.isMe)
            PositionedDirectional(
              bottom: 10,
              end: 10,
              child: _Button(
                busy: _busy,
                label: url == null ? l10n.profileBannerAdd : null,
                onTap: _busy ? null : _menu,
              ),
            ),
        ],
      ),
    );
  }
}

/// The owner's control. Carries its label only while the banner is empty —
/// over a photo the icon is enough, and a pill of text would cover the picture
/// it is there to change.
class _Button extends StatelessWidget {
  const _Button({required this.busy, required this.label, required this.onTap});

  final bool busy;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: RungRadius.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 9 : 12,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              if (label != null) ...[
                const SizedBox(width: 7),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
