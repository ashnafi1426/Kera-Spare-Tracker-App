import '../../../../core/utils/result.dart';
import '../models/admin_models.dart';

/// Contract for Admin API operations.
/// Strictly ONLINE ONLY; never reads or touches local Drift tables or sync queues.
abstract class AdminRepository {
  Future<Result<AdminDashboardStats>> getDashboard();

  Future<Result<Map<String, dynamic>>> getOwners({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    int? inactiveDays,
    String? sortBy,
  });

  Future<Result<AdminOwnerDetails>> getOwnerDetails(String ownerId);

  Future<Result<void>> suspendOwner(
    String ownerId, {
    required String reason,
  });

  Future<Result<void>> reactivateOwner(String ownerId);

  Future<Result<Map<String, dynamic>>> resetOwnerPassword(String ownerId);

  Future<Result<void>> updateOwner(
    String ownerId, {
    String? businessName,
    String? phoneNumber,
  });

  Future<Result<void>> disableOwner(
    String ownerId, {
    required String phoneConfirmation,
  });

  // Global Brands
  Future<Result<List<GlobalCatalogItem>>> getBrands();
  Future<Result<GlobalCatalogItem>> createBrand(String name);
  Future<Result<GlobalCatalogItem>> updateBrand(
    String id, {
    String? name,
    bool? isActive,
  });

  // Global Categories
  Future<Result<List<GlobalCatalogItem>>> getCategories();
  Future<Result<GlobalCatalogItem>> createCategory(String name);
  Future<Result<GlobalCatalogItem>> updateCategory(
    String id, {
    String? name,
    bool? isActive,
  });

  // Global Units
  Future<Result<List<GlobalCatalogItem>>> getUnits();
  Future<Result<GlobalCatalogItem>> createUnit(String name);
  Future<Result<GlobalCatalogItem>> updateUnit(
    String id, {
    String? name,
    bool? isActive,
  });

  // App Settings
  Future<Result<dynamic>> getSetting(String key);
  Future<Result<dynamic>> updateSetting(String key, dynamic value);

  // Audit Logs
  Future<Result<Map<String, dynamic>>> getAuditLogs({
    int page = 1,
    int limit = 50,
    String? action,
    String? targetUserId,
    String? adminId,
    String? startDate,
    String? endDate,
  });
}
