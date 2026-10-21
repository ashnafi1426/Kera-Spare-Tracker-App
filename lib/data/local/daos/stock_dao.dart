import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/stock_movements_table.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockMovements])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  /// Inserts a new stock movement into the ledger.
  Future<int> insertMovement(StockMovementsCompanion movement) {
    return into(stockMovements).insert(movement);
  }

  /// Retrieves all movements for a part ordered by date descending.
  Future<List<StockMovement>> getMovementsForPart(String partId, String ownerId) {
    return (select(stockMovements)
          ..where((t) =>
              t.partId.equals(partId) &
              t.ownerId.equals(ownerId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.movedAt)]))
        .get();
  }

  /// Calculates the on-hand stock by summing all active ledger movements.
  Future<double> calculateStockForPart(String partId, String ownerId) async {
    final sumQuantity = stockMovements.quantityChange.sum();
    final query = selectOnly(stockMovements)
      ..addColumns([sumQuantity])
      ..where(stockMovements.partId.equals(partId) &
          stockMovements.ownerId.equals(ownerId) &
          stockMovements.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(sumQuantity) ?? 0.0;
  }

  /// Watches all movements for a specific part.
  Stream<List<StockMovement>> watchMovementsForPart(
      String partId, String ownerId) {
    return (select(stockMovements)
          ..where((t) =>
              t.partId.equals(partId) &
              t.ownerId.equals(ownerId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.movedAt)]))
        .watch();
  }
}
