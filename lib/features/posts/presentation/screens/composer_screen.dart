import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/services/media_upload_service.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/reels/presentation/notifiers/reels_notifier.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/stories/presentation/notifiers/stories_notifier.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../widgets/mention_suggestions.dart';
import '../widgets/post_visibility_label.dart';

/// What this composer is publishing.
///
/// One screen rather than three, because the three share almost everything —
/// an author header, a text field, a picker, an upload queue and a publish
/// button — and differ only in what media they accept and which endpoint they
/// end at. Three screens would be three copies of the upload state machine,
/// and the second copy is where they start to drift.
enum ComposerMode {
  post,
  story,
  reel;

  /// Parses the `?mode=` query the router passes through. Anything unknown —
  /// an old deep link, a typo in a push payload — falls back to a post rather
  /// than failing the navigation.
  static ComposerMode fromWire(String? raw) => switch (raw?.trim()) {
    'story' => ComposerMode.story,
    'reel' => ComposerMode.reel,
    _ => ComposerMode.post,
  };

  /// What a person can attach here.
  ///
  /// A story takes either a photo or a clip; a reel is a video by definition —
  /// `PublishReelDto.VideoUrl` is required server-side and there is nothing
  /// else to put in it. Documents belong only to a post.
  Set<MediaKind> get kinds => switch (this) {
    ComposerMode.post => const {MediaKind.image, MediaKind.document},
    ComposerMode.story => const {MediaKind.image, MediaKind.video},
    ComposerMode.reel => const {MediaKind.video},
  };

  /// A story and a reel are ONE piece of media — the endpoints take a single
  /// `mediaUrl` / `videoUrl`, so a second attachment has nowhere to go.
  int get maxAttachments => this == ComposerMode.post ? 4 : 1;

  /// A post can be words alone. The other two cannot: both endpoints reject a
  /// publish with no media, so offering the button would only buy a round trip
  /// and a server error in Arabic.
  bool get allowsTextOnly => this == ComposerMode.post;

  /// Visibility is a post column. `StoryModel` and `ReelModel` have no
  /// equivalent, so showing the pill would promise an audience control that
  /// the publish silently drops.
  bool get hasVisibility => this == ComposerMode.post;

  /// Hashtags and mentions are parsed out of a post's body server-side
  /// (`TextParsing` in `PostService.PublishAsync`). Neither `StoryService` nor
  /// `ReelService` calls it, so a `#tag` in a caption is just text — and a
  /// button that inserts one here would be an affordance for nothing.
  bool get parsesTags => this == ComposerMode.post;

  String label(BuildContext context) => switch (this) {
    ComposerMode.post => context.l10n.composerModePost,
    ComposerMode.story => context.l10n.composerModeStory,
    ComposerMode.reel => context.l10n.composerModeReel,
  };

  String title(BuildContext context) => switch (this) {
    ComposerMode.post => context.l10n.composerTitle,
    ComposerMode.story => context.l10n.composerTitleStory,
    ComposerMode.reel => context.l10n.composerTitleReel,
  };

  String hint(BuildContext context) => switch (this) {
    ComposerMode.post => context.l10n.composerHint,
    ComposerMode.story => context.l10n.composerHintStory,
    ComposerMode.reel => context.l10n.composerHintReel,
  };

  IconData get icon => switch (this) {
    ComposerMode.post => Icons.article_outlined,
    ComposerMode.story => Icons.auto_awesome_outlined,
    ComposerMode.reel => Icons.movie_creation_outlined,
  };
}

/// Full-screen composer for a post, a story or a reel — chosen by the
/// segmented control at the top, which can be changed mid-compose.
///
/// Visibility cycles public → followers → private through the pill under the
/// author name, and shows only in post mode.
class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key, this.initialMode = ComposerMode.post});

  /// Where the composer opens. The story rail's "+" lands on
  /// [ComposerMode.story] rather than making somebody switch after arriving.
  final ComposerMode initialMode;

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

/// One picked photo, from the moment it is chosen to the moment it has a
/// stored path.
///
/// The upload starts as soon as the photo is picked rather than at publish
/// time. Two reasons: the person can see it fail (and remove it) while they
/// are still writing, and tapping "Post" then costs one request instead of
/// a chain that can strand a half-uploaded post behind a spinner.
class _Attachment {
  _Attachment.image(this.localPath)
    : kind = MediaKind.image,
      fileName = null,
      sizeBytes = null;

  _Attachment.document(this.localPath, this.fileName, this.sizeBytes)
    : kind = MediaKind.document;

  _Attachment.video(this.localPath, this.fileName, this.sizeBytes)
    : kind = MediaKind.video;

  final String localPath;

  /// Decides the tile, the upload call and what is sent on publish. A document
  /// is not an image with a different icon: it uploads under its own extension
  /// allow-list and carries a name the image path has no use for.
  final MediaKind kind;

  /// The name the person picked it under. Kept because the stored path is a
  /// generated uuid — nothing else carries it to the other side.
  final String? fileName;

  final int? sizeBytes;

  bool get isDocument => kind == MediaKind.document;
  bool get isVideo => kind == MediaKind.video;

  /// The host-less path Bunny holds it at, once the upload succeeds.
  String? storedPath;

  /// The CDN prefix this attachment's upload is AIMED at.
  ///
  /// Written when the upload STARTS, not when it succeeds. That is the whole
  /// point: an upload takes minutes for a clip, and the mode can change while
  /// it is in flight. Recording it only on success would leave this null for
  /// exactly that window — [_ComposerScreenState._setMode] would see nothing
  /// to restage, the in-flight upload would land under the OLD mode's prefix,
  /// and a reel's video would sit in `stories/` waiting for that folder's
  /// 24-hour lifecycle rule to delete it.
  ///
  /// It doubles as the supersede token: when a restage re-points this, the
  /// older `_upload` sees the mismatch and discards its own result rather than
  /// overwriting the newer one.
  String? targetFolder;

