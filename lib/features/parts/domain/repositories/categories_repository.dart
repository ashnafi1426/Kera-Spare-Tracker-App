import '../../../../core/utils/result.dart';
import '../models/category_item.dart';

/// Abstract contract for spare parts categories.
abstract class CategoriesRepository {
  /// Continuously watches active categories for the given owner.
  Stream<List<CategoryItem>> watchCategories(String ownerId);

  /// Retrieves one-shot snapshot of active categories.
  Future<Result<List<CategoryItem>>> getCategories(String ownerId);

  /// Creates a new category and enqueues sync mutation.
  Future<Result<CategoryItem>> createCategory({
    required String ownerId,
    required String name,
  });

  /// Updates an existing category and enqueues sync mutation.
  Future<Result<CategoryItem>> updateCategory({
    required String ownerId,
    required String id,
    required String name,
  });

  /// Soft deletes a category and enqueues sync delete mutation.
  Future<Result<void>> deactivateCategory({
    required String ownerId,
    required String id,
  });
}
