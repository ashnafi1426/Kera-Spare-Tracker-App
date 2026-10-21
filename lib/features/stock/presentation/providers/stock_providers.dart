import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database_provider.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../data/repositories/local_stock_repository.dart';
import '../../domain/models/stock_movement_item.dart';
import '../../domain/repositories/stock_repository.dart';

/// Provider for StockRepository instance.
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalStockRepository(db: db);
});

/// Stream of stock movement ledger entries for a part with running balances.
final partMovementsStreamProvider =
    StreamProvider.family<List<StockMovementItem>, String>((ref, partId) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchMovementsWithBalance(ownerId: ownerId, partId: partId);
});

/// Stream of low stock parts for the authenticated owner.
final lowStockPartsStreamProvider = StreamProvider<List<PartItem>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchLowStockParts(ownerId: ownerId);
});

/// Notifier for the global Allow Negative Stock setting.
class AllowNegativeStockNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(stockRepositoryProvider);
    return repo.getAllowNegativeStock();
  }

  Future<void> toggle(bool allow) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(stockRepositoryProvider);
      await repo.setAllowNegativeStock(allow);
      return allow;
    });
  }
}

final allowNegativeStockNotifierProvider =
    AsyncNotifierProvider<AllowNegativeStockNotifier, bool>(
  AllowNegativeStockNotifier.new,
);
