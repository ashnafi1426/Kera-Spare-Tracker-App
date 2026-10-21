import '../../../../core/utils/result.dart';
import '../models/inventory_filter.dart';
import '../models/paged_result.dart';
import '../models/part_item.dart';

/// Abstract contract for spare parts inventory operations.
abstract class PartsRepository {
  /// Continuously watches active spare parts for the specified owner.
  Stream<List<PartItem>> watchActiveParts(String ownerId);

  /// Retrieves one-shot list of active spare parts for an owner.
  Future<Result<List<PartItem>>> getActiveParts(String ownerId);

  /// Retrieves a single part by ID for the owner.
  Future<Result<PartItem>> getPartById({
    required String ownerId,
    required String id,
  });

  /// Creates a new spare part.
  /// If [initialQuantity] is provided (> 0), atomically logs an initial stock movement
  /// and updates [cachedQuantity] in the same database transaction.
  /// Enqueues offline mutation(s) to sync_queue.
  Future<Result<PartItem>> createPart({
    required String ownerId,
    String? name,
    String? partNumber,
    String? photoLocalPath,
    String? photoUrl,
    String? brandId,
    String? categoryId,
    String? locationId,
    String? customLocation,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? sizeSpecs,
    String? notes,
    double? lowStockLevel,
    double? initialQuantity,
  });

  /// Updates an existing spare part. Enqueues update mutation to sync_queue.
  Future<Result<PartItem>> updatePart({
    required String ownerId,
    required String id,
    String? name,
    String? partNumber,
    String? photoLocalPath,
    String? photoUrl,
    String? brandId,
    String? categoryId,
    String? locationId,
    String? customLocation,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? sizeSpecs,
    String? notes,
    double? lowStockLevel,
  });

  /// Soft deletes a spare part by setting deleted_at timestamp.
  /// Past sales records and ledger movements remain valid.
  /// Enqueues delete mutation to sync_queue.
  Future<Result<void>> deletePart({
    required String ownerId,
    required String id,
  });

  /// Retrieves a paginated list of parts matching the filter, search query, and sort criteria.
  Future<Result<PagedResult<PartItem>>> getPagedParts({
    required String ownerId,
    InventoryFilter filter = const InventoryFilter(),
    int limit = 50,
    int offset = 0,
  });

  /// Seeds [count] realistic spare parts for the current owner in a single batch.
  Future<Result<int>> seedTestParts({
    required String ownerId,
    int count = 2000,
  });

  /// Clears all seeded test parts for the current owner.
  Future<Result<int>> clearTestParts(String ownerId);
}
