import '../../../../core/utils/result.dart';
import '../models/sale_line_item.dart';
import '../models/sale_model.dart';

/// Contract for sales recording, transaction processing, and history queries.
abstract class SalesRepository {
  /// Records a new sale in a single database transaction:
  /// 1. Inserts the `sales` header record.
  /// 2. Inserts `sale_items` with snapshot pricing.
  /// 3. Inserts negative `stock_movements` (type `sale`, reference ID linked).
  /// 4. Updates `cached_quantity` on `spare_parts`.
  /// 5. Enqueues all changes to `sync_queue`.
  Future<Result<SaleModel>> createSale({
    required String ownerId,
    required List<SaleLineItem> items,
    String? notes,
    String? paymentMethod,
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

  /// Soft deletes a sale and associated line items.
  Future<Result<void>> deleteSale({
    required String ownerId,
    required String saleId,
  });
}
