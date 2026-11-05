import 'package:drift/drift.dart';
import 'base_table.dart';
import 'enums.dart';

/// Stock movements ledger table (append-only ledger).
/// Current on-hand stock quantity is the sum of quantity_change.
@TableIndex(name: 'idx_movements_part_id', columns: {#partId})
@TableIndex(name: 'idx_movements_spare_part_id', columns: {#sparePartId})
@TableIndex(name: 'idx_movements_owner_id', columns: {#ownerId})
@TableIndex(name: 'idx_movements_reference_id', columns: {#referenceId})
@TableIndex(name: 'idx_movements_sync_status', columns: {#syncStatus})
@DataClassName('StockMovement')
class StockMovements extends Table with SyncedTableMixin {
  TextColumn get partId => text()();
  TextColumn get sparePartId => text().nullable()();
  TextColumn get type => textEnum<MovementType>()();
  TextColumn get movementType => text().nullable()();
  RealColumn get quantityChange => real()();
  RealColumn get quantityBefore => real().withDefault(const Constant(0.0))();
  RealColumn get quantityAfter => real().withDefault(const Constant(0.0))();
  RealColumn get unitCost => real().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get movedAt => dateTime().withDefault(currentDateAndTime)();
}