  /// 0..1 while bytes are moving, null when the total is unknown.
  ///
  /// A photo uploads in a moment and a spinner is fine; a 100 MB clip takes
  /// minutes, and an indeterminate spinner for minutes is indistinguishable
  /// from a hang.
  double? progress;

  /// Last whole percent published to the UI.
  ///
  /// `file.openRead()` emits ~64 KB chunks, so a 150 MB clip fires roughly
  /// 2,400 progress callbacks. Repainting the whole composer — text field,
  /// video preview and all — on every one of them is minutes of continuous
  /// rebuilding for a ring that cannot show the difference.
  int _lastPercent = -1;

  /// Pixel dimensions of the picked file, measured before upload.
  ///
  /// Sent with the post so the feed can lay the tile out at its real shape.
  /// Without them the server stores nulls and every photo comes back as a 1:1
  /// tile — a portrait shot centre-cropped to a square.
  int? width;
  int? height;

  /// Set when the upload failed. The tile shows a retry rather than vanishing:
  /// silently dropping a photo someone chose is worse than making them tap.
  Object? error;

  /// Read off the initialised preview controller, and sent with a reel so the
  /// wall can show a length before the file is touched. Null on anything that
  /// is not a video, and on a clip the player could not open.
  double? durationSeconds;

  /// Muted, looping preview of a picked clip.
  ///
  /// Owned by the attachment rather than the tile: the tile is rebuilt on
  /// every keystroke and a controller created in `build` would restart the
  /// video each time and leak the one before it.
  VideoPlayerController? preview;

  bool uploading = true;

  bool get isReady => storedPath != null;

  /// Releases the player, if any. Idempotent — called from remove, from a
  /// mode switch that drops the attachment, and from the screen's dispose.
  void disposePreview() {
    preview?.dispose();
    preview = null;
  }
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _controller = TextEditingController();

  /// Held so the hashtag button can put the keyboard back after inserting a
  /// character — tapping the bar takes focus off the field, and without this
  /// the caret it just placed is invisible and unusable.
  final _focusNode = FocusNode();
  PostVisibility _visibility = PostVisibility.public;
  bool _publishing = false;

  late ComposerMode _mode = widget.initialMode;

  final List<_Attachment> _attachments = [];

  /// `PostMediaGrid` renders two tiles and collapses the rest behind a "+N"
  /// veil, so four is the most that still reads as a deliberate set rather
  /// than an unbounded pile the feed can only hint at. The backend imposes no
  /// limit of its own. A story and a reel take one — see
  /// [ComposerMode.maxAttachments], which is what this now defers to.
  int get _maxAttachments => _mode.maxAttachments;

  /// The largest clip this app will try to upload.
  ///
  /// 150 MB is roughly 90 seconds of 1080p from a phone camera, and about ten
  /// minutes of transfer on a slow uplink — the point past which the upload's
  /// own timeout, not the file, becomes the thing that fails. Neither the
  /// backend nor Bunny imposes this; it is a promise about what will finish.
  static const int _maxVideoBytes = 150 * 1024 * 1024;

