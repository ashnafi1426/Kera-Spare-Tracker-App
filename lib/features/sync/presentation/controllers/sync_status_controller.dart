import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_monitor.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/services/sync_push_service.dart';

enum SyncUIState {
  idle,
  syncing,
  offline,
  error,
}

class SyncStatusState {
  final SyncUIState status;
  final int pendingCount;
  final bool isOnline;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncStatusState({
    this.status = SyncUIState.idle,
    this.pendingCount = 0,
    this.isOnline = true,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncStatusState copyWith({
    SyncUIState? status,
    int? pendingCount,
    bool? isOnline,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      isOnline: isOnline ?? this.isOnline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

class SyncStatusController extends Notifier<SyncStatusState> {
  StreamSubscription? _onlineSub;
  StreamSubscription? _pendingSub;

  @override
  SyncStatusState build() {
    final monitor = ref.watch(networkMonitorProvider);
    final syncQueueDao = ref.watch(syncQueueDaoProvider);

    _onlineSub?.cancel();
    _onlineSub = monitor.onConnectivityChanged.listen((online) {
      state = state.copyWith(
        isOnline: online,
        status: !online
            ? SyncUIState.offline
            : (state.status == SyncUIState.offline
                ? SyncUIState.idle
                : state.status),
      );
    });

    _pendingSub?.cancel();
    _pendingSub = syncQueueDao.watchCountPending().listen((count) {
      state = state.copyWith(pendingCount: count);
    });

    ref.onDispose(() {
      _onlineSub?.cancel();
      _pendingSub?.cancel();
    });

    return const SyncStatusState();
  }

  Future<bool> triggerSync() async {
    if (!state.isOnline) {
      state = state.copyWith(
        status: SyncUIState.offline,
        lastError: 'No internet connection',
      );
      return false;
    }

    state = state.copyWith(status: SyncUIState.syncing, lastError: null);
    try {
      final pushService = ref.read(syncPushServiceProvider);
      final result = await pushService.pushPendingQueue();

      if (result.isSuccess) {
        state = state.copyWith(
          status: SyncUIState.idle,
          lastSyncedAt: DateTime.now(),
        );
        return true;
      } else {
        state = state.copyWith(
          status: SyncUIState.error,
          lastError: result.failureOrNull?.message ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncUIState.error,
        lastError: e.toString(),
      );
      return false;
    }
  }
}

final syncStatusControllerProvider =
    NotifierProvider<SyncStatusController, SyncStatusState>(
  SyncStatusController.new,
);
