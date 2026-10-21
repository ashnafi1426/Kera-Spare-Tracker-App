import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/local_brands_repository.dart';
import '../../data/repositories/local_categories_repository.dart';
import '../../data/repositories/local_locations_repository.dart';
import '../../domain/models/brand_item.dart';
import '../../domain/models/category_item.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/brands_repository.dart';
import '../../domain/repositories/categories_repository.dart';
import '../../domain/repositories/locations_repository.dart';

/// Provider for BrandsRepository instance.
final brandsRepositoryProvider = Provider<BrandsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalBrandsRepository(db: db);
});

/// Provider for CategoriesRepository instance.
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalCategoriesRepository(db: db);
});

/// Provider for LocationsRepository instance.
final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalLocationsRepository(db: db);
});

/// Current authenticated owner ID for multi-tenant isolation.
final currentOwnerIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(authControllerProvider).value;
  return authUser?.ownerId ?? '';
});

/// Stream of active brands (global defaults + owner's custom brands).
final brandsStreamProvider = StreamProvider<List<BrandItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(brandsRepositoryProvider);
  return repo.watchBrands(ownerId);
});

/// Stream of active categories for the current owner.
final categoriesStreamProvider = StreamProvider<List<CategoryItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchCategories(ownerId);
});

/// Stream of active storage locations (default shelves + owner's custom locations).
final locationsStreamProvider = StreamProvider<List<LocationItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(locationsRepositoryProvider);
  return repo.watchLocations(ownerId);
});
