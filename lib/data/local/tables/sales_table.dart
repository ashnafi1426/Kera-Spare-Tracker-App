import 'package:drift/drift.dart';
import 'base_table.dart';

/// Sales transactions header table.
@TableIndex(name: 'idx_sales_sold_at', columns: {#soldAt})
@TableIndex(name: 'idx_sales_sale_date', columns: {#saleDate})
@TableIndex(name: 'idx_sales_owner_id', columns: {#ownerId})
@TableIndex(name: 'idx_sales_server_id', columns: {#serverId})
@TableIndex(name: 'idx_sales_sync_status', columns: {#syncStatus})
@TableIndex(name: 'idx_sales_sale_number', columns: {#saleNumber})
@DataClassName('Sale')
class Sales extends Table with SyncedTableMixin {
  TextColumn get serverId => text().nullable()();
  TextColumn get saleNumber => text().nullable()();
  TextColumn get receiptNumber => text().nullable()();
  DateTimeColumn get soldAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get saleDate => dateTime().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  RealColumn get totalCost => real().withDefault(const Constant(0.0))();
  RealColumn get totalProfit => real()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get notes => text().nullable()();
}
