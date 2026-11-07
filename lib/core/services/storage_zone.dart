import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_envelope.dart';
import '../api/endpoints.dart';
import '../providers.dart';
import 'tenant_store.dart';

/// The Bunny.net storage zone this deployment writes user photos to, **as the
/// backend reports it**.
///
/// The zone name, its write password and the region endpoint used to be
/// compiled into each flavour. They are not any more, and the reason is not
/// tidiness: a password in the binary is the same password for every tenant,
/// cannot be rotated without shipping a release, and is trivially recoverable
/// from an IPA. Served from `GET /api/social/Storage/Zone` it is per tenant,
/// rotatable in place, and revocable the moment it leaks.
///
/// It is still a shared secret handed to clients — Bunny authenticates a
/// storage PUT with the zone password and has no presigned-upload equivalent,
/// so a direct upload cannot be done any other way. Point it at a zone that
/// holds nothing but user uploads.
class StorageZone {
  const StorageZone({
    required this.name,
    required this.password,
    required this.storageHostname,
    this.pullZoneUrl = '',
    this.folder = 'avatars',
  });

  /// Reads exactly the field names Bunny's own Storage Zone API uses, which is
  /// what the backend echoes — so a value copied straight out of Bunny's
  /// console lands in the right column with no renaming in between.
  factory StorageZone.fromJson(Map<String, dynamic> json) => StorageZone(
    name: json['name'] as String? ?? '',
    password: json['password'] as String? ?? '',
    storageHostname: json['storageHostname'] as String? ?? '',
    pullZoneUrl: json['pullZoneUrl'] as String? ?? '',
    folder: json['folder'] as String? ?? 'avatars',
  );

  /// Zone name — the first path segment of every storage URL.
  final String name;

  /// The zone's read-WRITE password, sent as the `AccessKey` header on a PUT.
  /// The read-only key answers 401 rather than refusing politely.
  final String password;

  /// Region endpoint that accepts writes. Falkenstein is the bare
  /// `storage.bunnycdn.com`; every other region is prefixed (`ny.`, `la.`,
  /// `sg.`, `syd.`, `uk.`, `se.`, `br.`, `jh.`). The server stores it rather
  /// than the app guessing, because the wrong one answers 401, not a redirect.
  final String storageHostname;

  /// Where uploads are READ from — the pull zone, not [storageHostname], which
  /// accepts writes and refuses anonymous reads. Empty falls back to Bunny's
  /// `https://<name>.b-cdn.net` convention below.
  final String pullZoneUrl;

  /// Path prefix inside the zone, and therefore the first segment of the value
  /// persisted on a profile. Server-owned so the layout can change without an
  /// app release.
  final String folder;

  String get _cdnBase =>
      pullZoneUrl.isNotEmpty ? pullZoneUrl : 'https://$name.b-cdn.net';

  /// The full URL for a stored path.
  ///
  /// What is persisted on a profile is the host-less path (`avatars/abc.jpg`)
  /// so the CDN can be repointed without rewriting rows — this is where it
  /// becomes displayable again.
  String? publicUrl(String? storedPath) {
    final path = storedPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$_cdnBase/${path.startsWith('/') ? path.substring(1) : path}';
  }

  /// True once the server has answered with a zone that can actually be
  /// written to. A tenant with no zone configured yields `null` from the
  /// provider instead, and the photo controls stay hidden.
  bool get isConfigured => name.isNotEmpty && password.isNotEmpty;
}

/// Fetches the zone once per session and holds it.
///
/// **Null is a normal outcome**, not an error state: a tenant with no Bunny
/// zone configured, or a host that predates this endpoint, both land here as
/// null and every photo control hides itself. Failing loudly would block
/// sign-up over something that is only ever optional.
class StorageZoneNotifier extends AsyncNotifier<StorageZone?> {
  @override
  Future<StorageZone?> build() => _load();

  /// Re-reads the zone — after the tenant's settings change, or after a
  /// password rotation invalidates the one held here.
  Future<void> refresh() async {
    state = const AsyncValue<StorageZone?>.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<StorageZone?> _load() async {
    // Sign-up uploads a profile photo before an account exists, so this call
    // has to work with no bearer. Kernel resolves the tenant from the JWT once
    // there is one, and a client-supplied header would then override the
    // claim — so the header goes on only while there is no token, exactly as
    // login and sign-up do it.
    Options? options;
    // Which tenant this request will be answered for, in the terms the log
    // below reports it. Not used for anything else.
    String scope;
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (token == null || token.isEmpty) {
      final tenant = await ref.read(tenantProvider.notifier).resolve();
      if (tenant != null) options = Options(headers: {'X-Tenant-Id': tenant});
      scope = 'X-Tenant-Id: ${tenant ?? 'none'}';
    } else {
      scope = 'JWT TenantId: ${_tenantClaim(token) ?? 'absent'}';
    }

    final result = await apiCall<StorageZone?>(
      EndPoints.storageZone,
      () => ref
          .read(apiClientProvider)
          .dio
          .get<dynamic>(EndPoints.storageZone, options: options),
      (envelope) => StorageZone.fromJson(envelope.object),
    );

    // "Storage is not configured on this server" arrives as `error: true` on a
    // 200 — the module's way of saying "no zone", not a fault. Treated the same
    // as an unreachable host: no zone, no photo control, everything else works.
    final zone = result.valueOrNull;
    if (zone == null || !zone.isConfigured) {
      // **Three different problems used to print one line.** "No usable zone"
      // can mean the server said this tenant has no storage row, or that the
      // call never arrived, or that it arrived for a tenant nobody configured
      // — and the third is the one that looks exactly like the first while
      // having nothing to do with storage at all. The tenant this request was
      // answered for is therefore part of the message: a zero or an absent
      // claim there means the session, not the settings.
      final why = result.errorOrNull?.message ?? 'no zone in the answer';
      ref.read(loggerProvider).d(
        '[storage] no usable zone — photo upload stays disabled · $scope · $why',
      );
      return null;
    }
    return zone;
  }

  /// The `TenantId` claim out of an access token, for the log line only.
  ///
  /// Decoding the payload is safe here: nothing is trusted from it, and the
  /// server reads the claim off the signed token regardless of what this says.
  static int? _tenantClaim(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (claims is! Map) return null;
      final raw = claims['TenantId'];
      return raw is num ? raw.toInt() : int.tryParse('$raw');
    } catch (_) {
      return null;
    }
  }
}

/// The active storage zone, or null when this deployment has none.
final storageZoneProvider =
    AsyncNotifierProvider<StorageZoneNotifier, StorageZone?>(
      StorageZoneNotifier.new,
    );
