import 'package:drift/drift.dart';
import 'base_table.dart';

/// Sale items line items table storing pricing and part name snapshots.
@TableIndex(name: 'idx_sale_items_sale_id', columns: {#saleId})
@TableIndex(name: 'idx_sale_items_part_id', columns: {#partId})
@DataClassName('SaleItem')
class SaleItems extends Table with SyncedTableMixin {
  TextColumn get saleId => text()();
  TextColumn get partId => text()();
  TextColumn get partNameSnapshot => text()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
  RealColumn get lineProfit => real()();
}