  /// The largest document this app will try to upload.
  ///
  /// Smaller than the video cap on purpose: a clip is the post, and a 500 MB
  /// project archive is an attachment nobody scrolling a feed is going to
  /// open. Nothing compresses on the way out, so an unbounded pick is an
  /// unbounded transfer on somebody's mobile data — and with the send timeout
  /// now at ten minutes, the thing that used to refuse it by accident no
  /// longer does.
  static const int _maxDocumentBytes = 40 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    // The suggestion strip is read from the caret, and the caret moves on a
    // tap as well as on a keystroke. `onChanged` only fires for the latter,
    // which would leave a strip standing over a word the cursor has left.
    _controller.addListener(_onEditingChanged);
  }

  void _onEditingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onEditingChanged);
    _controller.dispose();
    _focusNode.dispose();
    // Every picked clip holds a platform player. Leaving one alive keeps a
    // decoder — and on iOS an audio session — for a screen that is gone.
    for (final attachment in _attachments) {
      attachment.disposePreview();
    }
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;
  bool get _uploading => _attachments.any((a) => a.uploading);
  bool get _readyMedia => _attachments.any((a) => a.isReady);

  /// Mirrors each endpoint's own rule, and additionally waits for uploads,
  /// since publishing mid-upload would drop the media without saying so.
  ///
  /// A post is text or media; a story and a reel are media, full stop — both
  /// services answer "A story needs media." / "A reel needs a video." to a
  /// publish without one, and that refusal is better prevented than
  /// translated.
  bool get _canPublish {
    if (_publishing || _uploading) return false;
    return _mode.allowsTextOnly ? (_hasText || _readyMedia) : _readyMedia;
  }

  /// Switches what is being composed, keeping the text and whatever media
  /// still fits.
  ///
  /// Dropping an attachment the new mode cannot carry is said out loud: three
  /// photos silently vanishing on the way from a post to a reel is the kind of
  /// thing people notice only after publishing.
  void _setMode(ComposerMode mode) {
    if (mode == _mode) return;
    // A publish is already in flight against the old mode. Switching now would
    // restage media the request has already sent, and the screen pops the
    // moment that request returns — leaving a half-written object under a
    // prefix nothing will ever reference.
    if (_publishing) return;

    final kept = <_Attachment>[];
    final dropped = <_Attachment>[];
    for (final attachment in _attachments) {
      // Two rules, both from the new mode: the kind has to be one it accepts,
      // and it has to fit under its cap — a story cannot take the second of
      // two photos a post was happy with.
      if (mode.kinds.contains(attachment.kind) &&
          kept.length < mode.maxAttachments) {
        kept.add(attachment);
      } else {
        dropped.add(attachment);
      }
    }

    for (final attachment in dropped) {
      attachment.disposePreview();
    }

    // A kept attachment is already on the CDN under the OLD mode's prefix, and
    // nothing moves it. Re-uploading is the only way its stored path ends up
    // where the new mode's lifecycle rules apply: a post's image left in
    // `stories/` would be reaped in 24 hours, and a story's media left in
    // `posts/` would outlive its rail forever. The orphan under the old prefix
    // is the same few KB `_remove` already chooses to leave behind.
    final folder = _folderFor(mode);
    final restaged = [
      for (final attachment in kept)
        // `targetFolder` is set the moment an upload starts, so this catches
        // the in-flight case as well as the finished one. Comparing a
        // success-only field would miss exactly the window that matters: the
        // minutes a clip spends uploading, which is when somebody actually
        // changes their mind.
        if (attachment.targetFolder != null &&
            attachment.targetFolder != folder)
          attachment,
    ];
    for (final attachment in restaged) {
      attachment
        ..uploading = true
        ..error = null
        ..progress = null
        ..storedPath = null
        ..targetFolder = null;
    }

    setState(() {
      _mode = mode;
      _attachments
        ..clear()
        ..addAll(kept);
    });

    // After the setState, so `_upload` reads the mode it is uploading for.
    for (final attachment in restaged) {
      _upload(attachment);
    }

    if (dropped.isNotEmpty) {
      showRungToast(context, context.l10n.composerModeDropped, success: false);
    }
  }

  Future<void> _pickImages() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    // Said, not swallowed. This is null whenever the server has no Bunny zone
    // configured, and the old behaviour — hide the button, return silently —
    // was indistinguishable from a broken app: a control that does nothing and
    // explains nothing is worse than one that refuses out loud.
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    // A story holds one photo, and picking a second means "this one instead",
    // exactly as picking a second clip does. Only a post, which holds several,
    // can actually run out of room.
    final single = _maxAttachments == 1;
    final remaining = single ? 1 : _maxAttachments - _attachments.length;
    if (remaining <= 0) {
      showRungToast(
        context,
        context.l10n.composerPhotoLimit(_maxAttachments),
        success: false,
      );
      return;
    }

    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        // Sized for a feed card on a high-DPI phone. Uploading a 12 MP
        // original would cost the person's data and buy no visible quality.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }
    if (picked.isEmpty || !mounted) return;

    final accepted = picked.take(remaining).toList(growable: false);
    final replacing = single && _attachments.isNotEmpty;
    if (picked.length > accepted.length || replacing) {
      showRungToast(
        context,
        // `composerPhotoLimit` is a plural written for a post's cap of four —
        // in story mode it would read "you can attach 1 photos", and it would
        // be describing a refusal that does not happen: a second pick here
        // replaces the first.
        single
            ? context.l10n.composerSingleMediaOnly
            : context.l10n.composerPhotoLimit(_maxAttachments),
        // A swap is the thing the person asked for, not a refusal. Only the
        // post cap is a "no".
        success: single,
      );
    }

    final added = [for (final file in accepted) _Attachment.image(file.path)];
    if (single) {
      // The replacement is total, players included — see _pickVideo.
      for (final old in _attachments) {
        old.disposePreview();
      }
      _attachments.clear();
    }
    setState(() => _attachments.addAll(added));
    for (final attachment in added) {
      _upload(attachment);
    }
  }

  /// Puts an `@` where the cursor is, which is also what opens the suggestion
  /// strip — [MentionQuery.at] reads the text before the caret, so the strip
  /// appears as soon as two letters follow.
  void _insertMention() => _insertToken('@');

  /// Replaces the `@token` under the caret with the handle that was tapped.
  ///
  /// The EXACT handle, from the server. A mention is parsed back out of the
  /// text, so a near-miss — a display name, a stripped diacritic — becomes
  /// plain words and the person is never notified. That silent failure is the
  /// whole reason this picker exists rather than leaving people to type it.
  void _applyMention(MentionQuery query, String username) {
    final text = _controller.text;

    // A trailing space so the next word is not swallowed into the handle, and
    // so the server's word-boundary rule holds on the right-hand side too.
    final insert = '@$username ';
    final next = text.replaceRange(query.start, query.end, insert);

    _controller.value = _controller.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: query.start + insert.length),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  /// Puts a `#` where the cursor is and leaves the caret after it.
  ///
  /// The server parses hashtags out of the text itself, so this is an
  /// affordance rather than a data path: it tells somebody the feature exists
  /// and saves them hunting for the key on an Arabic layout. A space is added
  /// first when the character before the caret is not one, because the parser
  /// requires a word boundary — `شيء#هندسة` is not a hashtag on either side.
  void _insertHashtag() => _insertToken('#');

  void _insertToken(String token) {
    final value = _controller.value;
    final selection = value.selection;
    final text = value.text;

    // A collapsed caret is the normal case; an unset selection means the field
    // was never focused, so append.
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final needsSpace = start > 0 && !RegExp(r'\s').hasMatch(text[start - 1]);
    final insert = needsSpace ? ' $token' : token;

    _controller.value = value.copyWith(
      text: text.replaceRange(start, end, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  /// Attaches a document — a PDF, a spreadsheet, whatever the platform picker
  /// offers.
  ///
  /// Shares the attachment list and the limit with photos on purpose: they are
  /// the same thing to the post, and two separate caps would let somebody
  /// attach twice as much by splitting it across the two buttons.
  Future<void> _pickDocuments() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    final remaining = _maxAttachments - _attachments.length;
    if (remaining <= 0) {
      showRungToast(
        context,
        context.l10n.composerPhotoLimit(_maxAttachments),
        success: false,
      );
      return;
    }

    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        // A named type set rather than FileType.any: the upload allow-lists
        // these extensions anyway, and letting somebody pick a 400 MB video
        // only to have it rejected after the wait is a worse answer than not
        // offering it.
        type: FileType.custom,
        allowedExtensions: const [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'csv', 'rtf', 'zip',
        ],
      );
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }

    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty || !mounted) return;

    // Two filters, kept apart: a file the picker handed back without a path
    // is a provider quirk, not an oversized file, and telling somebody their
    // document is too big when it is not would send them looking for a
    // smaller one that would fail the same way.
    final readable = files.where((f) => f.path != null).toList(growable: false);
    final usable = readable
        .where((f) => f.size <= _maxDocumentBytes)
        .toList(growable: false);
    if (usable.length < readable.length) {
      showRungToast(
        context,
        context.l10n.composerDocumentTooLarge(
          _maxDocumentBytes ~/ (1024 * 1024),
        ),
        success: false,
      );
    }

    final accepted = usable.take(remaining).toList(growable: false);
    if (usable.length > accepted.length) {
      showRungToast(
        context,
        context.l10n.composerPhotoLimit(_maxAttachments),
        success: false,
      );
    }
    if (accepted.isEmpty) return;

    final added = [
      for (final file in accepted)
        _Attachment.document(file.path!, file.name, file.size),
    ];
    setState(() => _attachments.addAll(added));
    for (final attachment in added) {
      _upload(attachment);
    }
  }

  /// Picks one clip for a story or a reel.
  ///
  /// Single, not multiple: both endpoints take one URL. Picking a second when
  /// one is already there REPLACES it rather than refusing — somebody who
  /// taps the video button with a clip already chosen wants a different clip,
  /// and making them remove the first one first is a step for nothing.
  Future<void> _pickVideo() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }
    if (picked == null || !mounted) return;

    // `XFile` carries no size, and the tile shows one. Reading it can throw on
    // a file the provider has already reaped, which is not worth failing the
    // pick over — the tile just shows no size.
    int? size;
    try {
      size = await File(picked.path).length();
    } catch (_) {
      size = null;
    }
    if (!mounted) return;

    // Refused here rather than discovered after a ten-minute upload. Nothing
    // compresses on the way out — the file is PUT as it sits on disk — so an
    // unbounded pick is an unbounded transfer on somebody's mobile data, and
    // the upload's own ceiling would report it as a network failure minutes
    // later instead of as the one thing it is: too big.
    if (size != null && size > _maxVideoBytes) {
      showRungToast(
        context,
        context.l10n.composerVideoTooLarge(_maxVideoBytes ~/ (1024 * 1024)),
        success: false,
      );
      return;
    }

    final attachment = _Attachment.video(picked.path, picked.name, size);

    // The replacement is total: the old clip's player goes with it, or the
    // decoder stays alive behind a tile nobody can see.
    final replaced = List<_Attachment>.from(_attachments);
    for (final old in replaced) {
      old.disposePreview();
    }
    setState(() {
      _attachments
        ..clear()
        ..add(attachment);
    });

    _preparePreview(attachment);
    _upload(attachment);
  }

  /// Opens the picked clip in a muted, looping player and records its length.
  ///
  /// Failure is deliberately quiet: a clip the device cannot decode can still
  /// upload and still play on other people's phones, so a preview that does
  /// not come up falls back to the document-style tile rather than blocking
  /// the publish.
  Future<void> _preparePreview(_Attachment attachment) async {
    final controller = VideoPlayerController.file(File(attachment.localPath));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      // Muted, always. A composer that starts talking the moment a clip is
      // picked is the reason people compose in silence.
      await controller.setVolume(0);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      return;
    }

    // Disposed while initialising — the screen was popped, or the clip was
    // replaced by another pick. Either way this controller has no tile left.
    if (!mounted || !_attachments.contains(attachment)) {
      await controller.dispose();
      return;
    }

    setState(() {
      attachment.preview = controller;
      final duration = controller.value.duration;
      attachment.durationSeconds = duration > Duration.zero
          ? duration.inMilliseconds / 1000
          : null;
    });
  }

  /// Where this mode's media belongs on the CDN.
  ///
  /// A zone-wide rule, a purge or a lifecycle policy is written against a
  /// prefix, and there is no way to separate the kinds again once they share
  /// one — so `stories/` can carry a 24-hour rule that must never touch a
  /// post's images.
  static String _folderFor(ComposerMode mode) => switch (mode) {
    ComposerMode.post => 'posts',
    ComposerMode.story => 'stories',
    ComposerMode.reel => 'reels',
  };

  /// Uploads one attachment, in the background, updating its tile in place.
  ///
  /// Deliberately not awaited by the caller: several photos upload at once,
  /// and each one's tile resolves as it lands rather than all of them waiting
  /// on the slowest.
  Future<void> _upload(_Attachment attachment) async {
    final uploader = ref.read(mediaUploadServiceProvider);
    // Not a silent return: `_canPublish` waits on `uploading`, so leaving the
    // flag set here would spin the tile forever and disable Post with no way
    // back but removing the photo. The zone can genuinely be missing at this
    // point — it is re-read after the picker await, and it reads null while
    // `storageZoneProvider` is refreshing.
    if (uploader == null) {
      if (!mounted) return;
      setState(() {
        attachment.uploading = false;
        attachment.error = const UnknownException(
          'Storage is not configured on this server',
        );
        // Surfaced as well as recorded: the tile's retry says "something went
        // wrong", which is not true — nothing will go right until the server
        // has a zone, and retrying forever is the wrong thing to invite.
        showRungToast(context, context.l10n.composerUploadsOff, success: false);
      });
      return;
    }

    // Measured before the upload rather than after: image_picker has already
    // applied maxWidth/maxHeight and the quality re-encode, so the file on
    // disk is exactly what Bunny will hold. Skipped for a document, which has
    // no pixels and would only cost a failed decode.
    // Claimed BEFORE any await, so `_setMode` can see where this upload is
    // going while it is still going there — and so a restage that re-points
    // the attachment makes this call recognise itself as superseded.
    final folder = _folderFor(_mode);
    attachment.targetFolder = folder;
    attachment._lastPercent = -1;

    final size = attachment.kind == MediaKind.image
        ? await _measure(attachment.localPath)
        : null;

    // Each kind gets its own call rather than one with a different folder: an
    // image upload renames anything it does not recognise to .jpg, which would
    // have the CDN serve a spreadsheet — or an .mov — as a picture.
    void report(int sent, int total) {
      if (!mounted || total <= 0) return;
      // Superseded by a restage — its own `report` owns the ring now.
      if (attachment.targetFolder != folder) return;

      final fraction = (sent / total).clamp(0, 1).toDouble();
      final percent = (fraction * 100).round();
      if (percent == attachment._lastPercent) return;
      attachment._lastPercent = percent;
      setState(() => attachment.progress = fraction);
    }

    final result = switch (attachment.kind) {
      MediaKind.document => await uploader.uploadDocument(
        attachment.localPath,
        folder: folder,
        onProgress: report,
      ),
      MediaKind.video => await uploader.uploadVideo(
        attachment.localPath,
        folder: folder,
        onProgress: report,
      ),
      MediaKind.image => await uploader.uploadImage(
        attachment.localPath,
        folder: folder,
        onProgress: report,
      ),
    };
    if (!mounted) return;

    // A restage re-pointed this attachment while the bytes were moving. The
    // newer `_upload` owns it now: publishing this result would overwrite the
    // path it is about to produce, and clearing `uploading` would let Publish
    // light up over an upload that is still running.
    if (attachment.targetFolder != folder) return;

    setState(() {
      attachment.uploading = false;
      attachment.progress = null;
      attachment.width = size?.$1;
      attachment.height = size?.$2;
      result.when(
        success: (path) {
          attachment.storedPath = path;
          attachment.error = null;
        },
        failure: (e) => attachment.error = e,
      );
    });
  }

  /// The picked file's pixel dimensions, or null if it cannot be decoded.
  ///
  /// A failure here is not worth failing the upload over — the post still
  /// publishes, the tile just falls back to 1:1.
  static Future<(int, int)?> _measure(String path) async {
    ui.Image? decoded;
    try {
      final bytes = await File(path).readAsBytes();
      decoded = await decodeImageFromList(bytes);
      return (decoded.width, decoded.height);
    } catch (_) {
      return null;
    } finally {
      decoded?.dispose();
    }
  }

  void _retry(_Attachment attachment) {
    setState(() {
      attachment.uploading = true;
      attachment.error = null;
      attachment.width = null;
      attachment.height = null;
      attachment.progress = null;
      attachment.storedPath = null;
      attachment.targetFolder = null;
    });
    _upload(attachment);
  }

  void _remove(_Attachment attachment) {
    // The uploaded file is left on the CDN rather than deleted. Deleting would
    // need the zone's write key to also grant delete on an arbitrary path, and
    // an orphan under `posts/` costs a few KB — the wrong trade to make on a
    // key that lives on the device.
    attachment.disposePreview();
    setState(() => _attachments.remove(attachment));
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() => _publishing = true);

    final ok = switch (_mode) {
      ComposerMode.post => await _publishPost(),
      ComposerMode.story => await _publishStory(),
      ComposerMode.reel => await _publishReel(),
    };

    if (!mounted) return;
    setState(() => _publishing = false);
    if (ok && context.canPop()) context.pop();
  }

  /// The one attachment a story or a reel publishes, or null if the upload has
  /// not landed. `_canPublish` already waits on `_readyMedia`, so null here
  /// means the state changed under the await — not that the button was wrong.
  _Attachment? get _singleReady {
    for (final attachment in _attachments) {
      if (attachment.isReady) return attachment;
    }
    return null;
  }

  Future<bool> _publishPost() async {
    // Hashtags are parsed out of the text server-side and stored in their own
    // table — the publish endpoint takes no tags array.
    //
    // Only the attachments that actually uploaded are sent. One that failed is
    // still on screen with its retry, so the person has already seen it did
    // not make it; posting is not the moment to surprise them about it.
    final media = [
      for (final a in _attachments)
        if (a.storedPath != null)
          PostMedia(
            id: a.storedPath!,
            url: a.storedPath,
            kind: a.kind,
            width: a.width,
            height: a.height,
            aspectRatio: (a.width != null && a.height != null && a.height! > 0)
                ? a.width! / a.height!
                : 1,
            // Only meaningful on a document, and the server drops them on any
            // other kind — but sent from the one place that still knows them,
            // because the stored path is a uuid and the name is gone after this.
            fileName: a.fileName,
            sizeBytes: a.sizeBytes,
          ),
    ];

    final result = await ref
        .read(feedNotifierProvider.notifier)
        .publish(
          text: _controller.text,
          visibility: _visibility,
          media: media,
        );

    if (!mounted) return false;
    return result.when(
      success: (_) {
        showRungToast(context, context.l10n.toastPosted);
        return true;
      },
      failure: (e) {
        showRungToast(context, arabicMessageForException(e), success: false);
        return false;
      },
    );
  }

  /// `Stories/Publish` — one `mediaUrl`, a kind flag, an optional caption.
  ///
  /// There is no visibility and no media list: a story is a single file that
  /// expires in 24 hours, and the endpoint's shape says so.
  Future<bool> _publishStory() async {
    final media = _singleReady;
    if (media == null) {
      showRungToast(
        context,
        context.l10n.composerStoryNeedsMedia,
        success: false,
      );
      return false;
    }

    final result = await ref
        .read(storiesNotifierProvider.notifier)
        .publish(
          mediaUrl: media.storedPath!,
          isVideo: media.isVideo,
          caption: _controller.text,
        );

    if (!mounted) return false;
    return result.when(
      success: (_) {
        showRungToast(context, context.l10n.toastStoryPosted);
        return true;
      },
      failure: (e) {
        showRungToast(context, arabicMessageForException(e), success: false);
        return false;
      },
    );
  }

  /// `Reels/Publish` — a `videoUrl`, an optional caption and a length.
  ///
  /// `thumbnailUrl` is left null: generating a poster frame needs a native
  /// plugin this app does not carry, and the reel wall already falls back to
  /// the video's first frame. Sending a wrong one would be worse than none.
  Future<bool> _publishReel() async {
    final media = _singleReady;
    if (media == null || !media.isVideo) {
      showRungToast(
        context,
        context.l10n.composerReelNeedsVideo,
        success: false,
      );
      return false;
    }

    // Reading the notifier builds it, which fetches the wall if the Reels tab
    // was never opened. That is a wasted request only if the person never
    // looks — and they just published a reel, so it is a prefetch of the tab
    // they are most likely to open next.
    final result = await ref
        .read(reelsNotifierProvider.notifier)
        .publish(
          videoUrl: media.storedPath!,
          caption: _controller.text,
          durationSeconds: media.durationSeconds,
        );

    if (!mounted) return false;
    return result.when(
      success: (_) {
        showRungToast(context, context.l10n.toastReelPosted);
        return true;
      },
      failure: (e) {
        showRungToast(context, arabicMessageForException(e), success: false);
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final me = ref.watch(currentPersonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        leading: TextButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          style: TextButton.styleFrom(foregroundColor: c.ink2),
          child: Text(l10n.actionCancel),
        ),
        title: _mode.title(context),
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(
              onPressed: _canPublish ? _publish : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.composerPublish),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                RungSpace.gutter,
                14,
                RungSpace.gutter,
                14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModeSelector(
                    mode: _mode,
                    // Inert rather than merely ignored, so the segment does
                    // not look tappable while the publish it belongs to is
                    // still in flight.
                    onChanged: _publishing ? null : _setMode,
                  ),
                  const SizedBox(height: RungSpace.sm),
                  Row(
                    children: [
                      RungAvatar(
                        seed: me?.id ?? 'me',
                        initials: me?.initials ?? '—',
                        imageUrl: ref.watch(imageUrlResolverProvider)(
                          me?.avatarUrl,
                        ),
                        size: 44,
                      ),
                      const SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me?.name ?? '',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // A story and a reel have no visibility column, so
                          // the pill would be a control whose value is thrown
                          // away at publish. The mode label takes its place —
                          // the line under a name is where people look to see
                          // what they are about to make.
                          if (_mode.hasVisibility)
                            _VisibilityPill(
                              visibility: _visibility,
                              onTap: () => setState(
                                () => _visibility = _visibility.next,
                              ),
                            )
                          else
                            _ModeNote(mode: _mode),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: RungSpace.sm),
                  // Outside a post the media comes FIRST. It is the thing
                  // being published; the caption is a line under it, and a
                  // composer that puts the text box on top says the reverse.
                  if (!_mode.allowsTextOnly) ...[
                    if (_attachments.isEmpty)
                      _MediaPrompt(
                        mode: _mode,
                        onPickPhoto: _mode.kinds.contains(MediaKind.image)
                            ? _pickImages
                            : null,
                        onPickVideo: _pickVideo,
                      )
                    else
                      _AttachmentStrip(
                        mode: _mode,
                        attachments: _attachments,
                        onRemove: _remove,
                        onRetry: _retry,
                      ),
                    const SizedBox(height: RungSpace.sm),
                  ],
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    // A story and a reel are the media; the caption is a
                    // line under it. Eight rows of empty field above a clip
                    // would say the opposite.
                    autofocus: _mode == ComposerMode.post,
                    maxLines: null,
                    minLines: _mode == ComposerMode.post ? 8 : 2,
                    style: TextStyle(fontSize: 16, height: 1.55, color: c.ink),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: _mode.hint(context),
                      hintStyle: TextStyle(fontSize: 16, color: c.ink3),
                    ),
                  ),
                  if (_mode.allowsTextOnly && _attachments.isNotEmpty) ...[
                    const SizedBox(height: RungSpace.sm),
                    _AttachmentStrip(
                      mode: _mode,
                      attachments: _attachments,
                      onRemove: _remove,
                      onRetry: _retry,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Sits directly above the toolbar, so a suggestion appears between
          // the text and the keyboard where the thumb already is. Renders
          // nothing until an @token with two letters is under the caret, so it
          // costs no height on a post that mentions nobody.
          if (_mode.parsesTags)
            MentionSuggestions(
              query: MentionQuery.at(
                _controller.text,
                _controller.selection.isValid
                    ? _controller.selection.baseOffset
                    : _controller.text.length,
              ),
              onSelected: (person) {
                final query = MentionQuery.at(
                  _controller.text,
                  _controller.selection.isValid
                      ? _controller.selection.baseOffset
                      : _controller.text.length,
                );
                // Re-read rather than captured: the strip is built from an
                // earlier frame's text, and a keystroke between the build and
                // the tap would have it replace the wrong range.
                if (query != null) _applyMention(query, person.username.trim());
              },
            ),

          _AttachmentBar(
            mode: _mode,
            onPickImages: _pickImages,
            onPickDocuments: _pickDocuments,
            onPickVideo: _pickVideo,
            onAddHashtag: _insertHashtag,
            onAddMention: _insertMention,
            canAttach:
                _maxAttachments == 1 ||
                _attachments.length < _maxAttachments,
          ),
        ],
      ),
    );
  }
}

