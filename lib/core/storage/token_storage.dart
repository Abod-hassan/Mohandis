import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth tokens, their server-issued expiries, a tiny user cache for
/// cold-start rebuild, and the request-signing secret. The only place these
/// values are read/written; nothing else should touch the keystore directly.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _accessExpKey = 'auth.access_token_expires_at';
  static const _refreshExpKey = 'auth.refresh_token_expires_at';
  static const _userIdKey = 'auth.user_id';
  static const _userNameKey = 'auth.user_name';
  static const _displayNameKey = 'auth.display_name';
  static const _signingSecretKey = 'security.signing_secret';

  // ── reads ───────────────────────────────────────────────────────────────
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readAccessTokenExpiresAt() async {
    final raw = await _storage.read(key: _accessExpKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<DateTime?> readRefreshTokenExpiresAt() async {
    final raw = await _storage.read(key: _refreshExpKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<String?> readUserId() => _storage.read(key: _userIdKey);
  Future<String?> readUserName() => _storage.read(key: _userNameKey);
  Future<String?> readDisplayName() => _storage.read(key: _displayNameKey);

  Future<String?> readSigningSecret() =>
      _storage.read(key: _signingSecretKey);

  // ── writes ──────────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> saveSigningSecret(String secret) =>
      _storage.write(key: _signingSecretKey, value: secret);

  /// Persist a full session in one call. Pass `null` for any field that
  /// shouldn't overwrite an existing value — passing a value (even empty)
  /// will replace it.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
    String? userId,
    String? userName,
    String? displayName,
  }) async {
    final writes = <Future<void>>[
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ];
    if (accessTokenExpiresAt != null) {
      writes.add(_storage.write(
        key: _accessExpKey,
        value: accessTokenExpiresAt.toUtc().toIso8601String(),
      ));
    }
    if (refreshTokenExpiresAt != null) {
      writes.add(_storage.write(
        key: _refreshExpKey,
        value: refreshTokenExpiresAt.toUtc().toIso8601String(),
      ));
    }
    if (userId != null) {
      writes.add(_storage.write(key: _userIdKey, value: userId));
    }
    if (userName != null) {
      writes.add(_storage.write(key: _userNameKey, value: userName));
    }
    if (displayName != null) {
      writes.add(_storage.write(key: _displayNameKey, value: displayName));
    }
    await Future.wait(writes);
  }

  /// Legacy two-token convenience. Kept so callers that don't have expiry
  /// info can still persist a session (signing-bootstrap response, tests).
  @Deprecated('Use saveSession instead so expiry info is persisted too.')
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      saveSession(accessToken: accessToken, refreshToken: refreshToken);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpKey),
      _storage.delete(key: _refreshExpKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _displayNameKey),
    ]);
  }
}
