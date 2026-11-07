import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/services/stream_library.dart';
import 'package:mohandis/core/services/stream_upload_service.dart';
import 'package:mohandis/core/services/video_upload_queue.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import 'package:mohandis/features/panel/data/repositories/panel_repository_impl.dart';
import 'package:mohandis/features/panel/domain/repositories/panel_repository.dart';
import '../../domain/entities/panel_entities.dart';
import '../notifiers/course_market_notifiers.dart';
import '../notifiers/panel_notifiers.dart';
import '../widgets/course_bits.dart';

/// The lessons of one course — its own screen, reached after the course itself
/// has been saved.
///
/// **Why this is not a section of the editor any more.** A lesson needs a
/// course id to hang off, so the editor used to carry a lessons section that
/// quietly saved the draft the first time somebody pressed "add". That hid a
/// real ordering — course first, lessons second — inside a side effect, and it
/// put the longest upload in the app behind a form the author still had
/// unsaved changes in. Splitting it makes the order the navigation: save the
/// course, land here, add lessons against an id that certainly exists.
///
/// Reads the course through `myCourseProvider` rather than taking it as an
/// argument. It has to be watched anyway — a lesson added here changes the
/// course's own lesson count — and reading it here means arriving by deep link
/// works exactly like arriving from the editor.
class CourseLessonsScreen extends ConsumerWidget {
  const CourseLessonsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final course = ref.watch(myCourseProvider(courseId));

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(title: l10n.courseLessonsTitle, showBack: true),
      body: course.when(
        loading: () => const LessonListSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RungSpace.gutter),
            child: Text(
              arabicMessageForException(e),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink3),
            ),
          ),
        ),
        data: (saved) => _Body(course: saved),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    // Same rule as the editor's: the server refuses writes on a course that is
    // with the reviewer or already approved, so the Add button goes rather than
    // failing when pressed.
    final enabled = course.commerce.isEditable;
    final lessons = ref.watch(courseLecturesProvider(course.id));

    // The running transfer, if there is one. Matched to a row by its tag, which
    // is the lesson id the pending save produced — see `VideoUploadJob.tag`.
    final job = ref.watch(videoUploadQueueProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        RungSpace.xl,
      ),
      children: [
        // The course's own title, so somebody who arrived by deep link knows
        // which course these lessons belong to.
        Text(
          course.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.courseLessons,
          style: TextStyle(fontSize: 12.5, color: c.ink3),
        ),
        const SizedBox(height: RungSpace.md),

        lessons.when(
          loading: () => const LessonListSkeleton(),
          error: (e, _) => Text(
            arabicMessageForException(e),
            style: TextStyle(fontSize: 12.5, color: c.ink3),
          ),
          data: (rows) => Column(
            children: [
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: RungSpace.md,
                  ),
                  child: Text(
                    l10n.courseLessonsEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: c.ink3),
                  ),
                ),
              for (final lesson in rows)
                _LessonRow(
                  lesson: lesson,
                  enabled: enabled,
                  job: job?.tag == lesson.id ? job : null,
                  onTap: () => _open(context, lesson),
                ),
            ],
          ),
        ),

        if (enabled) ...[
          const SizedBox(height: RungSpace.md),
          FilledButton.icon(
            onPressed: () => _open(context, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.courseAddLesson),
          ),
        ],
      ],
    );
  }

  Future<void> _open(BuildContext context, Lecture? lesson) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LessonSheet(courseId: course.id, lesson: lesson),
      );
}

