import 'dart:convert';

import 'package:crypto/crypto.dart';

/// HMAC-SHA256 signing for outgoing requests.
///
/// The signed payload is `window|METHOD|path` where `window` is the current
/// epoch second divided by [windowSeconds]. This gives ±[windowSeconds]
/// replay tolerance and lets servers verify the request without clock-perfect
/// synchronisation.
class RequestSigner {
  const RequestSigner({this.windowSeconds = 30});

  final int windowSeconds;

  String sign({
    required String secret,
    required String method,
    required String path,
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final window = ts ~/ windowSeconds;
    final payload = '$window|${method.toUpperCase()}|$path';
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(payload)).toString();
  }
}
