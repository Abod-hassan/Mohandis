import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/l10n/l10n.dart';

/// What the picked image will be shown as, which decides the crop.
enum ImageCropShape {
  /// The round profile photo. Cropped square under a circular guide — the
  /// file stays square so every place that draws it, round or not, has the
  /// whole picture to work with.
  avatar,

  /// The wide strip across the top of a profile, drawn the full screen width
  /// and 140pt tall. 3:1 sits between a small phone (about 2.7:1) and a large
  /// one (about 3.1:1), so the crop shown here is very nearly what visitors see.
  banner,
}

extension on ImageCropShape {
  CropAspectRatio get ratio => switch (this) {
        ImageCropShape.avatar => const CropAspectRatio(ratioX: 1, ratioY: 1),
        ImageCropShape.banner => const CropAspectRatio(ratioX: 3, ratioY: 1),
      };

  /// Largest size the CROPPED file is saved at. An avatar is drawn at 88pt at
  /// most and a banner at screen width; past these, every visitor to the
  /// profile pays for pixels no screen shows.
  (int, int) get output => switch (this) {
        ImageCropShape.avatar => (1024, 1024),
        ImageCropShape.banner => (1500, 500),
      };

  CropStyle get style => switch (this) {
        ImageCropShape.avatar => CropStyle.circle,
        ImageCropShape.banner => CropStyle.rectangle,
      };
}

/// Lets the person choose a photo, then crop it to [shape].
///
/// Returns the path of the CROPPED file, or null when they backed out of
/// either step — the picker or the crop screen — which every caller treats as
/// "nothing changed", exactly as a cancelled picker always was.
///
/// **Picked large, cropped small.** The picker is asked for a generous size
/// and the cropper does the shrinking, so the part the person keeps is cut
/// from a sharp original rather than enlarged from an already-reduced one.
///
/// Throws what the picker or the cropper throw — a denied photo permission,
/// an unreadable file. Callers already catch around the picker and show the
/// mapped message; that is unchanged.
Future<String?> pickCroppedImage(
  BuildContext context, {
  required ImageCropShape shape,
}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 3000,
    maxHeight: 3000,
    imageQuality: 95,
  );
  if (picked == null || !context.mounted) return null;

  final l10n = context.l10n;
  final c = context.rung;
  final title = shape == ImageCropShape.avatar
      ? l10n.cropAvatarTitle
      : l10n.cropBannerTitle;
  final (maxWidth, maxHeight) = shape.output;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    // Locked: a banner cropped to a square would be cut again by the layout,
    // and the person would never have seen which part survives.
    aspectRatio: shape.ratio,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: c.surface,
        toolbarWidgetColor: c.ink,
        activeControlsWidgetColor: c.accent,
        lockAspectRatio: true,
        cropStyle: shape.style,
      ),
      IOSUiSettings(
        title: title,
        doneButtonTitle: l10n.cropDone,
        cancelButtonTitle: l10n.cropCancel,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        cropStyle: shape.style,
      ),
    ],
  );
  return cropped?.path;
}
