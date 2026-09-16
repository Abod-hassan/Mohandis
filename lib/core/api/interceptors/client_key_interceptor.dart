import 'package:dio/dio.dart';

import '../client_key.dart';
import '../request_signing.dart';

/// Adds the `X-KEY` header to every outgoing request.
///
/// `X-KEY` mirrors the backend's `OneWay30SecEncryptor(method, endpoint)`:
/// an HMAC-SHA256 over `window|METHOD|path` (window = unix-epoch-seconds ÷ 30)
/// using the shared client secret [kClientSecretKey]. The backend computes
/// the same value from `_cfg["Jwt:ClientSecretKey"]` and rejects mismatches.
///
/// **Why this exists alongside `X-Request-Key`:**
/// - `X-Request-Key` (from `RequestSigningInterceptor`) uses a **per-device
///   secret** minted by the signing-bootstrap endpoint. It defends against
///   replay across devices and per-device session theft.
/// - `X-KEY` uses a **shared static secret**. It defends against curl /
///   non-mobile clients. Much weaker on its own (the secret ships in the
///   binary), but useful as a fast-rejection check before the more
///   expensive per-device verification runs.
///
/// Both ride the chain unconditionally — even pre-bootstrap requests
/// like `/auth/signing-bootstrap` carry `X-KEY` because the shared secret
/// is compiled in, not provisioned.
class ClientKeyInterceptor extends Interceptor {
  ClientKeyInterceptor({RequestSigner? signer})
      : _signer = signer ?? const RequestSigner();

  final RequestSigner _signer;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['X-KEY'] = _signer.sign(
      secret: kClientSecretKey,
      method: options.method,
      path: options.path,
    );
    handler.next(options);
  }
}
