import 'package:drift/drift.dart';

/// Synchronization metadata storing high-water mark timestamps per table.
@DataClassName('SyncMetaEntry')
class SyncMeta extends Table {
  TextColumn get tableTarget => text().named('table_name')();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();
  DateTimeColumn get lastPushedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {tableTarget};
}
