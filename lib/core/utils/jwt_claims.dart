import 'dart:convert';

/// The payload of a JWT, decoded but NOT verified.
///
/// For UI decisions only — which screens to offer. Anything that matters is
/// enforced by the server, which checks the signature; a forged claim here
/// gets a button that answers 403.
Map<String, dynamic>? jwtClaims(String? jwt) {
  if (jwt == null) return null;
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    return claims is Map ? claims.cast<String, dynamic>() : null;
  } catch (_) {
    return null;
  }
}
