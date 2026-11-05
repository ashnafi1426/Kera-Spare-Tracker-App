import 'package:drift/drift.dart';

/// Synchronization state table storing cursor and sync timestamps per owner.
@TableIndex(name: 'idx_sync_state_owner_id', columns: {#ownerId})
@DataClassName('SyncStateEntry')
class SyncState extends Table {
  TextColumn get ownerId => text()();
  TextColumn get lastPullCursor => text().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {ownerId};
}

