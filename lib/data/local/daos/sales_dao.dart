import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/enums.dart';
import '../tables/sale_items_table.dart';
import '../tables/sales_table.dart';
import '../tables/stock_movements_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, StockMovements])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  /// Atomically records a sale transaction, its line items, and deducts inventory
  /// via the append-only stock_movements ledger.
  Future<void> recordSaleTransaction({
    required SalesCompanion sale,
    required List<SaleItemsCompanion> items,
  }) {
    return transaction(() async {
      // 1. Insert header
      await into(sales).insert(sale);

      // 2. Insert line items & ledger stock deductions
      for (final item in items) {
        await into(saleItems).insert(item);

        // Deduct from ledger (negative quantity)
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            ownerId: item.ownerId.value,
            partId: item.partId.value,
            type: MovementType.sale,
            quantityChange: -item.quantity.value,
            unitCost: Value(item.unitCost.value),
            referenceId: Value(sale.id.value),
            note: Value('Sale receipt #${sale.receiptNumber.value ?? ""}'),
            movedAt: Value(sale.soldAt.value),
          ),
        );
      }
    });
  }

  /// Retrieves active sales for an owner ordered by soldAt descending.
  Future<List<Sale>> getActiveSales(String ownerId) {
    return (select(sales)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.soldAt)]))
        .get();
  }

  /// Watches active sales for an owner.
  Stream<List<Sale>> watchActiveSales(String ownerId) {
    return (select(sales)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.soldAt)]))
        .watch();
  }

  /// Retrieves line items for a sale.
  Future<List<SaleItem>> getSaleItems(String saleId, String ownerId) {
    return (select(saleItems)
          ..where((t) =>
              t.saleId.equals(saleId) &
              t.ownerId.equals(ownerId) &
              t.deletedAt.isNull()))
        .get();
  }

  /// Retrieves sales within a given date range.
  Future<List<Sale>> getSalesByDateRange({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return (select(sales)
          ..where((t) =>
              t.ownerId.equals(ownerId) &
              t.deletedAt.isNull() &
              t.soldAt.isBiggerOrEqualValue(startDate) &
              t.soldAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.desc(t.soldAt)]))
        .get();
  }

  /// Soft deletes a sale and associated sale items.
  Future<void> softDeleteSale(String saleId, String ownerId) {
    final now = DateTime.now();
    return transaction(() async {
      await (update(sales)
            ..where((t) => t.id.equals(saleId) & t.ownerId.equals(ownerId)))
          .write(
        SalesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

      await (update(saleItems)
            ..where((t) =>
                t.saleId.equals(saleId) & t.ownerId.equals(ownerId)))
          .write(
        SaleItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
    });
  }
}
