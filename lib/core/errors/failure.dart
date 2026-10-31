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

/// Constant code for when the device has connectivity but the backend server is unreachable.
const String kServerUnreachableCode = 'SERVER_UNREACHABLE';

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

/// Represents an attempt to register or login while offline.
class OfflineInternetRequiredFailure extends Failure {
  const OfflineInternetRequiredFailure({
    super.message = 'Internet is required to register or log in.',
    super.code = 'NO_INTERNET',
    super.cause,
  });
}

/// Represents an account conflict when a different owner tries to log in
/// while unsynced local mutations exist on this device.
class DifferentOwnerConflictFailure extends Failure {
  final String previousOwnerId;
  final String previousOwnerName;

  const DifferentOwnerConflictFailure({
    required this.previousOwnerId,
    required this.previousOwnerName,
    super.message =
        'Another account has unsynced changes on this phone. Sync or discard them first.',
    super.code = 'DIFFERENT_OWNER_CONFLICT',
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

/// Represents synchronization errors during batch push or catalog pull.
class SyncFailure extends Failure {
  const SyncFailure({
    required super.message,
    super.code,
    super.cause,
  });
}