import 'package:drift/drift.dart';
import 'enums.dart';

/// Outgoing synchronization queue for changes made offline.
@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableTarget => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get operation => textEnum<SyncOperation>()();
  TextColumn get payload => text()(); // JSON serialized payload
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
