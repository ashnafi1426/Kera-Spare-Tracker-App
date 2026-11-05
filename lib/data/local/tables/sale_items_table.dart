import 'package:drift/drift.dart';
import 'base_table.dart';

/// Sale items line items table storing pricing and part name snapshots.
@TableIndex(name: 'idx_sale_items_sale_id', columns: {#saleId})
@TableIndex(name: 'idx_sale_items_part_id', columns: {#partId})
@TableIndex(name: 'idx_sale_items_spare_part_id', columns: {#sparePartId})
@TableIndex(name: 'idx_sale_items_owner_id', columns: {#ownerId})
@DataClassName('SaleItem')
class SaleItems extends Table with SyncedTableMixin {
  TextColumn get serverId => text().nullable()();
  TextColumn get saleId => text()();
  TextColumn get partId => text()();
  TextColumn get sparePartId => text().nullable()();
  TextColumn get partNameSnapshot => text()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
  RealColumn get subtotal => real().nullable()();
  RealColumn get lineProfit => real()();
  RealColumn get profit => real().nullable()();
}
