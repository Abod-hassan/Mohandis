import 'user.dart';

/// In-memory representation of a logged-in mobile session.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  /// True when the access token is past its server-issued expiry. Falls
  /// back to `false` when no expiry is known so we don't refresh-loop
  /// unnecessarily.
  bool get accessExpired {
    final at = accessTokenExpiresAt;
    if (at == null) return false;
    return DateTime.now().toUtc().isAfter(at.toUtc());
  }

  AuthSession copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) =>
      AuthSession(
        user: user ?? this.user,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        accessTokenExpiresAt:
            accessTokenExpiresAt ?? this.accessTokenExpiresAt,
        refreshTokenExpiresAt:
            refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      );
}
