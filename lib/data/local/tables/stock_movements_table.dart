import 'package:drift/drift.dart';
import 'base_table.dart';
import 'enums.dart';

/// Stock movements ledger table (append-only ledger).
/// Current on-hand stock quantity is the sum of quantity_change.
@TableIndex(name: 'idx_movements_part_id', columns: {#partId})
@DataClassName('StockMovement')
class StockMovements extends Table with SyncedTableMixin {
  TextColumn get partId => text()();
  TextColumn get type => textEnum<MovementType>()();
  RealColumn get quantityChange => real()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get movedAt => dateTime().withDefault(currentDateAndTime)();
}
