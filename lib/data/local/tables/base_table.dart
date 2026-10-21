import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

/// Common mixin for all multi-tenant tables that synchronize with Supabase.
mixin SyncedTableMixin on Table {
  /// UUID primary key generated on device.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Tenant owner ID ensuring complete data isolation between owners.
  TextColumn get ownerId => text()();

  /// Timestamp when the record was created locally.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when the record was last modified.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete timestamp (null if active, timestamp when deleted).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Sync lifecycle state: pending, synced, or failed.
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.name))();

  @override
  Set<Column> get primaryKey => {id};
}
