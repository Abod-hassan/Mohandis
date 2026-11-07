import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/result.dart';
import 'stream_library.dart';
import 'stream_upload_service.dart';

/// Where a job has got to.
enum VideoUploadStage {
  /// Bytes on the wire. [VideoUploadJob.progress] is meaningful here.
  uploading,

  /// Transferred, and waiting for somebody to say what it was for.
  ///
  /// Only reachable on the eager path: the transfer is started when the video
  /// is PICKED, which is minutes before the person finishes writing a caption
  /// or a lesson title. A clip that lands first parks here until [commit].
  ready,

  /// Transferred; running whatever the caller wanted done with the URL —
  /// publishing the reel, saving the lesson. Short, and not measurable.
  finishing,

  done,
  failed,

  /// Stopped on purpose. Distinct from [failed] because the banner must not
  /// cry wolf: a cancellation is the person getting what they asked for, and
  /// showing it in red next to "upload failed" trains them to ignore the one
  /// that matters.
  cancelled,
}

/// One video on its way to Bunny, and what to do when it lands.
class VideoUploadJob {
  const VideoUploadJob({
    required this.label,
    required this.stage,
    this.tag,
    this.claimed = true,
    this.progress = 0,
    this.error,
    this.debugDetail,
  });

  /// Shown on the banner — the reel's caption, the lesson's title. Something
  /// the person will recognise as theirs, because by the time they see this
  /// they have left the screen they started it from.
  final String label;

  final VideoUploadStage stage;

  /// What this upload belongs to, in the caller's own terms — a lesson id for a
  /// course lecture, null for a reel.
  ///
  /// **Why the queue carries somebody else's id.** The row for a pending lesson
  /// is written before the transfer starts, so the lessons list has a lesson to
  /// draw while the bytes are moving; to draw it as *uploading, 40%* that list
  /// has to know which of its rows this job is for. The alternative is matching
  /// on the label, which is the lesson's title and is not unique.
  final String? tag;

  /// Whether anybody has said yet what this transfer is for.
  ///
  /// False only on the eager path, between the pick and the Publish. An
  /// unclaimed job is the composer's private business: it is not announced on
  /// the shell banner, and leaving the app with one running needs no warning,
  /// because the screen that owns it abandons it on the way out.
  final bool claimed;

  /// 0‥1 while [VideoUploadStage.uploading]. Not a guess: Bunny's PUT reports
  /// bytes sent, so this is the real figure rather than a crawling fake.
  final double progress;

  final AppException? error;

  /// What actually went wrong, in the terms the API used — the stage, the
  /// status code, and Bunny's own message.
  ///
  /// Separate from [error] because the two have different jobs. `error` is
  /// translated for the person using the app and collapses everything it has
  /// no rule for into "something went wrong", which is right for them and
  /// useless for fixing it. This is the other half, shown only in a debug
  /// build.
  final String? debugDetail;

  bool get isActive =>
      stage == VideoUploadStage.uploading || stage == VideoUploadStage.finishing;

  /// Transferred but not yet spoken for — see [VideoUploadStage.ready].
  bool get isParked => stage == VideoUploadStage.ready;

  /// Whether pressing Cancel can still do anything.
  ///
  /// Only the transfer is cancellable. Once the stage is
  /// [VideoUploadStage.finishing] the bytes are on Bunny and the caller's own
  /// write is in flight — stopping there would leave a reel row half-made or a
  /// video stored with nothing pointing at it, so the button goes away instead
  /// of offering something it cannot honour.
  bool get canCancel => stage == VideoUploadStage.uploading;
}

/// Carries a video upload across navigation.
///
/// **Why this exists above the screens.** The composer used to own the
/// transfer, which meant the publish button stayed disabled until it finished
/// and the only way to wait was to sit on the composer. A phone video is tens
/// of megabytes on a mobile uplink; that is a minute of staring at a progress
/// ring with the rest of the app unreachable behind it.
///
/// The job therefore outlives the screen that started it: the composer hands
/// over and pops, and the work continues against this provider, which nothing
/// in the widget tree owns.
///
/// **One at a time, deliberately.** Two concurrent video uploads on a phone
/// uplink finish later than the same two in sequence, and both of them show a
/// progress bar that stalls. A second request while one is running is refused
/// and says so, which is a worse feature and an honest one.
///
/// **It does NOT survive the process.** A Dart isolate dies with the app, so
/// a job cannot be resumed on next launch without first copying the video into
/// app storage and adding a platform-side uploader. The shell asks before
/// letting somebody leave with one running — see `RungShell` — and that is the
/// whole of the protection.
class VideoUploadQueue extends Notifier<VideoUploadJob?> {
  @override
  VideoUploadJob? build() => null;

