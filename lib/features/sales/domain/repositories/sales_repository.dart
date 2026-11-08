import '../../../../core/utils/result.dart';
import '../models/sale_line_item.dart';
import '../models/sale_model.dart';

/// Contract for sales recording, transaction processing, and history queries.
abstract class SalesRepository {
  /// Records a new sale in a single database transaction:
  /// 1. Validates available quantity locally.
  /// 2. Inserts the `sales` header record (with historical total_cost).
  /// 3. Inserts `sale_items` with historical unit_cost snapshots for profit preservation.
  /// 4. Inserts negative `stock_movements` (type `sale`, reference ID linked).
  /// 5. Reduces `cached_quantity` on `spare_parts`.
  /// 6. Enqueues ONE atomic sale operation to `sync_queue`.
  /// Retry-safe: Calling with an existing [saleId] never reduces stock twice.
  Future<Result<SaleModel>> createSale({
    required String ownerId,
    required List<SaleLineItem> items,
    String? saleId,
    String? notes,
    String? paymentMethod,
    double discount = 0.0,
    bool forceAllowNegative = false,
  });

  /// Retrieves a specific sale and its itemized snapshot lines.
  Future<Result<SaleModel>> getSaleById({
    required String ownerId,
    required String saleId,
  });

  /// Watches all active (non-deleted) sales for an owner ordered by `soldAt` descending.
  Stream<List<SaleModel>> watchActiveSales(String ownerId);

  /// Watches filtered and searched sales for an owner.
  Stream<List<SaleModel>> watchFilteredSales({
    required String ownerId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Processes a sale return/reversal without mutating the immutable original transaction.
  /// Restores stock via positive return ledger movements and enqueues a return operation.
  Future<Result<void>> returnSale({
    required String ownerId,
    required String saleId,
    required String reason,
  });

  /// Soft deletes a sale and associated line items (tombstone).
  Future<Result<void>> deleteSale({
    required String ownerId,
    required String saleId,
  });
}
