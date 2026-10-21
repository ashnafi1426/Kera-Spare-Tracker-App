import 'package:drift/drift.dart';
import 'base_table.dart';

/// Sales transactions header table.
@TableIndex(name: 'idx_sales_sold_at', columns: {#soldAt})
@DataClassName('Sale')
class Sales extends Table with SyncedTableMixin {
  TextColumn get receiptNumber => text().nullable()();
  DateTimeColumn get soldAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  RealColumn get totalProfit => real()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get notes => text().nullable()();
}
