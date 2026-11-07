import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_monitor.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/services/sync_coordinator_service.dart';
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
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  SyncStatusState build() {
    final monitor = ref.watch(networkMonitorProvider);
    final syncQueueDao = ref.watch(syncQueueDaoProvider);

    _onlineSub?.cancel();
    _onlineSub = monitor.onConnectivityChanged.listen((online) {
      final wasOffline = !state.isOnline;
      state = state.copyWith(
        isOnline: online,
        status: !online
            ? SyncUIState.offline
            : (state.status == SyncUIState.offline
                ? SyncUIState.idle
                : state.status),
      );

      // Automated silent sync loop:
      // When network switches from offline to online, or reconnects with pending mutations
      if (online && (wasOffline || state.pendingCount > 0)) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          triggerSync(silent: true);
        });
      }
    });

    _pendingSub?.cancel();
    _pendingSub = syncQueueDao.watchCountPending().listen((count) {
      state = state.copyWith(pendingCount: count);
    });

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _onlineSub?.cancel();
      _pendingSub?.cancel();
    });

    return const SyncStatusState();
  }

  /// Triggers a synchronization cycle.
  /// If [silent] is true, errors are logged quietly without alerting the UI.
  /// If [silent] is false, UI state transitions to syncing/error with snackbar feedback.
  Future<bool> triggerSync({bool silent = false}) async {
    if (_isProcessing) return false;
    _isProcessing = true;

    if (!state.isOnline) {
      _isProcessing = false;
      if (!silent) {
        state = state.copyWith(
          status: SyncUIState.offline,
          lastError: 'No internet connection. Changes safely preserved in local offline cache.',
        );
      }
      return false;
    }

    if (!silent) {
      state = state.copyWith(status: SyncUIState.syncing, lastError: null);
    }

    try {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final coordinator = ref.read(syncCoordinatorServiceProvider);
        final res = await coordinator.synchronize(ownerId: user.id);
        if (res.isSuccess) {
          state = state.copyWith(
            status: SyncUIState.idle,
            lastSyncedAt: DateTime.now(),
            lastError: null,
          );
          return true;
        } else {
          state = state.copyWith(
            status: silent ? SyncUIState.idle : SyncUIState.error,
            lastError: res.failureOrNull?.message ?? 'Sync failed',
          );
          return false;
        }
      }

      final pushService = ref.read(syncPushServiceProvider);
      final result = await pushService.pushPendingQueue();

      if (result.isSuccess) {
        state = state.copyWith(
          status: SyncUIState.idle,
          lastSyncedAt: DateTime.now(),
          lastError: null,
        );
        return true;
      } else {
        state = state.copyWith(
          status: silent ? SyncUIState.idle : SyncUIState.error,
          lastError: result.failureOrNull?.message ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: silent ? SyncUIState.idle : SyncUIState.error,
        lastError: e.toString(),
      );
      return false;
    } finally {
      _isProcessing = false;
    }
  }
}

final syncStatusControllerProvider =
    NotifierProvider<SyncStatusController, SyncStatusState>(
  SyncStatusController.new,
);
