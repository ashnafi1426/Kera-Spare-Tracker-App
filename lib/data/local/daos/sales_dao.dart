import 'package:drift/drift.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/sales_summary.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/top_selling_part.dart';
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

  /// Retrieves filtered and searched sales for an owner ordered by soldAt descending.
  Future<List<Sale>> getFilteredSales({
    required String ownerId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final statement = select(sales);
    statement.where((t) {
      Expression<bool> pred = t.ownerId.equals(ownerId) & t.deletedAt.isNull();
      if (startDate != null) {
        pred = pred & t.soldAt.isBiggerOrEqualValue(startDate);
      }
      if (endDate != null) {
        pred = pred & t.soldAt.isSmallerOrEqualValue(endDate);
      }
      if (query != null && query.trim().isNotEmpty) {
        final clean = '%${query.trim()}%';
        final receiptMatch = t.receiptNumber.like(clean);
        final itemMatch = existsQuery(
          selectOnly(saleItems)
            ..where(
              saleItems.saleId.equalsExp(t.id) &
                  saleItems.ownerId.equals(ownerId) &
                  saleItems.deletedAt.isNull() &
                  saleItems.partNameSnapshot.like(clean),
            ),
        );
        pred = pred & (receiptMatch | itemMatch);
      }
      return pred;
    });
    statement.orderBy([(t) => OrderingTerm.desc(t.soldAt)]);
    return statement.get();
  }

  /// Watches filtered and searched sales for an owner ordered by soldAt descending.
  Stream<List<Sale>> watchFilteredSales({
    required String ownerId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final statement = select(sales);
    statement.where((t) {
      Expression<bool> pred = t.ownerId.equals(ownerId) & t.deletedAt.isNull();
      if (startDate != null) {
        pred = pred & t.soldAt.isBiggerOrEqualValue(startDate);
      }
      if (endDate != null) {
        pred = pred & t.soldAt.isSmallerOrEqualValue(endDate);
      }
      if (query != null && query.trim().isNotEmpty) {
        final clean = '%${query.trim()}%';
        final receiptMatch = t.receiptNumber.like(clean);
        final itemMatch = existsQuery(
          selectOnly(saleItems)
            ..where(
              saleItems.saleId.equalsExp(t.id) &
                  saleItems.ownerId.equals(ownerId) &
                  saleItems.deletedAt.isNull() &
                  saleItems.partNameSnapshot.like(clean),
            ),
        );
        pred = pred & (receiptMatch | itemMatch);
      }
      return pred;
    });
    statement.orderBy([(t) => OrderingTerm.desc(t.soldAt)]);
    return statement.watch();
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

  /// Computes sales count, total revenue, and estimated profit in SQL for a given date range.
  Future<SalesSummary> getSalesSummary({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final countExpr = sales.id.count();
    final revenueExpr = sales.totalAmount.sum();
    final profitExpr = sales.totalProfit.sum();

    final query = selectOnly(sales)
      ..addColumns([countExpr, revenueExpr, profitExpr])
      ..where(
        sales.ownerId.equals(ownerId) &
            sales.deletedAt.isNull() &
            sales.soldAt.isBiggerOrEqualValue(startDate) &
            sales.soldAt.isSmallerOrEqualValue(endDate),
      );

    final row = await query.getSingle();
    return SalesSummary(
      salesCount: row.read(countExpr) ?? 0,
      totalRevenue: row.read(revenueExpr) ?? 0.0,
      totalProfit: row.read(profitExpr) ?? 0.0,
    );
  }

  /// Retrieves the top selling parts ranked by quantity sold using SQL aggregation.
  Future<List<TopSellingPart>> getTopSellingParts({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    final qtySum = saleItems.quantity.sum();
    final revSum = saleItems.lineTotal.sum();

    final query = selectOnly(saleItems)
      ..join([
        innerJoin(sales, sales.id.equalsExp(saleItems.saleId)),
      ])
      ..addColumns([
        saleItems.partId,
        saleItems.partNameSnapshot,
        qtySum,
        revSum,
      ])
      ..where(
        sales.ownerId.equals(ownerId) &
            sales.deletedAt.isNull() &
            saleItems.deletedAt.isNull() &
            (startDate != null
                ? sales.soldAt.isBiggerOrEqualValue(startDate)
                : const Constant(true)) &
            (endDate != null
                ? sales.soldAt.isSmallerOrEqualValue(endDate)
                : const Constant(true)),
      )
      ..groupBy([saleItems.partId, saleItems.partNameSnapshot])
      ..orderBy([OrderingTerm.desc(qtySum)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      return TopSellingPart(
        partId: r.read(saleItems.partId) ?? '',
        partName: r.read(saleItems.partNameSnapshot) ?? '',
        quantitySold: r.read(qtySum) ?? 0.0,
        totalRevenue: r.read(revSum) ?? 0.0,
      );
    }).toList();
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

