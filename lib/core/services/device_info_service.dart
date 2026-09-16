import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Minimal placeholder for device metadata used by request headers.
/// Replace with `device_info_plus` / `package_info_plus` calls when you wire
/// real values — the interface stays the same.
class DeviceInfoService {
  /// SharedPreferences key for the install-stable device serial.
  /// Bumping this key effectively rotates every device's serial — only
  /// do that with intent.
  static const String _installIdPrefsKey = 'device.install_id';

  static const Uuid _uuid = Uuid();

  /// In-process cache so we hit SharedPreferences only once per launch.
  /// Stored as a future (not the resolved string) so concurrent first
  /// callers all await the SAME resolution — without this, two early
  /// requests on a fresh install could each mint a different UUID and
  /// race on the prefs write.
  Future<String>? _serialFuture;

  /// Returns a UUID v4 that is **stable for the lifetime of the
  /// installation**. Minted on first call (after install, after
  /// "clear data" on Android, after re-install), persisted to
  /// SharedPreferences, and reused on every subsequent call.
  ///
  /// Surfaced on the wire as `X-Device-SN`. The backend uses it for:
  ///   * device-keyed FCM token rows
  ///   * per-device session revocation
  ///   * deriving the per-device signing secret in the
  ///     signing-bootstrap handshake (it replaces the old
  ///     `X-Device-Fingerprint` header — see
  ///     `Backend/docs/mobile-request-headers.md`).
  ///
  /// **Reset semantics:** value survives app restarts and OS updates,
  /// but resets on app uninstall + reinstall, and on Android's
  /// Settings → Apps → Storage → Clear data. iOS has no equivalent
  /// "clear data" path; only uninstall rotates the value.
  Future<String> deviceSerial() {
    return _serialFuture ??= _resolveInstallId();
  }

  Future<String> _resolveInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_installIdPrefsKey);
    if (stored != null && stored.isNotEmpty) return stored;
    // First read on this install — mint and persist.
    final minted = _uuid.v4();
    await prefs.setString(_installIdPrefsKey, minted);
    return minted;
  }

  Future<String> osDescriptor() async {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Best-effort OS version string, attached to outgoing requests as
  /// `X-Device-OS-Version` (paired with [osDescriptor]). Values look like:
  ///   * iOS:     `"Version 17.5.1 (Build 21F90)"`
  ///   * macOS:   `"Version 14.5 (Build 23F79)"`
  ///   * Android: kernel descriptor (e.g. `"Linux 5.10.198-android13-…"`).
  ///
  /// `Platform.operatingSystemVersion` exposes the platform-reported string
  /// directly so we don't need to add `device_info_plus` just for this. When
  /// that package is wired later (TODO at the top of this file), prefer its
  /// structured fields — `androidInfo.version.release`, `iosInfo.systemVersion`
  /// — and keep this method's contract (a single string).
  ///
  /// Returns `'unknown'` on web and on any platform that rejects the call.
  Future<String> osVersion() async {
    if (kIsWeb) return 'unknown';
    try {
      final raw = Platform.operatingSystemVersion;
      return raw.isEmpty ? 'unknown' : raw;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String> appVersion() async {
    return '1.0.0';
  }

  String timezone() => DateTime.now().timeZoneName;
}