/// Stands in for the media a story or a reel does not have yet.
///
/// The toolbar below already carries the same buttons, but an empty composer
/// with nothing in the middle of it reads as a screen that failed to load —
/// and the one thing this mode needs is the one thing it is not showing.
class _MediaPrompt extends StatelessWidget {
  const _MediaPrompt({
    required this.mode,
    required this.onPickPhoto,
    required this.onPickVideo,
  });

  final ComposerMode mode;

  /// Null in a mode that takes no photo — a reel, where the only answer is a
  /// video.
  final VoidCallback? onPickPhoto;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final photo = onPickPhoto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: RungRadius.mdAll,
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Icon(mode.icon, size: 30, color: c.ink3),
          const SizedBox(height: 10),
          Text(
            mode == ComposerMode.reel
                ? l10n.composerReelNeedsVideo
                : l10n.composerStoryNeedsMedia,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.ink2,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (photo != null)
                OutlinedButton.icon(
                  onPressed: photo,
                  icon: const Icon(Icons.image_outlined, size: 17),
                  label: Text(l10n.composerAddPhoto),
                ),
              FilledButton.icon(
                onPressed: onPickVideo,
                icon: const Icon(Icons.videocam_outlined, size: 17),
                label: Text(l10n.composerAddVideo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The three-way منشور / قصة / ريل switch at the top of the composer.
///
/// A segmented control rather than a dropdown or a sheet: all three options
/// are visible at once, which is what makes "you can also post a story from
/// here" discoverable to somebody who came looking for a post.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final ComposerMode mode;

  /// Null while a publish is in flight — see [_ComposerScreenState._setMode].
  final ValueChanged<ComposerMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: RungRadius.pill,
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final option in ComposerMode.values)
            Expanded(
              child: _ModeSegment(
                mode: option,
                selected: option == mode,
                onTap: onChanged == null ? null : () => onChanged!(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ComposerMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    // White on the accent, never `accentInk` — that token is the accent AS
    // ink, for light grounds. On the filled segment it reads as navy on blue.
    final foreground = selected ? Colors.white : c.ink2;

    return InkWell(
      onTap: onTap,
      borderRadius: RungRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? c.accent : Colors.transparent,
          borderRadius: RungRadius.pill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(mode.icon, size: 15, color: foreground),
            const SizedBox(width: 6),
            // Each segment is a third of the gutter-inset width — about 94px
            // on a 320dp phone. Flexible is what turns a long label at a large
            // text scale into an ellipsis rather than an overflow stripe.
            Flexible(
              child: Text(
                mode.label(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands where the visibility pill stands on a post, saying what this is
/// instead of who can see it.
class _ModeNote extends StatelessWidget {
  const _ModeNote({required this.mode});

  final ComposerMode mode;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(mode.icon, size: 13, color: c.ink3),
        const SizedBox(width: 5),
        Text(
          mode.label(context),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: c.ink3,
          ),
        ),
      ],
    );
  }
}

/// Thumbnails of what is attached, read from the device rather than the CDN.
///
/// The local file is already on disk and renders instantly; the uploaded copy
/// would mean waiting for a round-trip to show something the person is
/// looking at right now.
class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({
    required this.mode,
    required this.attachments,
    required this.onRemove,
    required this.onRetry,
  });

  final ComposerMode mode;
  final List<_Attachment> attachments;
  final void Function(_Attachment) onRemove;
  final void Function(_Attachment) onRetry;

  @override
  Widget build(BuildContext context) {
    // A story and a reel ARE their media — one file, shown at a size somebody
    // can actually judge before publishing it. A 104px thumbnail is the right
    // shape for one of four photos on a post and the wrong one for the whole
    // of what is being published.
    if (mode != ComposerMode.post) {
      final only = attachments.first;
      return _AttachmentHero(
        attachment: only,
        onRemove: () => onRemove(only),
        onRetry: () => onRetry(only),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _AttachmentTile(
          attachment: attachments[i],
          onRemove: () => onRemove(attachments[i]),
          onRetry: () => onRetry(attachments[i]),
        ),
      ),
    );
  }
}

/// The single photo or clip a story or a reel is made of, shown large.
class _AttachmentHero extends StatelessWidget {
  const _AttachmentHero({
    required this.attachment,
    required this.onRemove,
    required this.onRetry,
  });

  final _Attachment attachment;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final preview = attachment.preview;

    // The clip's own shape once the player knows it, so a portrait phone video
    // is not letterboxed into a landscape box. 9:16 until then — the shape a
    // story is far more often than not, and the one that does not jump when
    // the real value arrives.
    final ratio = (preview != null && preview.value.isInitialized)
        ? preview.value.aspectRatio
        : 9 / 16;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320, maxWidth: 260),
        child: AspectRatio(
          aspectRatio: ratio <= 0 ? 9 / 16 : ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: RungRadius.mdAll,
                child: ColoredBox(
                  color: c.surface2,
                  child: attachment.isVideo
                      ? _VideoPreview(attachment: attachment)
                      : Image.file(
                          File(attachment.localPath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: c.line),
                        ),
                ),
              ),
              _MediaVeil(attachment: attachment, onRetry: onRetry),
              _RemoveBadge(onTap: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picked clip, playing muted on a loop.
///
/// Falls back to a still placeholder while the controller is initialising or
/// after it failed — [_ComposerScreenState._preparePreview] leaves `preview`
/// null in that case, and a clip with no preview still uploads and publishes.
class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.attachment});

  final _Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final controller = attachment.preview;

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Icon(Icons.movie_creation_outlined, size: 30, color: c.ink3),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// One veil for both waiting states, so a slow upload and a failed one read as
/// the same kind of thing — something is not finished here.
class _MediaVeil extends StatelessWidget {
  const _MediaVeil({required this.attachment, required this.onRetry});

  final _Attachment attachment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = attachment.error != null;
    if (!attachment.uploading && !failed) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: RungRadius.mdAll,
      child: ColoredBox(
        color: const Color(0x990A0E16),
        child: Center(
          child: attachment.uploading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    // Determinate as soon as the transfer reports a total. A
                    // clip takes minutes, and minutes of an indeterminate
                    // spinner is indistinguishable from a frozen screen.
                    value: attachment.progress,
                  ),
                )
              : IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  color: Colors.white,
                  tooltip: context.l10n.composerPhotoRetry,
                ),
        ),
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 4,
      end: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xCC0A0E16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onRemove,
    required this.onRetry,
  });

