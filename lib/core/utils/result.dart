import '../errors/failure.dart';

/// A value-or-failure result container for functional error handling.
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result holding [failure].
  const factory Result.failure(Failure failure) = Error<T>;

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is an [Error].
  bool get isFailure => this is Error<T>;

  /// Returns the value if successful, or null if failure.
  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Error() => null,
      };

  /// Returns the failure if failed, or null if success.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Error(failure: final f) => f,
      };

  /// Executes [onSuccess] or [onFailure] based on result state.
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Error(failure: final f) => onFailure(f),
    };
  }

  /// Maps the success value to a new value with [transform].
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(value: final v) => Result.success(transform(v)),
      Error(failure: final f) => Result.failure(f),
    };
  }
}

/// Concrete successful result holding data of type [T].
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Result.success($value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Concrete failure result holding a [Failure].
final class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  String toString() => 'Result.failure($failure)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Error<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}
