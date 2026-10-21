import '../../../../core/utils/result.dart';
import '../../../parts/domain/models/part_item.dart';
import '../models/stock_movement_item.dart';

/// Repository contract for ledger-based stock operations.
abstract class StockRepository {
  /// Adds stock (purchases, receipts) for a spare part.
  ///
  /// Increments cached quantity, writes a `purchase` entry in `stock_movements`,
  /// and queues sync records in a single atomic database transaction.
  Future<Result<StockMovementItem>> addStock({
    required String ownerId,
    required String partId,
    required double quantity,
    double? unitCost,
    String? note,
  });

  /// Decrements stock for a spare part.
  ///
  /// Decrements cached quantity, writes an `adjustment` entry with negative change
  /// into `stock_movements`, and queues sync records in a single atomic database transaction.
  /// If [forceAllowNegative] is false and result would be negative, checks the
  /// `allow_negative_stock` app setting.
  Future<Result<StockMovementItem>> removeStock({
    required String ownerId,
    required String partId,
    required double quantity,
    double? unitCost,
    String? note,
    bool forceAllowNegative = false,
  });

  /// Adjusts stock to match a physical count.
  ///
  /// Calculates delta = countedQuantity - currentStock.
  /// Writes an `adjustment` entry with delta into `stock_movements`,
  /// updates cached quantity to countedQuantity, and queues sync records in one transaction.
  Future<Result<StockMovementItem>> adjustStock({
    required String ownerId,
    required String partId,
    required double countedQuantity,
    double? unitCost,
    String? note,
    bool forceAllowNegative = false,
  });

  /// Recalculates cached quantity directly from the append-only stock movement ledger.
  ///
  /// Used for data integrity checks to correct any potential drift in cached_quantity.
  Future<Result<double>> recalculateCachedQuantity({
    required String ownerId,
    required String partId,
  });

  /// Retrieves chronological movement ledger with computed running balances.
  ///
  /// Returns movements ordered by `movedAt` descending (most recent first),
  /// with each item's `runningBalance` accurately computed.
  Future<Result<List<StockMovementItem>>> getMovementsWithBalance({
    required String ownerId,
    required String partId,
  });

  /// Watches chronological movement ledger with computed running balances.
  Stream<List<StockMovementItem>> watchMovementsWithBalance({
    required String ownerId,
    required String partId,
  });

  /// Retrieves list of parts that are at or below their low stock threshold.
  Future<Result<List<PartItem>>> getLowStockParts({
    required String ownerId,
  });

  /// Stream of low stock parts for real-time reactivity.
  Stream<List<PartItem>> watchLowStockParts({
    required String ownerId,
  });

  /// Gets the global setting for whether negative stock is allowed.
  Future<bool> getAllowNegativeStock();

  /// Updates the global setting for whether negative stock is allowed.
  Future<void> setAllowNegativeStock(bool allow);
}