/// One lesson in the author's list, including one whose file is still moving.
///
/// **A lesson being uploaded is a row, not an absence.** The row is written to
/// the database before the transfer starts precisely so that there is something
/// here to draw — so this is where that state is explained: what is happening,
/// how far along it is, and, when an attempt stopped, that the lesson is real
/// and only its file is missing.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.enabled,
    required this.job,
    required this.onTap,
  });

  final Lecture lesson;
  final bool enabled;

  /// The running transfer, but ONLY when it is this lesson's. Null otherwise,
  /// including while some other lesson or a reel is uploading.
  final VideoUploadJob? job;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final live = job != null && job!.isActive;
    final uploading = live && job!.stage == VideoUploadStage.uploading;

    // Not while the bytes are moving. Opening the sheet would offer a Save that
    // the single-slot queue refuses, and re-picking the file now would leave
    // the first transfer running against a lesson nobody is waiting for.
    final tappable = enabled && !live;

    final String subtitle;
    if (uploading) {
      subtitle = l10n.courseUploading(
        ArabicNumbers.plain((job!.progress * 100).round()),
      );
    } else if (live) {
      // Transferred; the write that fills in the URL is in flight.
      subtitle = l10n.uploadBannerFinishing;
    } else if (lesson.uploadPending) {
      // Saved ahead of its file and still without one: an attempt failed or
      // was cancelled, unless the row already has an older file to fall back
      // on — which is an edit whose replacement never arrived.
      subtitle = (lesson.contentUrl ?? '').isEmpty
          ? l10n.courseLessonUploadIncomplete
          : l10n.courseLessonUploadQueued;
    } else {
      subtitle = '${lesson.kind.label(context)} · '
          '${ArabicNumbers.plain(lesson.durationMinutes)}';
    }

    return RungCard(
      onTap: tappable ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                ArabicNumbers.plain(lesson.position),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: lesson.uploadPending && !live ? c.red : c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              if (live)
                RungTagChip(
                  label: l10n.courseLessonUploadingChip,
                  emphasis: RungTagEmphasis.accent,
                )
              else if (lesson.isPreview)
                RungTagChip(
                  label: l10n.courseLessonPreview,
                  emphasis: RungTagEmphasis.accent,
                ),
            ],
          ),
          // Determinate while bytes move, indeterminate once they have — the
          // write that follows has no measurable length, and a bar frozen at
          // the end reads as a hang.
          if (live) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: uploading ? job!.progress : null,
              minHeight: 2,
              backgroundColor: c.line,
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonSheet extends ConsumerStatefulWidget {
  const _LessonSheet({required this.courseId, this.lesson});

  final String courseId;
  final Lecture? lesson;

  @override
  ConsumerState<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends ConsumerState<_LessonSheet> {
  late final _title = TextEditingController(text: widget.lesson?.title ?? '');
  /// The lesson's host-less CDN path, or null until something is uploaded.
  /// State, not a controller — nobody types a storage path by hand.
  late String? _url = widget.lesson?.contentUrl;

  bool _uploading = false;
  double _progress = 0;
  late final _body = TextEditingController(
    text: widget.lesson?.articleBody ?? '',
  );
  /// Set when a video has been picked. Save writes the lesson row against it
  /// and hands the transfer — already running, see [_beginUpload] — to the
  /// background queue instead of writing the lesson itself.
  String? _pendingVideoPath;

  /// The queue, held rather than read on demand: [dispose] has to be able to
  /// abandon an unclaimed transfer, and by then `ref` is no longer usable.
  VideoUploadQueue? _queue;

  /// Whether this sheet started a transfer that nobody has claimed. Cleared
  /// when Save commits it, because from then on it belongs to the queue.
  bool _eager = false;

  late final _minutes = TextEditingController(
    text: widget.lesson == null
        ? ''
        : widget.lesson!.durationMinutes.toString(),
  );

  late LessonKind _kind = widget.lesson?.kind ?? LessonKind.video;
  late bool _preview = widget.lesson?.isPreview ?? false;
  bool _busy = false;

  /// Why the last attempt to save failed, shown INSIDE the sheet.
  ///
  /// **A toast cannot report this.** `showRungToast` goes to the
  /// `ScaffoldMessenger`, which belongs to the screen underneath — so while a
  /// modal sheet is open the SnackBar is drawn behind its barrier and the
  /// person sees nothing at all. Pressing Save and having the sheet sit there
  /// unchanged is indistinguishable from a dead button, and the explanation
  /// only appears once they give up and drag the sheet away.
  String? _error;

  /// The server's own words, untranslated, in a debug build only. The line
  /// above collapses anything it has no rule for into "something went wrong",
  /// which is right for the person using the app and useless for fixing it.
  String? _errorDetail;

  @override
  void dispose() {
    for (final c in [_title, _body, _minutes]) {
      c.dispose();
    }
    // Picked a video, started sending it, then closed the sheet without
    // saving. The bytes are stopped and the video taken back off Bunny.
    if (_eager) _queue?.abandon();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() write,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
      _errorDetail = null;
    });
    await write();
    if (mounted) setState(() => _busy = false);
  }

  /// Reports a failure where the person is actually looking.
  ///
  /// [override] replaces the translated line when this screen understands the
  /// refusal better than the generic mapping does. The raw message is kept
  /// either way, so a debug build still shows what the server actually said.
  void _fail(AppException e, {String? override}) {
    if (!mounted) return;
    setState(() {
      _error = override ?? arabicMessageForException(e);
      _errorDetail = e.message;
    });
  }

  /// Picks the lesson's file and uploads it.
  ///
  /// The picker follows the KIND: a video lesson opens the gallery's video
  /// picker, a PDF lesson the file browser restricted to PDFs. One combined
  /// "any file" picker would let somebody attach a spreadsheet to a lesson the
  /// player will try to play.
  Future<void> _pickFile() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      setState(() => _error = context.l10n.composerUploadsOff);
      return;
    }

    // A lesson VIDEO goes to Bunny Stream, exactly as a reel does. The storage
    // zone would take it and hand it back byte for byte, which is the problem:
    // it transcodes nothing, so a half-hour lecture is served as a single
    // original file with no HLS ladder — the viewer downloads at whatever
    // bitrate it was recorded at or stalls. Stream makes the ladder and the
    // poster on ingest.
    //
    // A PDF still goes to storage. There is nothing to transcode, and Stream
    // only takes video.
    final isVideo = _kind == LessonKind.video;
    if (isVideo) {
      // AWAITED, not read. `streamUploadServiceProvider` is derived from
      // `streamLibraryProvider.valueOrNull`, which is null for as long as that
      // one-shot fetch is in flight — so a synchronous read refuses a video on
      // the first attempt of a session and accepts it on the second, which is
      // indistinguishable from a flaky server.
      try {
        await ref.read(streamLibraryProvider.future);
      } catch (_) {
        // The null check below says the same thing in the same words.
      }
      if (!mounted) return;

      if (ref.read(streamUploadServiceProvider) == null) {
        setState(() => _error = context.l10n.courseLessonStreamOff);
        return;
      }
    }

    String? localPath;
    try {
      if (_kind == LessonKind.video) {
        final picked = await ImagePicker().pickVideo(
          source: ImageSource.gallery,
        );
        localPath = picked?.path;
      } else {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        localPath = picked?.files.single.path;
      }
    } catch (e) {
      if (mounted) setState(() => _error = arabicMessageForException(e));
      return;
    }

    if (localPath == null || !mounted) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    void report(int sent, int total) {
      if (!mounted || total <= 0) return;
      setState(() => _progress = (sent / total).clamp(0, 1).toDouble());
    }

    // **A VIDEO starts moving NOW, and the lesson is written after.**
    //
    // A lecture is the longest upload in the app — the author then spends a
    // while on the title, the length and the preview toggle, which is time the
    // uplink would otherwise spend idle. Starting at the pick spends it on the
    // file instead, so Save usually finds the transfer already finished.
    //
    // Nothing is written until Save commits it. Close the sheet without
    // saving and `dispose` abandons the transfer, which deletes the video.
    if (isVideo) {
      setState(() {
        _uploading = false;
        _pendingVideoPath = localPath;
        // Stands in until the real URL arrives, so the picker shows the file
        // as chosen and Save is enabled.
        _url = localPath;
      });
      _beginUpload(localPath);
      return;
    }

    final result = await uploader.uploadDocument(
      localPath,
      folder: 'courses/lessons',
      onProgress: report,
    );

    if (!mounted) return;
    setState(() => _uploading = false);
    result.when(
      success: (path) => setState(() => _url = path),
      failure: _fail,
    );
  }

  /// Starts the lecture's transfer at pick time. See the comment at the call
  /// site; the library has already been awaited by then.
  void _beginUpload(String localPath) {
    final queue = ref.read(videoUploadQueueProvider.notifier);
    _queue = queue;

    // The previous pick's transfer, if the author changed their mind about
    // which file this lesson holds.
    if (_eager) {
      _eager = false;
      queue.abandon();
    }

    // Another job holds the queue. Not an error here: Save asks again, and
    // falls back to starting the transfer itself.
    if (queue.isBusy || queue.hasParked) return;

    final begun = queue.begin(
      localPath: localPath,
      // Renamed to the lesson's title at commit. There may not be one yet.
      label: _title.text.trim().isEmpty ? 'lesson' : _title.text.trim(),
    );
    if (begun) _eager = true;
  }

  /// Writes the lesson with whatever [contentUrl] it should carry.
  ///
  /// Shared by the two paths: the immediate save, and the one the background
  /// queue runs once a video has landed. One function because the second must
  /// write exactly what the first would, and a copy would drift the moment a
  /// field was added to the form.
  Future<Result<SavedLesson, AppException>> _writeLesson({
    /// The repository to write through, read by whoever is calling.
    ///
    /// A repository rather than a ref or the `myCourses` notifier, because the
    /// two callers hold different things. The immediate save has a `WidgetRef`;
    /// the background one has the queue's `Ref` — different types with no
    /// common supertype. And `myCoursesProvider` is autoDispose, so reading its
    /// notifier from the queue, where nothing is listening, hands back an
    /// object that may be disposed before the write lands. The repository is a
    /// plain provider and has neither problem.
    required PanelRepository repo,
    required String? contentUrl,
    required String title,
    required LessonKind kind,
    required String? body,
    required int minutes,
    required bool preview,

    /// Which lesson to write. Defaults to the one this sheet opened on; the
    /// post-upload write passes the id the pending save produced, which for a
    /// NEW lesson the sheet never had.
    String? lessonId,

    /// Save the row without its file. See `PanelRepository.saveLesson`.
    bool uploadPending = false,
  }) {
    return repo.saveLesson(
      courseId: widget.courseId,
      lessonId: lessonId ?? widget.lesson?.id,
      title: title,
      kind: kind,
      contentUrl: contentUrl,
      articleBody: body,
      durationMinutes: minutes,
      isPreview: preview,
      position: widget.lesson?.position ?? 0,
      uploadPending: uploadPending,
    );
  }

  Future<void> _save() => _run(() async {
    // Snapshotted before anything async: the sheet is about to close, and the
    // callback that writes the lesson must not read controllers that have been
    // disposed by then.
    final title = _title.text;
    final kind = _kind;
    final body = _body.text.trim().isEmpty ? null : _body.text;
    final minutes = int.tryParse(_minutes.text.trim()) ?? 0;
    final preview = _preview;
    final pendingVideo = _pendingVideoPath;
    final courseId = widget.courseId;

    if (pendingVideo != null) {
      // **The row is written BEFORE the bytes move.**
      //
      // A lecture video is a minute of uplink. Writing the lesson afterwards
      // meant that for that whole minute the author's own list showed nothing
      // — they had added a lesson and could not see it — and anything that
      // ended the process in between lost the lesson along with the transfer.
      // So the lesson is saved first, marked `uploadPending`, which is the one
      // case the server lets a video lesson exist with no file. The list draws
      // it as uploading, and the write that follows the transfer fills in the
      // URL and clears the flag.
      //
      // `contentUrl` keeps whatever was already stored rather than being
      // nulled: on an EDIT that replaces the video, the old one goes on
      // playing until the new one lands. For a new lesson there is nothing to
      // keep and the row is simply fileless until then.
      final pendingSave = await _writeLesson(
        repo: ref.read(panelRepositoryProvider),
        contentUrl: widget.lesson?.contentUrl,
        title: title,
        kind: kind,
        body: body,
        minutes: minutes,
        preview: preview,
        uploadPending: true,
      );

      if (!mounted) return;

      final placed = pendingSave.valueOrNull;
      if (placed == null) {
        final e = pendingSave.errorOrNull!;
        // "This lesson needs its file uploaded first" — in answer to a write
        // that explicitly asked the server to keep a place for the file. A
        // server that understands `uploadPending` cannot answer that, so the
        // one it is running predates the field, and no amount of retrying
        // from here will change its mind.
        final outdated = e.message.toLowerCase().contains(
          'needs its file uploaded',
        );
        _fail(
          e,
          override: outdated ? context.l10n.courseLessonServerOutdated : null,
        );
        return;
      }

      final lessonId = placed.lessonId;
      ref.invalidate(courseLecturesProvider(courseId));

      final label = title.trim().isEmpty ? 'lesson' : title.trim();

      Future<Result<void, AppException>> write(
        Ref queueRef,
        StreamUploadResult uploaded,
      ) async {
        final written = await _writeLesson(
          repo: queueRef.read(panelRepositoryProvider),
          contentUrl: uploaded.videoPath,
          title: title,
          kind: kind,
          body: body,
          minutes: minutes,
          preview: preview,
          // The row the pending save created — NOT `widget.lesson`, which is
          // null for a lesson added this way.
          lessonId: lessonId,
        );
        // The lists behind the closed sheet are stale until this lands. Done
        // here rather than by `MyCoursesNotifier.run`, which this path
        // deliberately bypasses — see `_writeLesson`.
        queueRef.invalidate(courseLecturesProvider(courseId));
        queueRef.invalidate(myCoursesProvider);
        return written.map<void>((_) {});
      }

      final queue = ref.read(videoUploadQueueProvider.notifier);

      // Claim the transfer that started when the file was picked. Tagged with
      // the lesson now that there is one, so the list can put the live
      // percentage on that row rather than on every pending one.
      if (_eager) {
        final claimed = queue.commit(
          label: label,
          tag: lessonId,
          onUploaded: write,
        );
        if (claimed) {
          _eager = false;
          showRungToast(context, context.l10n.uploadStartedBackground);
          Navigator.of(context).pop();
          return;
        }
        // Failed or was cancelled while the form was being filled in. Start
        // over rather than reporting a transfer the author never saw.
        _eager = false;
        queue.clear();
      }

      final started = queue.start(
        localPath: pendingVideo,
        label: label,
        tag: lessonId,
        onUploaded: write,
      );

      if (!mounted) return;
      if (!started) {
        // The lesson is saved and pending; only the transfer was refused. Said
        // in the sheet, because the row they are about to see in the list is
        // real and they need to know why it has no file yet.
        setState(() => _error = context.l10n.uploadBannerBusy);
        return;
      }
      showRungToast(context, context.l10n.uploadStartedBackground);
      Navigator.of(context).pop();
      return;
    }

    final result = await _writeLesson(
      repo: ref.read(panelRepositoryProvider),
      contentUrl: _url,
      title: title,
      kind: kind,
      body: body,
      minutes: minutes,
      preview: preview,
    );

    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(courseLecturesProvider(widget.courseId));
        Navigator.of(context).pop();
      },
      failure: _fail,
    );
  });

  Future<void> _delete() => _run(() async {
    final lesson = widget.lesson;
    if (lesson == null) return;

    final result = await ref
        .read(myCoursesProvider.notifier)
        .run(
          (repo) => repo.deleteLesson(
            courseId: widget.courseId,
            lessonId: lesson.id,
          ),
        );

    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(courseLecturesProvider(widget.courseId));
        Navigator.of(context).pop();
      },
      failure: _fail,
    );
  });

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RungRadius.lg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RungSpace.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RungField(
                  label: l10n.courseLessonTitle,
                  controller: _title,
                  enabled: !_busy,
                ),
                const SizedBox(height: RungSpace.sm),
                RungSelectField<LessonKind>(
                  label: l10n.courseLessonKind,
                  value: _kind,
                  values: LessonKind.values,
                  enabled: !_busy,
                  labelOf: (v) => v.label(context),
                  iconOf: (v) => v.icon,
                  onChanged: (v) => setState(() => _kind = v),
                ),
                const SizedBox(height: RungSpace.sm),

                // One field or the other, never both: the server stores the
                // file on a video or a PDF and the text on an article, and
                // nulls whichever does not belong to the kind.
                if (_kind == LessonKind.article)
                  RungField(
                    label: l10n.courseLessonBody,
                    controller: _body,
                    enabled: !_busy,
                    maxLines: 8,
                  )
                else
                  _LessonFilePicker(
                    kind: _kind,
                    path: _url,
                    uploading: _uploading,
                    progress: _progress,
                    enabled: !_busy,
                    onPick: _pickFile,
                  ),

                const SizedBox(height: RungSpace.sm),
                RungField(
                  label: l10n.courseLessonDuration,
                  controller: _minutes,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: RungSpace.sm),
                RungToggleTile(
                  title: l10n.courseLessonPreview,
                  subtitle: l10n.courseFieldPriceHint,
                  value: _preview,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _preview = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: RungSpace.md),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.red.withValues(alpha: 0.08),
                      borderRadius: RungRadius.mdAll,
                      border: Border.all(color: c.red.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 18, color: c.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: c.red,
                                ),
                              ),
                              // Debug only: the untranslated message, so the
                              // line above collapsing into "something went
                              // wrong" does not hide what the server said.
                              if (kDebugMode && _errorDetail != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _errorDetail!,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: c.ink3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: RungSpace.md),
                FilledButton(
                  // Also blocked while the file is still moving: saving now
                  // would send a null path and be refused by the server for a
                  // file the author is watching upload.
                  onPressed: _busy || _uploading ? null : _save,
                  child: Text(l10n.actionSave),
                ),
                if (widget.lesson != null) ...[
                  const SizedBox(height: RungSpace.xs),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: Text(
                      l10n.courseLessonDelete,
                      style: TextStyle(color: c.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// The lesson's own file: a video or a PDF, uploaded before the lesson saves.
///
/// Shows WHETHER a file is attached rather than its path. The path is a
/// host-less storage key — it means nothing to the author, and showing it
/// invites editing it into something that does not resolve.
class _LessonFilePicker extends StatelessWidget {
  const _LessonFilePicker({
    required this.kind,
    required this.path,
    required this.uploading,
    required this.progress,
    required this.enabled,
    required this.onPick,
  });

  final LessonKind kind;
  final String? path;
  final bool uploading;
  final double progress;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final has = path != null && path!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.courseLessonFile,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled && !uploading ? onPick : null,
          borderRadius: RungRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled ? c.surface : c.surface2,
              borderRadius: RungRadius.mdAll,
              border: Border.all(color: has ? c.green : c.line),
            ),
            child: Row(
              children: [
                Icon(
                  uploading
                      ? Icons.cloud_upload_outlined
                      : has
                          ? Icons.check_circle_outline_rounded
                          : kind.icon,
                  size: 20,
                  color: has && !uploading ? c.green : c.ink3,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uploading
                        ? l10n.courseUploading(
                            ArabicNumbers.plain((progress * 100).round()),
                          )
                        : has
                            ? l10n.courseLessonFileReady
                            : kind == LessonKind.video
                                ? l10n.courseLessonPickVideo
                                : l10n.courseLessonPickPdf,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: has && !uploading ? c.green : c.ink2,
                    ),
                  ),
                ),
                if (!uploading)
                  Icon(
                    has ? Icons.refresh_rounded : Icons.upload_rounded,
                    size: 18,
                    color: c.ink3,
                  ),
              ],
            ),
          ),
        ),
        if (uploading) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress == 0 ? null : progress,
            minHeight: 3,
            backgroundColor: c.surface2,
          ),
        ] else if (!has) ...[
          const SizedBox(height: 4),
          Text(
            l10n.courseLessonFileMissing,
            style: TextStyle(fontSize: 11.5, color: c.ink3),
          ),
        ],
      ],
    );
  }
}
