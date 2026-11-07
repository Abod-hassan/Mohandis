import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/result.dart';
import 'stream_library.dart';

/// Puts a reel's video on Bunny Stream and reports where it landed.
///
/// **Two calls, not one.** Stream has no single-shot upload: you create the
/// video record first (`POST .../videos`), which answers with the guid every
/// later URL is built from, and only then send the bytes to that guid
/// (`PUT .../videos/<guid>`). Doing it in that order is also what makes a
/// failed transfer recoverable — the record exists, so a retry can re-send the
/// file rather than orphaning a half-uploaded one under a new id.
///
/// **Nothing here waits for transcoding.** The PUT returns as soon as Bunny has
/// the file; the HLS ladder and the poster appear a little later. A reel
/// published immediately is therefore playable within seconds and shows its
/// poster once Stream has made one — which is why the player falls back to its
/// own first frame rather than treating a missing poster as an error.
///
/// Uses its own bare Dio, like [MediaUploadService] and for the same reason:
/// the app's `ApiClient` attaches a bearer token, `X-KEY` and a request
/// signature to everything it sends, and forwarding those to a third party
/// would leak the session.
class StreamUploadService {
  StreamUploadService({required StreamLibrary library, Dio? dio})
    : _library = library,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              // Bounds the WHOLE body transfer, as in MediaUploadService: a
              // 60-second reel is 100 MB or more on a phone uplink.
              sendTimeout: const Duration(minutes: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  static const String _apiBase = 'https://video.bunnycdn.com';

  final StreamLibrary _library;
  final Dio _dio;

  /// Uploads [localPath] and reports where Bunny put it.
  Future<Result<StreamUploadResult, AppException>> upload(
    String localPath, {
    required String title,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!_library.isConfigured) {
      return const Result.failure(
        UnknownException('Video streaming is not configured on this server'),
      );
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      return const Result.failure(UnknownException('الملف غير موجود'));
    }

    final headers = {
      'AccessKey': _library.apiKey,
      'accept': 'application/json',
    };
    final videos = '$_apiBase/library/${_library.libraryId}/videos';

    // Remembered outside the try so that a cancellation mid-transfer can take
    // the half-written video record back off Bunny — see the catch below.
    String? createdGuid;

    try {
      final created = await _dio.post<dynamic>(
        videos,
        data: {'title': title},
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      // Bunny answers with the whole video record; `guid` is the only field
      // that matters and the only one whose name is part of its public API.
      final body = created.data;
      final guid = body is Map ? '${body['guid'] ?? ''}'.trim() : '';
      if (guid.isEmpty) {
        return const Result.failure(
          UnknownException('تعذّر إنشاء الفيديو على الخادم'),
        );
      }
      createdGuid = guid;

      final sent = await _dio.put<dynamic>(
        '$videos/$guid',
        data: file.openRead(),
        options: Options(
          headers: {
            ...headers,
            // A stream body needs its length declared, or Dio sends it
            // chunked and Bunny rejects the upload.
            Headers.contentLengthHeader: await file.length(),
            Headers.contentTypeHeader: 'application/octet-stream',
          },
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      // Bunny answers the PUT with its own envelope — `{success, message,
      // statusCode}` — and does NOT always signal a rejected upload with an
      // HTTP error status. Dio only throws on the transport, so without this a
      // refused upload returns success here and publishes a reel whose video
      // was never stored.
      final sentBody = sent.data;
      final sentStatus = sentBody is Map ? sentBody['statusCode'] : null;
      if (sentStatus != null && '$sentStatus' != '200') {
        final message = sentBody is Map ? '${sentBody['message'] ?? ''}' : '';
        return Result.failure(
          UnknownException(
            message.isEmpty ? 'تعذّر رفع الفيديو' : message,
          ),
        );
      }

      _playError = null;
      final urls = await _playData(guid, cancelToken);
      if (urls == null) {
        // The playlist URL is the thing being published. Without it there is
        // nothing to store but a host-less path, and that path only resolves
        // if the library's CDN hostname was configured correctly — which is
        // the failure this whole call exists to make impossible.
        return Result.failure(
          _playError ??
              const UnknownException('تعذّر الحصول على رابط تشغيل الفيديو'),
        );
      }

      return Result.success(StreamUploadResult(guid: guid, urls: urls));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Somebody pressed Cancel. The video record was already created, and
        // Bunny keeps it — an empty entry in the library, billed for and shown
        // in the dashboard — unless it is asked to let go. Best effort: a
        // failed delete leaves litter, not a broken app.
        if (createdGuid != null) unawaited(discard(createdGuid));
        return Result.failure(
          UnknownException(_cancelledMessage, cause: e, stackTrace: e.stackTrace),
        );
      }
      return Result.failure(
        UnknownException('تعذّر رفع الفيديو', cause: e, stackTrace: e.stackTrace),
      );
    } catch (e, s) {
      return Result.failure(
        UnknownException('تعذّر رفع الفيديو', cause: e, stackTrace: s),
      );
    }
  }

  /// Asks Bunny for the finished CDN URLs of a video it just took.
  ///
  /// **This is what replaces a configured CDN hostname.** The host-less
  /// convention (`<guid>/playlist.m3u8`, resolved against a stored hostname)
  /// has one failure mode and it is unforgiving: nothing in the Stream API
  /// reports a library's pull-zone hostname — `GET /videolibrary/{id}` gives a
  /// `PullZoneId` and no name — so the hostname has to be copied off the
  /// dashboard by hand. Copy the wrong zone and every poster and every playlist
  /// 404s, while the upload itself succeeds, which makes it a configuration
  /// mistake that looks exactly like a broken player.
  ///
  /// `GET /library/{id}/videos/{guid}/play` hands back `videoPlaylistUrl` and
  /// `thumbnailUrl` already absolute. It also stops `thumbnail.jpg` being an
  /// assumption: a library with a custom poster name is served correctly
  /// because Bunny is the one naming the file.
  ///
  /// **Sent WITH the library key.** Bunny's own reference publishes this call
  /// with the `AccessKey` header, and the published spec marks its security as
  /// empty — which is a statement about the anonymous player path, not a
  /// promise that an authenticated call is refused. Sending the key is correct
  /// either way and is the only form known to work on a library with token
  /// authentication enabled.
  ///
  /// Returns null on any failure, and the caller falls back to the host-less
  /// paths. A reel that uploaded should still publish when this call does not
  /// answer; it just goes back to depending on the hostname being right.
  Future<StreamUrls?> _playData(String guid, CancelToken? cancelToken) async {
    try {
      final res = await _dio.get<dynamic>(
        '$_apiBase/library/${_library.libraryId}/videos/$guid/play',
        options: Options(
          headers: {
            'AccessKey': _library.apiKey,
            'accept': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );
      final body = res.data;
      if (body is! Map) return null;

      final playlist = '${body['videoPlaylistUrl'] ?? ''}'.trim();
      final thumbnail = '${body['thumbnailUrl'] ?? ''}'.trim();
      if (!playlist.startsWith('http')) return null;

      return StreamUrls(
        playlist: playlist,
        thumbnail: thumbnail.startsWith('http') ? thumbnail : null,
      );
    } catch (e, s) {
      // Kept rather than swallowed: this is the last step of the upload and a
      // failure here fails the whole thing, so "it did not answer" is not
      // enough — the caller needs the status and body to tell a 401 on the key
      // from a video Bunny has not finished registering.
      _playError = UnknownException(
        'تعذّر الحصول على رابط تشغيل الفيديو',
        cause: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Why the last [_playData] returned null. Read once by [upload].
  AppException? _playError;

  /// Drops a video record from the library.
  ///
  /// Used to clean up after a cancelled or abandoned upload, and deliberately
  /// silent: there is nobody left to tell. Public because the queue needs it
  /// too — a video that finished transferring and was then abandoned has to be
  /// taken back off Bunny, and by then this service's own call has returned.
  Future<void> discard(String guid) async {
    try {
      await _dio.delete<dynamic>(
        '$_apiBase/library/${_library.libraryId}/videos/$guid',
        options: Options(
          headers: {
            'AccessKey': _library.apiKey,
            'accept': 'application/json',
          },
        ),
      );
    } catch (_) {
      // Nothing to do. The reel was never published, so the orphan is invisible
      // to the app; it only costs the library a dead row.
    }
  }

  /// Marks the failure a cancellation produces. Callers compare against this
  /// rather than inspecting Dio, so the reason survives being wrapped.
  static const String _cancelledMessage = 'تم إلغاء الرفع';

  /// True when [error] is the failure a cancelled upload returns.
  static bool wasCancelled(AppException? error) =>
      error?.message == _cancelledMessage;

  /// Where a video's HLS playlist lives, host-less.
  static String playlistPath(String guid) => '$guid/playlist.m3u8';

  /// Where Stream publishes the generated poster, host-less.
  ///
  /// It does not exist the instant the upload finishes — transcoding makes it —
  /// so every reader treats a 404 here as "not yet", never as an error.
  static String thumbnailPath(String guid) => '$guid/thumbnail.jpg';
}

/// Bunny's own answer for where a video's files are, both absolute.
class StreamUrls {
  const StreamUrls({required this.playlist, required this.thumbnail});

  final String playlist;
  final String? thumbnail;
}

/// What an upload produced: the guid, and the URLs Bunny gave for it.
///
/// [urls] is NOT nullable. An upload that could not be asked where it landed is
/// reported as a failure rather than handed back with the question open — the
/// only alternative is storing a host-less path, and that path resolves solely
/// against a CDN hostname somebody typed in by hand. That setting being wrong
/// is precisely the failure this call exists to remove, so falling back to it
/// would reintroduce it on exactly the day the lookup is having a bad time.
class StreamUploadResult {
  const StreamUploadResult({required this.guid, required this.urls});

  final String guid;
  final StreamUrls urls;

  /// What to write to the reel's `videoUrl` — Bunny's own absolute playlist
  /// URL. Every resolver in the app passes an absolute URL through untouched,
  /// so a row written this way plays whatever the hostname setting says, or
  /// whether it is set at all.
  String get videoPath => urls.playlist;

  /// What to write to the reel's `thumbnailUrl`.
  ///
  /// Falls back to the guid convention only when Bunny named no poster — a
  /// video whose transcode has not reached the thumbnail yet. That path is a
  /// guess, but a poster is optional on the way in and the player treats a
  /// missing one as "not yet".
  String get posterPath =>
      urls.thumbnail ?? StreamUploadService.thumbnailPath(guid);
}

/// Null while this deployment has no Stream library, exactly like
/// `mediaUploadServiceProvider` is null without a storage zone — so a screen
/// can ask "can I publish a reel at all" with one read.
final streamUploadServiceProvider = Provider<StreamUploadService?>((ref) {
  final library = ref.watch(streamLibraryProvider).valueOrNull;
  if (library == null || !library.isConfigured) return null;
  return StreamUploadService(library: library);
});
