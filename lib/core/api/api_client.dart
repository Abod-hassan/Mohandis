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
    required Future<bool> Function() refreshAccessToken,
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
    if (dio == null) _allowLoopbackDevCertificate(config);
    this.dio.interceptors.addAll([
      ClientKeyInterceptor(),
      RequestSigningInterceptor(tokenStorage: tokenStorage),
      DeviceHeaderInterceptor(config: config, deviceInfo: deviceInfo),
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshAccessToken: refreshAccessToken,
        // Public paths that must NOT have a bearer attached (and
        // shouldn't trigger a 401-refresh-retry loop). Registration is here
        // for the obvious reason: there is no session yet to attach or
        // refresh, and a 401 from it means bad credentials, not a stale token.
        unauthenticatedPaths: const {
          EndPoints.health,
          EndPoints.authLogin,
          EndPoints.authRefresh,
          EndPoints.authSignUp,
          EndPoints.authRegister,
          EndPoints.contacts,
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
          logPrint: (obj) => debugPrint('[api] $obj'),
        ),
    ]);
  }

  final Dio dio;

  /// Accepts the ASP.NET development certificate — but ONLY for a loopback
  /// host, ONLY in a debug build, and ONLY in the dev environment.
  ///
  /// `dotnet dev-certs https --trust` trusts the certificate on the Mac; the
  /// iOS simulator keeps its own trust store and rejects it anyway, which
  /// otherwise makes every request fail the handshake before it is sent. All
  /// three guards are load-bearing: strip any one of them and a release build
  /// could be talked into trusting a forged certificate.
  void _allowLoopbackDevCertificate(AppConfig config) {
    if (!kDebugMode || !config.environment.isDev) return;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, host, port) =>
            host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2',
    );
  }

  void setAcceptLanguage(String locale) {
    dio.options.headers['Accept-Language'] = locale;
  }
}
