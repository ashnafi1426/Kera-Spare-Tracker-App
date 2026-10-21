import '../../../../core/utils/result.dart';
import '../models/brand_item.dart';

/// Abstract contract for spare parts brands.
abstract class BrandsRepository {
  /// Continuously watches brands (both global and tenant owner's custom brands).
  Stream<List<BrandItem>> watchBrands(String ownerId);

  /// Retrieves one-shot snapshot of active brands.
  Future<Result<List<BrandItem>>> getBrands(String ownerId);

  /// Creates a new custom brand and enqueues sync mutation.
  Future<Result<BrandItem>> createBrand({
    required String ownerId,
    required String name,
  });

  /// Updates an existing custom brand and enqueues sync mutation.
  Future<Result<BrandItem>> updateBrand({
    required String ownerId,
    required String id,
    required String name,
  });

  /// Soft deletes an owner's brand and enqueues sync delete mutation.
  Future<Result<void>> deactivateBrand({
    required String ownerId,
    required String id,
  });
}
