import 'dart:convert';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';

/// Wire shape of the backend's `LoginResultDto`, returned by
/// `/api/Auth/Login`, `/api/Auth/SignUp` and `/api/Auth/Refresh-Token`.
///
/// Returned bare — these two actions do not use the `ResultViewModel`
/// envelope the rest of the platform uses.
///
/// **There are no expiry fields.** The server issues a 1-day access token on
/// login and a 7-day one on refresh but never says so in the body, so the
/// expiry is read from the JWT's own `exp` claim ([expiryFromJwt]). Without
/// that, `AuthSession.accessExpired` is always false and the app only learns
/// the token died when a request comes back 401.
class MobileAuthResultDto {
  const MobileAuthResultDto({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
    this.userName,
    this.displayName,
    this.phoneNumber,
    this.userType,
    this.tenantId,
    this.roles = const [],
    this.isNewUser = false,
    this.requiresTwoFactor = false,
    this.email,
  });

  factory MobileAuthResultDto.fromJson(Map<String, dynamic> json) {
    return MobileAuthResultDto(
      accessToken: '${json['accessToken'] ?? ''}',
      refreshToken: '${json['refreshToken'] ?? ''}',
      userId: json['id']?.toString(),
      userName: json['userName'] as String?,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      // Enums serialise by name — the host registers Newtonsoft's
      // StringEnumConverter — so this arrives as "User" / "Admin", not 2.
      userType: json['userType']?.toString(),
      tenantId: (json['tenantId'] as num?)?.toInt(),
      isNewUser: json['isNewUser'] == true,
      requiresTwoFactor: json['requiresTwoFactor'] == true,
      email: json['email'] as String?,
      roles: json['roles'] is List
          ? (json['roles'] as List)
                .map((e) => '$e')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? userId;
  final String? userName;
  final String? displayName;
  final String? phoneNumber;

  /// Identity role bucket — `SystemAdmin` / `Admin` / `User`. Not the kind of
  /// account: see `Profile.accountType` for individual vs company.
  final String? userType;

  /// Multi-tenant partition, mirroring the JWT's `TenantId` claim.
  final int? tenantId;

  final List<String> roles;

  /// True when this is a REGISTRATION token rather than a session.
  ///
  /// The identity was proved — an OTP, an e-mail code — but no account exists
  /// behind it yet, so only [accessToken] (and sometimes [email]) are set and
  /// [refreshToken] is empty. It authorises exactly one call,
  /// `CreateWithContact`, which trades it for a real session.
  ///
  /// Branch on this BEFORE treating a response as a sign-in: the three states
  /// share one wire shape, and storing a registration token as a session
  /// strands the app holding a bearer that every other endpoint rejects.
  final bool isNewUser;

  /// True when this is a 2FA challenge rather than a session — a five-minute
  /// token spendable only on `TwoFactor/Verify`. Same trap as [isNewUser].
  final bool requiresTwoFactor;

  /// Present on an e-mail-verified registration token, echoing the address
  /// that was proved.
  final String? email;

  AuthSession toDomain() {
    final user = User(
      id: userId ?? '',
      name: (displayName?.isNotEmpty ?? false)
          ? displayName!
          : (userName ?? ''),
      userName: userName,
      roles: roles,
    );
    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: expiryFromJwt(accessToken),
      // The refresh token is an opaque server value, not a JWT, and its
      // expiry is never sent. Left null: `AuthTokenRefresher` then always
      // tries the call rather than pre-emptively signing the user out.
      refreshTokenExpiresAt: null,
    );
  }

  /// Whether [token] is structurally a JWT this backend could have issued.
  ///
  /// The check matters at cold start: a leftover token from a demo build
  /// (`"mock-access-token"`) is a perfectly good string in secure storage, and
  /// without this the app treats it as a session and lands on the feed instead
  /// of the login screen.
  static bool isJwt(String token) => _payload(token) != null;

  /// Reads the `exp` claim out of a JWT, as UTC.
  ///
  /// Decodes the payload only — no signature check, which is correct here:
  /// this is the client reading a token it was just handed, not validating
  /// one. Any malformed token yields null rather than throwing, so a change
  /// in token format can never break sign-in.
  static DateTime? expiryFromJwt(String token) {
    final exp = _payload(token)?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }

  /// The decoded claim set, or null if [token] is not a readable JWT.
  static Map<String, dynamic>? _payload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // base64url without padding — normalize before decoding.
      final json = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(json);
      return claims is Map ? claims.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }
}
