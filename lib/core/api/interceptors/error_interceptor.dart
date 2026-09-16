import 'package:dio/dio.dart';

import '../../error/app_exception.dart';

/// Maps `DioException` to the `AppException` hierarchy so repositories don't
/// have to inspect raw Dio error types.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _map(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }

  AppException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          err.message ?? 'Request timed out',
          cause: err,
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return NetworkException(
          err.message ?? 'Network error',
          cause: err,
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.cancel:
        return CancelledException(
          err.message ?? 'Request cancelled',
          cause: err,
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.badResponse:
        return _fromStatus(err);
      case DioExceptionType.unknown:
      // ignore: deprecated_member_use — Dio 5.x uses `unknown`; older
      // channels still emit `transformTimeout` as a distinct value.
      // ignore: unreachable_switch_default
      default:
        return UnknownException(
          err.message ?? 'Unknown error',
          cause: err,
          stackTrace: err.stackTrace,
        );
    }
  }

  AppException _fromStatus(DioException err) {
    final status = err.response?.statusCode ?? 0;
    final body = err.response?.data;
    final message = _extractMessage(body) ?? 'Request failed ($status)';

    return switch (status) {
      401 => UnauthorizedException(
        message,
        cause: err,
        stackTrace: err.stackTrace,
      ),
      403 => ForbiddenException(
        message,
        cause: err,
        stackTrace: err.stackTrace,
      ),
      402 => PaymentRequiredException(
        message,
        cause: err,
        stackTrace: err.stackTrace,
      ),
      404 => NotFoundException(
        message,
        cause: err,
        stackTrace: err.stackTrace,
      ),
      422 => ValidationException(
        message,
        fieldErrors: _extractFieldErrors(body),
        cause: err,
        stackTrace: err.stackTrace,
      ),
      _ => ServerException(
        message,
        statusCode: status,
        cause: err,
        stackTrace: err.stackTrace,
      ),
    };
  }

  String? _extractMessage(Object? body) {
    if (body is Map) {
      final m = body['message'] ?? body['error'] ?? body['detail'];
      if (m is String) return m;
    }
    return null;
  }

  Map<String, List<String>> _extractFieldErrors(Object? body) {
    if (body is! Map) return const {};
    final errors = body['errors'];
    if (errors is! Map) return const {};
    final out = <String, List<String>>{};
    errors.forEach((key, value) {
      if (key is String && value is List) {
        out[key] = value.whereType<String>().toList();
      }
    });
    return out;
  }
}
