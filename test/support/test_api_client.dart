import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/config/app_config.dart';
import 'package:flutter_mobile_template/core/config/environment.dart';
import 'package:flutter_mobile_template/core/services/device_info_service.dart';
import 'package:flutter_mobile_template/core/storage/token_storage.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

/// Adapter that answers every request from [handler] instead of the network.
/// ARCHITECTURE.md §15.7 — no test ever touches the real network.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);
}

ResponseBody jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Builds a real [ApiClient] — full interceptor chain included, so error
/// mapping is exercised — wired to a stubbed transport.
ApiClient buildTestApiClient({
  required Future<ResponseBody> Function(RequestOptions options) onRequest,
}) {
  final tokens = MockTokenStorage();
  final device = MockDeviceInfoService();

  when(tokens.readAccessToken).thenAnswer((_) async => 'test-access-token');
  when(tokens.readRefreshToken).thenAnswer((_) async => 'test-refresh-token');
  when(tokens.readSigningSecret).thenAnswer((_) async => null);
  when(tokens.clear).thenAnswer((_) async {});

  when(device.deviceSerial).thenAnswer((_) async => 'test-serial');
  when(device.osDescriptor).thenAnswer((_) async => 'test-os');
  when(device.osVersion).thenAnswer((_) async => '1.0');
  when(device.appVersion).thenAnswer((_) async => '0.1.0+1');
  when(device.timezone).thenReturn('Asia/Riyadh');

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.test',
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  )..httpClientAdapter = FakeHttpAdapter(onRequest);

  return ApiClient(
    config: const AppConfig(
      environment: Environment.dev,
      apiBaseUrl: 'https://api.test',
      appName: 'test',
      enableLogging: false,
    ),
    tokenStorage: tokens,
    deviceInfo: device,
    refreshAccessToken: () async => false,
    dio: dio,
  );
}
