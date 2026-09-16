import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../storage/token_storage.dart';
import '../request_signing.dart';

/// Adds `X-Request-ID` (uuid v4) and `X-Request-Key` (HMAC-SHA256 signature)
/// to every outgoing request. The signing secret is loaded from secure
/// storage; if it is missing the signature header is omitted so endpoints
/// that don't require signing still work.
class RequestSigningInterceptor extends Interceptor {
  RequestSigningInterceptor({
    required TokenStorage tokenStorage,
    RequestSigner? signer,
    Uuid? uuid,
  }) : _tokens = tokenStorage,
       _signer = signer ?? const RequestSigner(),
       _uuid = uuid ?? const Uuid();

  final TokenStorage _tokens;
  final RequestSigner _signer;
  final Uuid _uuid;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Request-ID'] = _uuid.v4();

    final secret = await _tokens.readSigningSecret();
    if (secret != null && secret.isNotEmpty) {
      options.headers['X-Request-Key'] = _signer.sign(
        secret: secret,
        method: options.method,
        path: options.path,
      );
    }
    handler.next(options);
  }
}