  final _Attachment attachment;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A document has nothing to preview, so the tile IS its label: an
          // icon and the name, which is the only thing that tells two
          // attachments apart once they are both on the CDN under a uuid.
          if (attachment.isDocument)
            Container(
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: RungRadius.mdAll,
                border: Border.all(color: c.line),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 26,
                    color: c.accent,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    attachment.fileName ?? '',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: c.ink2,
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: RungRadius.mdAll,
              child: Image.file(
                File(attachment.localPath),
                fit: BoxFit.cover,
                // A picked file can disappear between pick and paint (a photo
                // deleted from another app, a provider handing back a temp file
                // the OS has since reaped).
                errorBuilder: (_, __, ___) => ColoredBox(color: c.line),
              ),
            ),

          _MediaVeil(attachment: attachment, onRetry: onRetry),
          _RemoveBadge(onTap: onRemove),
        ],
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.visibility, required this.onTap});

  final PostVisibility visibility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return InkWell(
      onTap: onTap,
      borderRadius: RungRadius.pill,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: RungRadius.pill,
          border: Border.all(color: c.line2, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 13, color: c.ink2),
            const SizedBox(width: 5),
            Text(
              visibility.audienceLabel(context),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: c.ink2,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 14, color: c.ink2),
          ],
        ),
      ),
    );
  }
}