  bool get isBusy => state?.isActive ?? false;

  /// Whether a transfer has been begun and nobody has claimed it yet.
  bool get hasParked => state?.isParked ?? false;

  /// The running transfer's cancel handle. Null between jobs.
  CancelToken? _token;

  /// [VideoUploadJob.tag] for the running job, so every state written from
  /// inside [_run] carries it without threading it through each call.
  String? _tag;

  /// The running job's name. A field rather than a parameter because [commit]
  /// may rename it: a reel begun at pick time is named after its file, and
  /// becomes named after its caption once there is one.
  String _label = '';

  /// What to do when the bytes land. Null on a transfer that was begun eagerly
  /// and not yet claimed.
  OnVideoUploaded? _onUploaded;

  /// Where the bytes landed, once they have. Held so that a [commit] arriving
  /// after the transfer finished can run against it immediately.
  StreamUploadResult? _transferred;

  /// Starts the transfer with nothing attached to it yet.
  ///
  /// **This is the whole point of the eager path.** A phone video is tens of
  /// megabytes on a mobile uplink, and the person spends the next half minute
  /// writing a caption or a lesson title — time the uplink was previously
  /// spent doing nothing. Beginning here means that by the time they press
  /// Publish most of the file has already gone, and the post feels immediate
  /// rather than merely backgrounded.
  ///
  /// Nothing is written anywhere until [commit]. A transfer nobody claims is
  /// dropped by [abandon], which takes the video back off Bunny — so somebody
  /// who picks a clip and changes their mind leaves nothing behind.
  ///
  /// Returns false when a job is already running or parked.
  bool begin({required String localPath, required String label}) {
    if (isBusy || hasParked) return false;
    _startTransfer(localPath: localPath, label: label, onUploaded: null);
    return true;
  }

  /// Says what the transfer was for, and lets it complete.
  ///
  /// Runs [onUploaded] straight away when the bytes have already landed, and
  /// otherwise hands it to the transfer still in flight. Either way the caller
  /// does not wait: this returns as soon as the job has been claimed.
  ///
  /// [label] renames the job on the banner — the caption, now that there is
  /// one. [tag] binds it to the row it belongs to; see [VideoUploadJob.tag].
  ///
  /// Returns false when there is nothing to claim, or when the transfer failed
  /// or was cancelled while the person was still typing.
  bool commit({String? label, String? tag, required OnVideoUploaded onUploaded}) {
    final job = state;
    if (job == null) return false;
    if (_onUploaded != null) return false;
    if (job.stage != VideoUploadStage.uploading &&
        job.stage != VideoUploadStage.ready) {
      return false;
    }

    _onUploaded = onUploaded;
    if (label != null && label.trim().isNotEmpty) _label = label.trim();
    if (tag != null) _tag = tag;

    final transferred = _transferred;
    if (job.stage == VideoUploadStage.ready && transferred != null) {
      unawaited(_finish(transferred, onUploaded));
    } else {
      // Still moving. Repaint under the new name so the banner the person sees
      // on their way out of the composer is the one they just titled.
      state = VideoUploadJob(
        label: _label,
        stage: job.stage,
        tag: _tag,
        progress: job.progress,
      );
    }
    return true;
  }

  /// Takes [localPath] to Bunny and then calls [onUploaded] with the URLs.
  ///
  /// The one-shot form of [begin] + [commit], for a caller that already knows
  /// what the video is for.
  ///
  /// [onUploaded] is where the caller's own write goes — publishing the reel,
  /// saving the lesson. It runs HERE rather than in the caller so that the
  /// whole operation is one thing that either happened or did not: a transfer
  /// that succeeded and a publish that failed is the state nobody handles, and
  /// keeping both on this side means the banner can report it.
  ///
  /// **[onUploaded] is handed THIS notifier's `Ref`, and must use it.** The
  /// screen that started the job is gone by the time the callback runs — that
  /// is the entire point — so a `ref` captured from a `ConsumerState`, or a
  /// notifier read through one, is dead by then. Reading providers through the
  /// passed ref is the only form that survives, because this notifier outlives
  /// every route.
  ///
  /// Returns false when a job is already running.
  bool start({
    required String localPath,
    required String label,
    String? tag,
    required OnVideoUploaded onUploaded,
  }) {
    if (isBusy || hasParked) return false;
    _startTransfer(
      localPath: localPath,
      label: label,
      tag: tag,
      onUploaded: onUploaded,
    );
    return true;
  }

