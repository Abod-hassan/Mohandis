import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Attaches `Authorization: Bearer <access>` to outgoing requests and triggers
/// a single-flight refresh on 401. On refresh failure, clears tokens and
/// forwards the 401 so callers can route to login.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Future<bool> Function() refreshAccessToken,
    this.unauthenticatedPaths = const {'/auth/login', '/auth/refresh'},
  }) : _tokens = tokenStorage,
       _refresh = refreshAccessToken;

  final TokenStorage _tokens;
  final Future<bool> Function() _refresh;
  final Set<String> unauthenticatedPaths;

  Future<bool>? _inflight;

  bool _isPublic(RequestOptions options) =>
      unauthenticatedPaths.contains(options.path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options)) {
      final token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status != 401 || _isPublic(err.requestOptions)) {
      return handler.next(err);
    }

    final refreshed = await (_inflight ??= _runRefresh());
    if (!refreshed) {
      await _tokens.clear();
      return handler.next(err);
    }

    try {
      final newToken = await _tokens.readAccessToken();
      final options = err.requestOptions;
      if (newToken != null && newToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $newToken';
      }
      final retried = await Dio(BaseOptions(baseUrl: options.baseUrl))
          .fetch<dynamic>(options);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _runRefresh() async {
    try {
      return await _refresh();
    } finally {
      _inflight = null;
    }
  }
}