/// Media / document / video / hashtag / poll affordances.
///
/// Which of them appear is the mode's decision, not this widget's: a reel
/// takes a video and nothing else, and a photo button that refuses every photo
/// is worse than no photo button.
class _AttachmentBar extends StatelessWidget {
  const _AttachmentBar({
    required this.mode,
    required this.onPickImages,
    required this.onPickDocuments,
    required this.onPickVideo,
    required this.onAddHashtag,
    required this.onAddMention,
    required this.canAttach,
  });

  final ComposerMode mode;
  final VoidCallback onPickImages;
  final VoidCallback onPickDocuments;
  final VoidCallback onPickVideo;
  final VoidCallback onAddHashtag;

  /// Inserts an `@`, which is also what opens the suggestion strip — the two
  /// are one gesture, so there is no separate "pick someone" screen to learn.
  final VoidCallback onAddMention;

  /// False when the attachment limit is already reached — and only then.
  ///
  /// A missing storage zone is NOT gated here: the picker says so out loud
  /// when it is tapped, because a control that greys out with no explanation
  /// is indistinguishable from a broken app.
  ///
  /// One flag for photos and documents, because they share the list and the
  /// limit — two caps would let somebody attach twice as much by alternating
  /// between the buttons. Always true in a single-media mode, where a second
  /// pick replaces rather than being refused.
  final bool canAttach;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: RungSpace.sm,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            if (mode.kinds.contains(MediaKind.image))
              IconButton(
                onPressed: canAttach ? onPickImages : null,
                icon: const Icon(Icons.image_outlined),
                color: c.green,
                disabledColor: c.ink3,
                tooltip: l10n.composerAddPhoto,
              ),
            // A clip REPLACES whatever is there, so unlike the others it is
            // never disabled by the cap: a story or a reel holds exactly one
            // and the button's job is to change it.
            if (mode.kinds.contains(MediaKind.video))
              IconButton(
                onPressed: onPickVideo,
                icon: const Icon(Icons.videocam_outlined),
                color: c.accent,
                disabledColor: c.ink3,
                tooltip: l10n.composerAddVideo,
              ),
            if (mode.kinds.contains(MediaKind.document))
              IconButton(
                onPressed: canAttach ? onPickDocuments : null,
                icon: const Icon(Icons.description_outlined),
                color: c.accent,
                disabledColor: c.ink3,
                tooltip: l10n.composerAddDocument,
              ),
            // Not gated on the storage zone: a hashtag is text, and the one
            // thing this button does is put a '#' where the cursor is. Absent
            // outside a post, where nothing parses it back out.
            if (mode.parsesTags) ...[
              IconButton(
                onPressed: onAddHashtag,
                icon: const Icon(Icons.tag),
                color: c.amber,
                tooltip: l10n.composerAddHashtag,
              ),
              IconButton(
                onPressed: () => showRungToast(context, l10n.comingSoon),
                icon: const Icon(Icons.poll_outlined),
                color: c.ink2,
                tooltip: l10n.comingSoon,
              ),
            ],
            const Spacer(),
            if (mode.parsesTags)
              IconButton(
                onPressed: onAddMention,
                icon: const Icon(Icons.alternate_email),
                color: c.accent,
                tooltip: l10n.composerAddMention,
              ),
          ],
        ),
      ),
    );
  }
}
