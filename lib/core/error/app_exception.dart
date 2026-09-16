/// Sealed hierarchy for every failure that can flow through repositories.
///
/// Repositories return `Result<T, AppException>`. Presentation handles the
/// subtype with a `switch` and renders accordingly.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.cause, super.stackTrace});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.cause, super.stackTrace});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.cause, super.stackTrace});
}

/// 402 — the caller is authenticated and allowed, but the feature is behind a
/// subscription they do not hold.
///
/// Its own type rather than a [ForbiddenException]: "you may not" and "not yet,
/// and here is what to do about it" lead to completely different screens, and a
/// paywall must not be reachable by anything that merely failed authorization.
class PaymentRequiredException extends AppException {
  const PaymentRequiredException(super.message, {super.cause, super.stackTrace});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  });

  final Map<String, List<String>> fieldErrors;
}

class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

class CancelledException extends AppException {
  const CancelledException(super.message, {super.cause, super.stackTrace});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.cause, super.stackTrace});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
