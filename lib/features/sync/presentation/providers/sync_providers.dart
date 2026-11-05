import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/services/sync_coordinator_service.dart';
import '../../data/services/sync_push_service.dart';
import '../../domain/models/sync_conflict_model.dart';

/// Live stream of all pending synchronization queue items from SQLite.
final syncQueueItemsStreamProvider =
    StreamProvider<List<SyncQueueItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.syncQueue)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
});

/// Live stream of pending sync count.
final pendingSyncCountStreamProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.watchCountPending();
});

/// Live stream of network connectivity status.
final isOnlineStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none) && initial.isNotEmpty;

  yield* connectivity.onConnectivityChanged.map(
    (results) =>
        !results.contains(ConnectivityResult.none) && results.isNotEmpty,
  );
});

/// State of a manual sync push execution.
class SyncPushState {
  final bool isPushing;
  final int lastSyncedCount;
  final String? lastError;
  final DateTime? lastSyncedAt;

  const SyncPushState({
    this.isPushing = false,
    this.lastSyncedCount = 0,
    this.lastError,
    this.lastSyncedAt,
  });

  SyncPushState copyWith({
    bool? isPushing,
    int? lastSyncedCount,
    String? lastError,
    DateTime? lastSyncedAt,
  }) {
    return SyncPushState(
      isPushing: isPushing ?? this.isPushing,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      lastError: lastError,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Controller managing background and manual sync pushes.
class SyncPushController extends Notifier<SyncPushState> {
  @override
  SyncPushState build() => const SyncPushState();

  Future<bool> pushNow() async {
    state = state.copyWith(isPushing: true, lastError: null);
    try {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final coordinator = ref.read(syncCoordinatorServiceProvider);
        final res = await coordinator.synchronize(ownerId: user.id);
        if (res.isSuccess) {
          state = state.copyWith(
            isPushing: false,
            lastSyncedCount: (res.valueOrNull?.pushedCount ?? 0) +
                (res.valueOrNull?.pulledCount ?? 0),
            lastSyncedAt: DateTime.now(),
          );
          return true;
        } else {
          state = state.copyWith(
            isPushing: false,
            lastError: res.failureOrNull?.message ?? 'Sync failed',
          );
          return false;
        }
      }

      final service = ref.read(syncPushServiceProvider);
      final result = await service.pushPendingQueue();

      if (result.isSuccess) {
        state = state.copyWith(
          isPushing: false,
          lastSyncedCount: result.valueOrNull ?? 0,
          lastSyncedAt: DateTime.now(),
        );
        return true;
      } else {
        state = state.copyWith(
          isPushing: false,
          lastError: result.failureOrNull?.message ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isPushing: false,
        lastError: e.toString(),
      );
      return false;
    }
  }
}

final syncPushControllerProvider =
    NotifierProvider<SyncPushController, SyncPushState>(
  SyncPushController.new,
);

/// State notifier managing active conflicts detected during synchronization.
class ConflictsNotifier extends Notifier<List<SyncConflictModel>> {
  @override
  List<SyncConflictModel> build() {
    // Seed sample conflict matching Stitch Screen 2 for testing & demonstration
    return [
      SyncConflictModel(
        id: 'CONF-001',
        partId: 'part-caterpillar-oil-filter',
        partName: 'CAT 320D Oil Filter (የካተርፒላር ዘይት ማጣሪያ)',
        oemNumber: '1R-0716',
        shelfLocation: 'Shelf A-04 / መደርደሪያ ሀ-04',
        localPrice: 3850.0,
        serverPrice: 4100.0,
        localStock: 18.0,
        serverStock: 22.0,
        localUpdatedBy: 'Ato Tesfaye (Local Device)',
        serverUpdatedBy: 'Head Office Admin (Cloud)',
        detectedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  void resolveConflict(String id, ConflictResolutionStrategy strategy) {
    state = state.where((c) => c.id != id).toList();
  }

  void addConflict(SyncConflictModel conflict) {
    state = [...state, conflict];
  }
}

final activeConflictsProvider =
    NotifierProvider<ConflictsNotifier, List<SyncConflictModel>>(
  ConflictsNotifier.new,
);