  void _startTransfer({
    required String localPath,
    required String label,
    String? tag,
    required OnVideoUploaded? onUploaded,
  }) {
    _token = CancelToken();
    _tag = tag;
    _label = label;
    _onUploaded = onUploaded;
    _transferred = null;

    state = VideoUploadJob(
      label: label,
      stage: VideoUploadStage.uploading,
      tag: tag,
      claimed: onUploaded != null,
    );

    // Not awaited: that is the point of this class. Errors are captured into
    // the state below rather than escaping into the zone.
    unawaited(_run(localPath: localPath));
  }

  /// Records a failure and prints the real cause.
  ///
  /// The banner shows `arabicMessageForException`, which falls back to a
  /// generic "something went wrong" for any message it has no rule for — and
  /// every message this path produces is one of those. That is right for the
  /// person using the app and useless for finding out what broke, so the
  /// untranslated exception and its `cause` go to the log, where a Dio error
  /// carries the status code and the response body Bunny actually sent.
  void _fail(VideoUploadStage at, AppException? error) {
    final detail = _describe(at, error);
    if (kDebugMode) debugPrint('[upload] $detail');

    state = VideoUploadJob(
      label: _label,
      stage: VideoUploadStage.failed,
      tag: _tag,
      // An unclaimed job's failure is the composer's to report, not the
      // shell's — see [VideoUploadJob.claimed].
      claimed: _onUploaded != null,
      progress: at == VideoUploadStage.uploading ? 0 : 1,
      error: error,
      debugDetail: detail,
    );
  }

  /// The failure in one line: which step, and whatever the server said.
  static String _describe(VideoUploadStage at, AppException? error) {
    final buffer = StringBuffer('${at.name}: ${error?.message ?? 'unknown'}');

    final cause = error?.cause;
    if (cause is DioException) {
      final status = cause.response?.statusCode;
      final body = '${cause.response?.data ?? ''}';
      buffer.write(' · ${cause.requestOptions.method} ');
      // The path only — the host is always video.bunnycdn.com and the full URL
      // pushes the part that varies off the end of a phone-width line.
      buffer.write(cause.requestOptions.uri.path);
      if (status != null) buffer.write(' · $status');
      if (body.isNotEmpty) {
        buffer.write(' · ${body.length > 160 ? body.substring(0, 160) : body}');
      }
      if (status == null) buffer.write(' · ${cause.type.name}');
    } else if (cause != null) {
      buffer.write(' · $cause');
    }
    return buffer.toString();
  }

  Future<void> _run({required String localPath}) async {
    // **AWAIT the library before asking for the uploader.**
    //
    // `streamUploadServiceProvider` reads `streamLibraryProvider.valueOrNull`,
    // which is null for as long as that one-shot fetch is in flight — so a
    // synchronous read here answers "no library configured" whenever this job
    // is the first thing in the session to want one. Which is exactly what it
    // now is: the composer used to read the provider when the video was
    // PICKED, warming it a minute before publish, and that read went away when
    // the transfer moved off the composer.
    //
    // Awaiting the future turns "not loaded yet" back into "wait", and leaves
    // only the genuine answer behind it.
    try {
      await ref.read(streamLibraryProvider.future);
    } catch (_) {
      // Fall through: the null check below reports it in the same terms as a
      // tenant with no library at all, which is what it amounts to.
    }

    final uploader = ref.read(streamUploadServiceProvider);
    if (uploader == null) {
      _fail(
        VideoUploadStage.uploading,
        const UnknownException(
          'Video streaming is not configured on this server',
        ),
      );
      return;
    }

    final token = _token;
    if (token?.isCancelled ?? false) {
      _cancelled();
      return;
    }

    final uploaded = await uploader.upload(
      localPath,
      cancelToken: token,
      title: _label.trim().isEmpty ? 'video' : _label.trim(),
      onProgress: (sent, total) {
        if (total <= 0) return;
        // Only while still uploading: a late progress callback arriving after
        // the stage moved on would drag the banner backwards.
        if (state?.stage != VideoUploadStage.uploading) return;
        state = VideoUploadJob(
          label: _label,
          stage: VideoUploadStage.uploading,
          tag: _tag,
          claimed: _onUploaded != null,
          progress: (sent / total).clamp(0, 1).toDouble(),
        );
      },
    );

    final result = uploaded.valueOrNull;
    if (result == null) {
      final error = uploaded.errorOrNull;
      // A cancelled transfer comes back as a failure like any other — Dio
      // throws `DioExceptionType.cancel` and the service wraps it — so the
      // distinction has to be made here, from the token, before the banner
      // decides whether to shout.
      if ((token?.isCancelled ?? false) ||
          StreamUploadService.wasCancelled(error)) {
        _cancelled();
      } else {
        _fail(VideoUploadStage.uploading, error);
      }
      return;
    }

    if (token?.isCancelled ?? false) {
      // Cancelled in the gap between the last byte and this line. The video is
      // on Bunny and nothing in the app points at it; honouring the cancel is
      // still the right answer, so the orphan is dropped rather than a reel
      // published against the person's wishes.
      _discard(result);
      _cancelled();
      return;
    }

    _transferred = result;

    final onUploaded = _onUploaded;
    if (onUploaded == null) {
      // Begun eagerly and still unclaimed: the person is writing their caption
      // and the file is already up. Park, and wait for `commit` — or for
      // `abandon`, if they change their mind.
      state = VideoUploadJob(
        label: _label,
        stage: VideoUploadStage.ready,
        tag: _tag,
        claimed: false,
        progress: 1,
      );
      return;
    }

    await _finish(result, onUploaded);
  }

