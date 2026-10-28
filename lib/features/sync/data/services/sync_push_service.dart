import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Service responsible for pushing locally queued mutations to the backend server.
class SyncPushService {
  final AppDatabase db;
  final Dio dio;
  final SessionStore sessionStore;

  SyncPushService({
    required this.db,
    required this.dio,
    required this.sessionStore,
  });

  /// Pushes all pending queue items in batches of 50 to the remote server.
  /// Deletes items from the syncQueue only upon confirmed server synchronization.
  /// If sync fails at any point, halts and returns the failure without deleting pending items.
  Future<Result<int>> pushPendingQueue({int maxBatches = 20}) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.isEmpty ||
          connectivity.contains(ConnectivityResult.none)) {
        return const Result.failure(
          NetworkFailure(
            message: 'No internet connection to synchronize pending data.',
            code: 'NO_INTERNET',
          ),
        );
      }
    } catch (_) {}

    int totalSynced = 0;
    int batchesCount = 0;

    try {
      while (batchesCount < maxBatches) {
        final batch = await db.syncQueueDao.getPendingBatch(limit: 50);
        if (batch.isEmpty) break;

        batchesCount++;

        final payload = batch.map((item) {
          dynamic parsedData;
          try {
            parsedData = jsonDecode(item.payload);
          } catch (_) {
            parsedData = item.payload;
          }
          return {
            'id': item.recordId,
            'entity': item.tableTarget,
            'action': item.operation.name,
            'data': parsedData,
          };
        }).toList();

        final response = await dio.post(
          '/sync/push',
          data: {'batch': payload},
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          for (final item in batch) {
            await db.syncQueueDao.deleteItem(item.id);
          }
          totalSynced += batch.length;
          await sessionStore.recordOnlineActivity();
        } else {
          final errorMsg = response.data?['message']?.toString() ??
              'Server returned error during sync';
          for (final item in batch) {
            await db.syncQueueDao.recordAttemptFailure(item.id, errorMsg);
          }
          return Result.failure(
            ServerFailure(message: errorMsg, statusCode: response.statusCode),
          );
        }
      }

      return Result.success(totalSynced);
    } on DioException catch (e) {
      final errorMsg = e.response?.data is Map
          ? (e.response!.data['error']?['message']?.toString() ??
              e.response!.data['message']?.toString() ??
              e.message ??
              'Sync network error')
          : (e.message ?? 'Sync network error');

      return Result.failure(
        NetworkFailure(
          message: errorMsg,
          code: e.response?.statusCode == 403
              ? 'ACCOUNT_SUSPENDED'
              : 'SYNC_NETWORK_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        SyncFailure(message: 'Sync push failed: ${e.toString()}'),
      );
    }
  }
}

/// Provider exposing SyncPushService.
final syncPushServiceProvider = Provider<SyncPushService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sessionStore = ref.watch(sessionStoreProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  Dio dioClient;
  if (authRepo is ApiAuthRepository) {
    dioClient = authRepo.dio;
  } else {
    dioClient = Dio();
  }

  return SyncPushService(
    db: db,
    dio: dioClient,
    sessionStore: sessionStore,
  );
});
