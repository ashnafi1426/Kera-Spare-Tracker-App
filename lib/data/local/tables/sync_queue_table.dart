import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

/// Outgoing synchronization queue (outbox) for changes made offline.
@TableIndex(name: 'idx_sync_queue_op_id', columns: {#operationId})
@TableIndex(name: 'idx_sync_queue_owner_id', columns: {#ownerId})
@TableIndex(name: 'idx_sync_queue_status', columns: {#queueStatus})
@TableIndex(name: 'idx_sync_queue_created_at', columns: {#createdAt})
@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId =>
      text().clientDefault(() => const Uuid().v4()).nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get entityType => text().nullable()();
  TextColumn get tableTarget => text().named('table_name')();
  TextColumn get entityId => text().nullable()();
  TextColumn get recordId => text()();
  TextColumn get operationType => text().nullable()();
  TextColumn get operation => textEnum<SyncOperation>()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get payload => text()(); // JSON serialized payload
  TextColumn get dependsOn => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get claimedAt => dateTime().nullable()();
  TextColumn get queueStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
