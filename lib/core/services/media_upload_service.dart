import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../error/app_exception.dart';
import '../error/result.dart';
import 'storage_zone.dart';

/// Uploads images to Bunny.net Storage and returns the value to store.
///
/// **What is stored is the host-less path** — `avatars/<uuid>.jpg`, never a
/// full URL. The CDN hostname is deployment configuration: baking it into
/// every row would mean rewriting the database to move zones or put a new pull
/// zone in front, and the same rows have to render behind whatever host each
/// environment uses.
///
/// **The zone comes from the backend**, not from the flavour — see
/// [StorageZone]. Nothing here knows a zone name or a password at compile time.
///
/// Uses its own bare Dio on purpose. The app's `ApiClient` attaches a bearer
/// token, `X-KEY` and a request signature to everything it sends; forwarding
/// those to a third party would leak the session, and Bunny would reject the
/// `Content-Type` the client sets anyway.
class MediaUploadService {
  MediaUploadService({required StorageZone zone, Dio? dio, Uuid? uuid})
    : _zone = zone,
      _uuid = uuid ?? const Uuid(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              // Bounds the WHOLE body transfer, not a gap between chunks —
              // Dio's IO adapter wraps `addStream` in one timeout. Sixty
              // seconds was sized for a re-encoded photo; a 60-second 1080p
              // clip is 100 MB or more and takes minutes on a phone uplink,
              // so that ceiling failed every realistic reel at exactly the
              // moment the bytes were still moving. Ten minutes is long
              // enough for the file and short enough to eventually give up —
              // and the caller now gets progress, so a slow upload no longer
              // looks like a hang.
              sendTimeout: const Duration(minutes: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final StorageZone _zone;
  final Dio _dio;
  final Uuid _uuid;

  /// Uploads the file at [localPath] and returns its stored path.
  ///
  /// The name is generated rather than taken from the picker: a device
  /// filename is not unique, can carry the person's own words, and would let
  /// one upload overwrite another's file in a shared zone.
  ///
  /// [folder] overrides the zone's default prefix — `posts` for a post's
  /// attachments, say, rather than the `avatars` the zone is configured with.
  /// Keeping kinds apart matters later: a zone-wide purge, a CDN rule or a
  /// lifecycle policy is written against a prefix, and there is no way to
  /// separate them again once everything shares one.
  Future<Result<String, AppException>> uploadImage(
    String localPath, {
    String? folder,
    ProgressCallback? onProgress,
  }) => _upload(
    localPath,
    folder: folder,
    onProgress: onProgress,
    fallbackExtension: '.jpg',
    failureMessage: 'تعذّر رفع الصورة',
  );

  /// Uploads a document — a PDF, a spreadsheet, whatever the person picked.
  ///
  /// Identical to [uploadImage] but for two things: an unrecognised file keeps
  /// no extension rather than being renamed `.jpg`, which would have the CDN
  /// serve a spreadsheet as an image; and the failure text says "الملف", since
  /// a person who attached a PDF has not been told anything useful by a message
  /// about a photo.
  Future<Result<String, AppException>> uploadDocument(
    String localPath, {
    String? folder,
    ProgressCallback? onProgress,
  }) => _upload(
    localPath,
    folder: folder,
    onProgress: onProgress,
    fallbackExtension: '',
    failureMessage: 'تعذّر رفع الملف',
  );

  /// Uploads a video — a reel, or the moving half of a story.
  ///
  /// The fallback is `.mp4` rather than nothing: a clip whose extension the
  /// allow-list does not know is still a video, and a path with no extension
  /// has the CDN serve it as `application/octet-stream`, which every mobile
  /// player refuses to start. `.mp4` is the container the pickers hand back on
  /// both platforms anyway, so the guess is almost always the truth.
  Future<Result<String, AppException>> uploadVideo(
    String localPath, {
    String? folder,
    ProgressCallback? onProgress,
  }) => _upload(
    localPath,
    folder: folder,
    onProgress: onProgress,
    fallbackExtension: '.mp4',
    failureMessage: 'تعذّر رفع الفيديو',
  );

  Future<Result<String, AppException>> _upload(
    String localPath, {
    required String? folder,
    required String fallbackExtension,
    required String failureMessage,
    ProgressCallback? onProgress,
  }) async {
    // The provider only builds this service for a configured zone, so this is
    // a guard against a hand-constructed one rather than the normal path.
    if (!_zone.isConfigured) {
      return const Result.failure(
        UnknownException('Storage is not configured on this server'),
      );
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      return Result.failure(NotFoundException('الملف غير موجود: $localPath'));
    }

    // Exactly the three fields the backend serves — the zone's host, its name
    // as the first path segment, and its password as the key.
    final storageHostname = _zone.storageHostname.isNotEmpty
        ? _zone.storageHostname
        : 'storage.bunnycdn.com';
    final storageName = _zone.name;
    final password = _zone.password;

    final extension = _extensionOf(localPath, fallbackExtension);
    final prefix = (folder != null && folder.trim().isNotEmpty)
        ? folder.trim()
        : _zone.folder;
    final storedPath = '$prefix/${_uuid.v4()}$extension';
    final url = 'https://$storageHostname/$storageName/$storedPath';

    try {
      final length = await file.length();
      await _dio.put<dynamic>(
        url,
        data: file.openRead(),
        options: Options(
          headers: {
            // Bunny's own header name — not `Authorization`.
            'AccessKey': password,
            Headers.contentTypeHeader: 'application/octet-stream',
            // Required with a stream body: without it Dio sends chunked, which
            // Bunny answers with a 411.
            Headers.contentLengthHeader: length,
          },
          // 201 is the success code here; anything else should raise.
          validateStatus: (status) => status != null && status < 300,
        ),
        // Meaningful because Content-Length is set above: without it Dio
        // reports -1 for the total and the caller can only show a spinner.
        onSendProgress: onProgress,
      );
      return Result.success(storedPath);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        // Either the tenant's stored key is the read-only one, or it has been
        // rotated since this session fetched it. Both are fixed server-side —
        // the app has nothing to fall back to.
        return const Result.failure(
          UnauthorizedException('مفتاح التخزين غير صحيح'),
        );
      }
      return Result.failure(
        NetworkException(
          '$failureMessage${status != null ? ' ($status)' : ''}',
          cause: e,
        ),
      );
    } catch (e, s) {
      return Result.failure(
        UnknownException(failureMessage, cause: e, stackTrace: s),
      );
    }
  }

  /// Keeps the source extension so the CDN serves a sensible content type.
  /// Anything unexpected falls back to [fallback] — `.jpg` for a photo, where
  /// guessing is safe, and nothing at all for a document, where guessing would
  /// have the CDN serve a spreadsheet as an image.
  static String _extensionOf(String path, String fallback) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return fallback;
    final ext = path.substring(dot).toLowerCase();

    // Allow-listed, not passed through. The extension becomes part of a path
    // this app PUTs to, so a crafted name is a path-traversal attempt and an
    // unknown one is a content type the CDN will guess at.
    const images = {'.jpg', '.jpeg', '.png', '.heic', '.webp'};
    const videos = {'.mp4', '.mov', '.m4v', '.webm', '.3gp'};
    const documents = {
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.txt', '.csv', '.rtf', '.zip',
    };
    if (images.contains(ext)) return ext;

    // Only a video upload asks for `.mp4`, so this branch cannot be reached by
    // uploadImage — a `.mov` attached to a post still becomes `.jpg` there,
    // which is the existing behaviour and the right one: the post media grid
    // has no player.
    if (fallback == '.mp4' && videos.contains(ext)) return ext;

    // A document upload asks for no fallback, and that is what says these are
    // allowed: an image upload would rename any of them to .jpg.
    if (fallback.isEmpty && documents.contains(ext)) return ext;

    return fallback;
  }
}

/// Null until the backend has answered with a usable zone — and null forever
/// on a deployment that has none. Callers hide the photo control rather than
/// offering an upload that cannot work.
///
/// Watching this is what triggers the fetch: nothing else asks for the zone,
/// so the first screen that offers a photo control is what loads it.
final mediaUploadServiceProvider = Provider<MediaUploadService?>((ref) {
  final zone = ref.watch(storageZoneProvider).valueOrNull;
  if (zone == null || !zone.isConfigured) return null;
  return MediaUploadService(zone: zone);
});