  /// Runs the caller's write against a finished transfer.
  Future<void> _finish(
    StreamUploadResult result,
    OnVideoUploaded onUploaded,
  ) async {
    state = VideoUploadJob(
      label: _label,
      stage: VideoUploadStage.finishing,
      tag: _tag,
      progress: 1,
    );

    // Caught rather than allowed to escape: this runs unawaited, so a throw
    // here would be an unhandled async error that leaves the banner stuck on
    // "publishing" forever with nothing on screen saying why.
    final Result<void, AppException> published;
    try {
      published = await onUploaded(ref, result);
    } catch (e, st) {
      _fail(
        VideoUploadStage.finishing,
        UnknownException('تعذّر إكمال النشر بعد الرفع', cause: e, stackTrace: st),
      );
      return;
    }

    published.when(
      success: (_) => state = VideoUploadJob(
        label: _label,
        stage: VideoUploadStage.done,
        tag: _tag,
        progress: 1,
      ),
      failure: (e) => _fail(VideoUploadStage.finishing, e),
    );
  }

  /// Takes a video back off Bunny. Best effort, and deliberately silent.
  void _discard(StreamUploadResult result) {
    final uploader = ref.read(streamUploadServiceProvider);
    if (uploader == null) return;
    unawaited(uploader.discard(result.guid));
  }

  /// Stops the running transfer, if it is still at a point where stopping is
  /// honest. See [VideoUploadJob.canCancel].
  ///
  /// The service takes the half-created video record back off Bunny; nothing is
  /// written in the app, because nothing had been written yet.
  void cancel() {
    if (!(state?.canCancel ?? false)) return;
    _token?.cancel('cancelled by user');
    // Reported straight away rather than waiting for the cancelled request to
    // unwind: on a stalled uplink that can take as long as the send timeout,
    // and a Cancel button that does nothing visible for a minute reads as
    // broken. `_run` sees the same token and will not overwrite this.
    _cancelled();
  }

  /// Drops a transfer that was begun eagerly and never claimed.
  ///
  /// Called when somebody picks a video and then leaves without publishing, or
  /// replaces it with a different clip. The bytes are either stopped mid-flight
  /// or, if they already landed, taken back off Bunny — so an abandoned
  /// composer leaves no video in the library and no row anywhere.
  ///
  /// A COMMITTED job is never abandoned. Once the person has pressed Publish
  /// the work belongs to the queue, not to the screen they are leaving, and
  /// that is the entire reason this class exists.
  void abandon() {
    if (_onUploaded != null) return;

    final job = state;
    if (job == null) return;

    if (job.stage == VideoUploadStage.uploading) {
      // The service deletes the half-created video record on cancel.
      _token?.cancel('abandoned');
    } else if (job.stage == VideoUploadStage.ready) {
      final transferred = _transferred;
      if (transferred != null) _discard(transferred);
    }

    _reset();
  }

  void _cancelled() {
    state = VideoUploadJob(
      label: _label,
      stage: VideoUploadStage.cancelled,
      tag: _tag,
      claimed: _onUploaded != null,
    );
  }

  /// Clears a finished or failed job. The banner shows those until dismissed:
  /// a success that vanished on its own would leave somebody unsure whether
  /// the thing they walked away from ever happened.
  void clear() {
    if (isBusy || hasParked) return;
    _reset();
  }

  void _reset() {
    _token = null;
    _tag = null;
    _label = '';
    _onUploaded = null;
    _transferred = null;
    state = null;
  }
}

/// What a caller wants done once the bytes are on Bunny.
///
/// Takes the QUEUE's `Ref`, never the caller's — see [VideoUploadQueue.start].
typedef OnVideoUploaded = Future<Result<void, AppException>> Function(
  Ref,
  StreamUploadResult,
);

final videoUploadQueueProvider =
    NotifierProvider<VideoUploadQueue, VideoUploadJob?>(VideoUploadQueue.new);
