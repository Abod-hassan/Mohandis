import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'endpoints.dart';
import '../services/device_info_service.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/client_key_interceptor.dart';
import 'interceptors/device_header_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/request_signing_interceptor.dart';
import 'log_redaction.dart';
import 'token_refresher.dart';

/// Single Dio instance for the app. Every repository talks to the network
/// through `apiClientProvider`'s [dio] — no other Dio instances anywhere.
///
/// Interceptors are chained in a fixed order:
///   1. `ClientKeyInterceptor`      — adds X-KEY (shared-secret bot deterrent)
///   2. `RequestSigningInterceptor` — adds X-Request-ID + X-Request-Key
///   3. `DeviceHeaderInterceptor`   — adds device + app metadata
///   4. `AuthInterceptor`           — adds bearer token, handles 401 refresh
///   5. `ErrorMappingInterceptor`   — maps DioException → AppException
///   6. `LogInterceptor` (debug only)
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    required DeviceInfoService deviceInfo,
    required Future<RefreshOutcome> Function() refreshAccessToken,
    void Function()? onSessionExpired,
    Dio? dio,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.apiBaseUrl,
                connectTimeout: config.connectTimeout,
                receiveTimeout: config.receiveTimeout,
                contentType: 'application/json',
                responseType: ResponseType.json,
              ),
            ) {
    // Only for the Dio this class created. An injected one (tests) brings its
    // own adapter, and replacing it would route the test suite at the network.
    if (dio == null) {
      final adapter = loopbackDevAdapter(config);
      if (adapter != null) this.dio.httpClientAdapter = adapter;
    }
    this.dio.interceptors.addAll([
      ClientKeyInterceptor(),
      RequestSigningInterceptor(tokenStorage: tokenStorage),
      DeviceHeaderInterceptor(config: config, deviceInfo: deviceInfo),
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshAccessToken: refreshAccessToken,
        onSessionExpired: onSessionExpired,
        retry: _retryClient(config, tokenStorage).fetch<dynamic>,
        // Public paths that must NOT have a bearer attached (and
        // shouldn't trigger a 401-refresh-retry loop). Registration is here
        // for the obvious reason: there is no session yet to attach or
        // refresh, and a 401 from it means bad credentials, not a stale token.
        unauthenticatedPaths: const {
          EndPoints.health,
          EndPoints.authLogin,
          EndPoints.authRefresh,
          EndPoints.authRegister,
          EndPoints.contacts,
          // Registration's prove-an-identity half. All anonymous by design, so
          // a 401 from one of them says nothing about anybody's session — and
          // Exists fires on every keystroke, which is the last thing that
          // should be able to sign a person out.
          //
          // CreateWithContact is deliberately NOT here: its bearer is the
          // registration token, and it is the one call in this flow that is
          // meant to carry one.
          EndPoints.authExists,
          EndPoints.authGenerateOtp,
          EndPoints.authValidateOtp,
          EndPoints.authEmailSendCode,
          EndPoints.authEmailVerifyCode,
        },
      ),
      ErrorMappingInterceptor(),
      if (kDebugMode && config.enableLogging)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          // On in debug: X-Tenant-Id, the bearer and X-KEY all ride here, and
          // a header that silently failed to attach is invisible without it.
          requestHeader: true,
          responseHeader: false,
          logPrint: (obj) => debugPrint(redactSecrets('[api] $obj')),
        ),
    ]);
  }

  final Dio dio;

  /// Where a request goes the second time, after its token was refreshed.
  ///
  /// NOT [dio]. `AuthInterceptor` is a `QueuedInterceptor`, so its error
  /// handlers run one at a time: a retry sent back through [dio] that failed
  /// again would queue its own `onError` behind the handler that is waiting
  /// for it, and neither would ever finish. A second Dio without the auth
  /// interceptor cannot deadlock and cannot loop.
  ///
  /// It is not bare, though, and that was the old retry's real problem. It
  /// re-signs X-KEY — a 30-second HMAC window that a slow refresh can
  /// straddle, and the stale signature was copied over verbatim — it maps
  /// errors like every other request, and it carries the loopback
  /// certificate allowance, without which a retry against the dev API failed
  /// its TLS handshake even when the refresh itself had worked. The device
  /// headers are already on the options from the first attempt.
  static Dio _retryClient(AppConfig config, TokenStorage tokenStorage) {
    final retry = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
      ),
    );
    final adapter = loopbackDevAdapter(config);
    if (adapter != null) retry.httpClientAdapter = adapter;
    retry.interceptors.addAll([
      ClientKeyInterceptor(),
      // X-Request-Key is the same kind of 30-second window as X-KEY, and
      // goes stale across a slow refresh for the same reason.
      RequestSigningInterceptor(tokenStorage: tokenStorage),
      ErrorMappingInterceptor(),
      if (kDebugMode && config.enableLogging)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(redactSecrets('[api:retry] $obj')),
        ),
    ]);
    return retry;
  }

  void setAcceptLanguage(String locale) {
    dio.options.headers['Accept-Language'] = locale;
  }
}

/// An adapter that accepts the ASP.NET development certificate — but ONLY for
/// a loopback host, ONLY in a debug build, and ONLY in the dev environment.
/// Null everywhere else, meaning "use the platform default".
///
/// `dotnet dev-certs https --trust` trusts the certificate on the Mac; the iOS
/// simulator keeps its own trust store and rejects it anyway, which otherwise
/// makes every request fail the handshake before it is sent. All three guards
/// are load-bearing: strip any one of them and a release build could be
/// talked into trusting a forged certificate.
///
/// Top-level rather than private to [ApiClient] because EVERY Dio in the app
/// needs the same answer. The token refresher owns a second, bare Dio, and
/// when only the main one had this, every refresh against the dev API failed
/// its TLS handshake — which the old refresher reported as "refresh failed"
/// and the interceptor answered by signing the person out. On localhost, an
/// expired access token was a guaranteed logout.
HttpClientAdapter? loopbackDevAdapter(AppConfig config) {
  if (!kDebugMode || !config.environment.isDev) return null;
  return IOHttpClientAdapter(
    createHttpClient: () => HttpClient()
      ..badCertificateCallback = (cert, host, port) =>
          host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2',
  );
}
