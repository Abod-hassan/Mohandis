/// Bunny.net Storage credentials for direct-from-app uploads.
///
/// **The access key ships inside the binary.** Bunny's storage password grants
/// write AND delete on the whole zone, and anyone can pull it out of an IPA or
/// APK — so point this at a storage zone that holds nothing but user uploads,
/// never one that also serves app assets. The durable fix is a small upload
/// endpoint on the host that holds the key server-side and returns the path;
/// when that exists, only [MediaUploadService] changes.
class BunnyStorageConfig {
  const BunnyStorageConfig({
    required this.zone,
    required this.accessKey,
    this.host = 'storage.bunnycdn.com',
    this.folder = 'avatars',
    this.cdnBaseUrl,
  });

  /// Storage zone name — the first path segment of every storage URL.
  final String zone;

  /// The zone's password (Bunny calls it "FTP & API Access → Password").
  /// Must be the read-WRITE one; the read-only key rejects PUT.
  final String accessKey;

  /// Region endpoint. Falkenstein (the default zone region) is the bare
  /// `storage.bunnycdn.com`; every other region is prefixed — `ny.`, `la.`,
  /// `sg.`, `syd.`, `uk.`, `se.`, `br.`, `jh.`. Using the wrong one answers
  /// 401, not a redirect.
  final String host;

  /// Path prefix inside the zone. Also the first segment of the stored value,
  /// since what lands on the contact is the host-less path.
  final String folder;

  /// Where uploads are READ from — the pull zone, not the storage endpoint.
  ///
  /// [host] accepts writes and refuses anonymous reads, so it cannot be used to
  /// display anything. Bunny's convention is `https://<pull-zone>.b-cdn.net`,
  /// and the pull zone is usually named after the storage zone — which is the
  /// default below. Set this explicitly whenever it isn't, or every uploaded
  /// photo resolves to a 404.
  final String? cdnBaseUrl;

  String get _cdnBase =>
      (cdnBaseUrl?.isNotEmpty ?? false) ? cdnBaseUrl! : 'https://$zone.b-cdn.net';

  /// The full URL for a stored path.
  ///
  /// What is persisted on a profile or contact is the host-less path
  /// (`avatars/abc.jpg`) so the CDN can be repointed without rewriting rows —
  /// this is where it becomes displayable again. An absolute URL is returned
  /// untouched, so a row written before this existed still renders.
  String? publicUrl(String? storedPath) {
    final path = storedPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$_cdnBase/${path.startsWith('/') ? path.substring(1) : path}';
  }

  /// True once the placeholders have been replaced with real values.
  bool get isConfigured =>
      zone.isNotEmpty &&
      accessKey.isNotEmpty &&
      !accessKey.startsWith('REPLACE_');
}
