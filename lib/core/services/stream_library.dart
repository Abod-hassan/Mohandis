import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_envelope.dart';
import '../api/endpoints.dart';
import '../providers.dart';

/// The Bunny **Stream** video library this deployment publishes reels to, as
/// the backend reports it.
///
/// **Why Stream and not the storage zone everything else uses.** A storage zone
/// behind a pull zone serves a file byte for byte — upload an .mp4 and that is
/// the only thing you can ever ask it for. Stream transcodes on ingest and then
/// offers an HLS ladder AND a generated poster at a predictable URL, which is
/// what lets a reel show a still frame while its video buffers without the
/// phone or the server extracting one.
///
/// Like [StorageZone] it carries a write key, and for the same reason: Bunny
/// authenticates a Stream upload with the library key and has no presigned
/// equivalent. It grants read and write over this LIBRARY, so point it at one
/// that holds nothing but reels.
class StreamLibrary {
  const StreamLibrary({
    required this.libraryId,
    required this.apiKey,
    required this.cdnHostname,
  });

  factory StreamLibrary.fromJson(Map<String, dynamic> json) => StreamLibrary(
    libraryId: (json['libraryId'] as num?)?.toInt() ?? 0,
    apiKey: json['apiKey'] as String? ?? '',
    cdnHostname: json['cdnHostname'] as String? ?? '',
  );

  /// The library id — first path segment of every Stream API call.
  final int libraryId;

  /// Sent as the `AccessKey` header on both the create and the upload.
  final String apiKey;

  /// Where playback and posters are READ from — `vz-xxxxxxxx.b-cdn.net`.
  /// `video.bunnycdn.com` accepts the uploads and serves nothing.
  final String cdnHostname;

  /// Where a video's files live once Bunny has processed it.
  ///
  /// Everything a reel needs hangs off this one directory: `playlist.m3u8` for
  /// playback and `thumbnail.jpg` for the poster. Stored host-less on the reel
  /// row — `<guid>/playlist.m3u8` — so the library can be repointed without
  /// rewriting rows, exactly like a storage path.
  String? publicUrl(String? storedPath) {
    final path = storedPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (cdnHostname.isEmpty) return null;

    final host = cdnHostname.startsWith('http')
        ? cdnHostname
        : 'https://$cdnHostname';
    return '$host/${path.startsWith('/') ? path.substring(1) : path}';
  }

  bool get isConfigured => libraryId > 0 && apiKey.isNotEmpty;
}

/// Fetches the library once per session and holds it.
///
/// **Null is a normal outcome**, like the storage zone: a tenant with no Stream
/// library configured lands here as null and the composer hides the reel
/// option rather than failing at the upload with an opaque 401.
class StreamLibraryNotifier extends AsyncNotifier<StreamLibrary?> {
  @override
  Future<StreamLibrary?> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue<StreamLibrary?>.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<StreamLibrary?> _load() async {
    // No anonymous path here, unlike the storage zone: sign-up uploads a photo
    // before an account exists, but nobody publishes a reel before signing in.
    final result = await apiCall<StreamLibrary?>(
      EndPoints.streamLibrary,
      () => ref
          .read(apiClientProvider)
          .dio
          .get<dynamic>(EndPoints.streamLibrary),
      (envelope) => StreamLibrary.fromJson(envelope.object),
    );

    // "not configured" arrives as `error: true` on a 200 — the module's way of
    // saying "no library", not a fault.
    final library = result.valueOrNull;
    if (library == null || !library.isConfigured) {
      ref.read(loggerProvider).d(
        '[stream] no usable library — reel publishing stays disabled',
      );
      return null;
    }
    return library;
  }
}

/// The active Stream library, or null when this deployment has none.
final streamLibraryProvider =
    AsyncNotifierProvider<StreamLibraryNotifier, StreamLibrary?>(
      StreamLibraryNotifier.new,
    );
