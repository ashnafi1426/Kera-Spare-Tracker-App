import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/image_service.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/datasources/parts_local_data_source.dart';
import '../../data/repositories/local_parts_repository.dart';
import '../../domain/models/part_item.dart';
import '../../domain/repositories/parts_repository.dart';
import 'metadata_providers.dart';

/// Provider for ImageService instance.
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

/// Provider for PartsRepository instance backed by LocalPartsRepository.
final partsRepositoryProvider = Provider<PartsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalPartsRepository(db: db);
});

/// Stream of all active spare parts for the authenticated owner directly from SQLite.
final partsStreamProvider = StreamProvider<List<PartItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(partsRepositoryProvider);
  return repo.watchActiveParts(ownerId);
});

/// Future provider to fetch a single part by ID directly from SQLite.
final partByIdProvider =
    FutureProvider.family<PartItem?, String>((ref, partId) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(partsRepositoryProvider);
  final result = await repo.getPartById(ownerId: ownerId, id: partId);
  return result.valueOrNull;
});

/// Future provider for local inventory dashboard metrics computed from SQLite.
final localDashboardMetricsProvider =
    FutureProvider.family<InventoryDashboardMetrics?, String>(
        (ref, ownerId) async {
  final repo = ref.watch(partsRepositoryProvider);
  if (repo is LocalPartsRepository) {
    final result = await repo.getLocalDashboardMetrics(ownerId);
    return result.valueOrNull;
  }
  return null;
});
