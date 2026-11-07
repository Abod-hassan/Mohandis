/// Strips credentials out of a line before the debug logger prints it.
///
/// **Why a debug log needs this.** The request logger is debug-only, so none
/// of this reaches a release build — but debug output does not stay on the
/// machine that produced it. It is copied into bug reports, pasted into chats,
/// screenshotted into tickets. Unredacted, one sign-in printed the password,
/// a SystemAdmin access token good for a week, a 60-day refresh token and the
/// Bunny storage write key, all in plain text, and every later request
/// repeated the bearer. The auth contract says it in one line: never log a
/// token.
///
/// Redacts by shape rather than by request, so it covers routes added later:
///
///   * any `Bearer <token>` (the Authorization header on every call)
///   * JSON string fields named like a secret — `"accessToken": "…"`,
///     `"refreshToken"`, `"password"` (which is also the Bunny key on
///     `Storage/Zone`), `"apiKey"`, `"token"`, and the password-change fields
///   * the same names in a Dart map's `toString()` — how Dio prints a request
///     body: `{userName: obeida, password: 123456}`
///   * `X-KEY` / `X-Request-Key`, the per-request signatures
String redactSecrets(String line) {
  var out = line.replaceAllMapped(
    _bearer,
    (m) => '${m[1]}<redacted>',
  );
  out = out.replaceAllMapped(
    _jsonSecret,
    (m) => '${m[1]}<redacted>${m[2]}',
  );
  out = out.replaceAllMapped(
    _mapSecret,
    (m) => '${m[1]}<redacted>',
  );
  out = out.replaceAllMapped(
    _signatureHeader,
    (m) => '${m[1]}<redacted>',
  );
  return out;
}

const _secretNames =
    'accessToken|refreshToken|password|currentPassword|newPassword|'
    'confirmPassword|apiKey|token|idToken|otp|code|secret';

final _bearer = RegExp(r'(Bearer\s+)[A-Za-z0-9\-_\.=+/]+');

/// `"name": "value"` — JSON, any spacing, case-insensitive name.
final _jsonSecret = RegExp(
  '("(?:$_secretNames)"\\s*:\\s*")[^"]*(")',
  caseSensitive: false,
);

/// `name: value` in a Dart map's toString, up to the next `,` `}` or newline.
/// Not preceded by a quote, so it never re-hits a JSON key.
final _mapSecret = RegExp(
  '(?<!")\\b((?:$_secretNames)\\s*:\\s*)(?!")[^,}\\n]+',
  caseSensitive: false,
);

final _signatureHeader = RegExp(
  r'(X-(?:KEY|Request-Key)\s*:\s*)\S+',
  caseSensitive: false,
);
