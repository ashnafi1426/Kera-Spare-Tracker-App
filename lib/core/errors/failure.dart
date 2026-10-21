/// Base failure class representing domain errors across the app.
abstract class Failure {
  final String message;
  final String? code;
  final dynamic cause;

  const Failure({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(message, code);
}

/// Represents an error originating from local SQLite / Drift database.
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Represents an error originating from network or lack of connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code,
    super.cause,
  });
}

/// Represents remote backend or Supabase server errors.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code,
    super.cause,
  });

  @override
  String toString() => 'ServerFailure(message: $message, statusCode: $statusCode, code: $code)';
}

/// Represents authentication and authorization failures.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Represents data validation failures (e.g. invalid phone, negative price).
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Represents a requested resource not being found.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Represents an attempt to reduce stock below zero when not permitted.
class NegativeStockFailure extends Failure {
  final double projectedStock;

  const NegativeStockFailure({
    required super.message,
    required this.projectedStock,
    super.code,
    super.cause,
  });
}

