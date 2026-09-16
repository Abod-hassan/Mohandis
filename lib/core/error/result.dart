/// Explicit success/failure container. Repositories return `Result<T, E>` so
/// callers must handle both branches — no nullable-on-failure, no thrown
/// exceptions crossing the data → presentation boundary.
sealed class Result<T, E> {
  const Result();

  const factory Result.success(T value) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) => switch (this) {
    Success(value: final v) => success(v),
    Failure(error: final e) => failure(e),
  };

  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Success(value: final v) => Result.success(transform(v)),
    Failure(error: final e) => Result.failure(e),
  };

  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async => switch (this) {
    Success(value: final v) => await transform(v),
    Failure(error: final e) => Result.failure(e),
  };
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;
}
