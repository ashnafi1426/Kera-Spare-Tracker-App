import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../auth/data/repositories/api_auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Comprehensive synchronization outcome summary.
class SyncSummary {
  final int pushedCount;
  final int pulledCount;
  final int photosUploaded;
  final int conflictCount;
  final int failedCount;
  final String? errorMessage;
  final bool isSuccess;

  const SyncSummary({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.photosUploaded = 0,
    this.conflictCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    required this.isSuccess,
  });

  static const SyncSummary emptySuccess = SyncSummary(isSuccess: true);
}

/// Central Coordinator for offline-first two-way synchronization.
/// Guarantees:
/// - Single-flight execution (in-memory lock + DB lease claimed_at)
/// - Network confirmation with GET /health before syncing
/// - Dependency-ordered push (parts before sales & stock movements)
/// - Safe pull without overwriting locally dirty records
/// - Resumable product photo uploads
class SyncCoordinatorService {
  final AppDatabase db;
  final Dio dio;
  final SessionStore sessionStore;
  final NetworkMonitor? networkMonitor;

  static bool _isSyncing = false;

  SyncCoordinatorService({
    required this.db,
    required this.dio,
    required this.sessionStore,
    this.networkMonitor,
  });

  bool get isSyncing => _isSyncing;

  /// Runs a full bidirectional synchronization cycle.
  Future<Result<SyncSummary>> synchronize({
    required String ownerId,
    bool force = false,
  }) async {
    // 1. Single-flight lock (in-memory)
    if (_isSyncing) {
      return const Result.success(
        SyncSummary(
          isSuccess: true,
          errorMessage: 'Sync already in progress; skipped overlapping run.',
        ),
      );
    }

    _isSyncing = true;
    try {
      // 2. Pre-sync Network Confirmation (connectivity + GET /health)
      final hasNet = await _hasActiveConnection();
      if (!hasNet) {
        return const Result.failure(
          NetworkFailure(
            message: 'No active internet connection. Please check Wi-Fi or mobile data.',
            code: 'OFFLINE',
          ),
        );
      }

      final isServerAlive = await _probeServerHealth();
      if (!isServerAlive) {
        return const Result.failure(
          NetworkFailure(
            message: 'Cloud server is starting up or temporarily unreachable. Please try again.',
            code: 'SERVER_UNREACHABLE',
          ),
        );
      }

      int totalPushed = 0;
      int totalPulled = 0;
      int photosUploaded = 0;
      int conflicts = 0;
      int failures = 0;

      // 3. PUSH: Process pending queue in dependency order with DB lease
      final pushResult = await _pushPendingOutbox(ownerId);
      if (pushResult.isFailure) {
        if (pushResult.failureOrNull is AuthFailure) {
          return Result.failure(pushResult.failureOrNull!);
        }
        failures += 1;
      } else {
        totalPushed = pushResult.valueOrNull ?? 0;
      }

      // 4. PULL: Fetch server updates since cursor and apply in ONE transaction
      final pullResult = await _pullServerChanges(ownerId);
      if (pullResult.isSuccess) {
        totalPulled = pullResult.valueOrNull ?? 0;
      } else if (pullResult.isFailure && pushResult.isFailure) {
        return Result.failure(pullResult.failureOrNull!);
      }

      // 5. PHOTOS: Upload pending product photos separately after records are synced
      photosUploaded = await _uploadPendingPhotos(ownerId);

      await sessionStore.recordOnlineActivity();

      return Result.success(
        SyncSummary(
          pushedCount: totalPushed,
          pulledCount: totalPulled,
          photosUploaded: photosUploaded,
          conflictCount: conflicts,
          failedCount: failures,
          isSuccess: failures == 0,
        ),
      );
    } catch (e) {
      return Result.failure(
        SyncFailure(message: 'Sync coordination failed: $e'),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Verifies local network interface
  Future<bool> _hasActiveConnection() async {
    try {
      if (networkMonitor != null) {
        return await networkMonitor!.isOnline();
      }
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none) &&
          connectivity.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  /// Confirms backend is genuinely reachable via GET /health with a fast timeout
  Future<bool> _probeServerHealth() async {
    try {
      final res = await dio
          .get('/health')
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Pushes claimed batches in dependency order (parts -> sales -> stock movements)
  Future<Result<int>> _pushPendingOutbox(String ownerId) async {
    int pushedCount = 0;
    const maxBatches = 20;
    int batchIteration = 0;

    while (batchIteration < maxBatches) {
      // Lease items in SQLite
      final batch = await db.syncQueueDao.claimBatch(limit: 50);
      if (batch.isEmpty) break;
      batchIteration++;

      // Sort in dependency order: spare_parts first, then sales & stock_movements
      final sortedBatch = List<SyncQueueItem>.from(batch)..sort((a, b) {
        if (a.entityType == 'spare_parts' && b.entityType != 'spare_parts') return -1;
        if (a.entityType != 'spare_parts' && b.entityType == 'spare_parts') return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      final payload = sortedBatch.map((item) {
        dynamic parsedData;
        try {
          parsedData = jsonDecode(item.payload);
        } catch (_) {
          parsedData = item.payload;
        }
        return {
          'id': item.recordId,
          'operationId': item.operationId,
          'entity': item.tableTarget,
          'action': item.operationType ?? item.operation.name,
          'data': parsedData,
        };
      }).toList();

      try {
        final response = await dio.post(
          '/sync/push',
          data: {'batch': payload},
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>?;
          final appliedList = data?['applied'] as List<dynamic>? ?? [];

          final appliedMap = <String, String>{};
          for (final a in appliedList) {
            if (a is Map) {
              final id = a['id']?.toString() ?? '';
              final status = a['status']?.toString() ?? 'applied';
              if (id.isNotEmpty) appliedMap[id] = status;
            }
          }

          for (final item in sortedBatch) {
            final status = appliedMap[item.recordId] ?? 'applied';
            if (status == 'applied' || status == 'ok' || status == 'duplicate' || status == 'acknowledged') {
              await db.syncQueueDao.deleteItem(item.id);
              pushedCount++;
            } else if (status == 'error') {
              await db.syncQueueDao.recordAttemptFailure(
                item.id,
                'Server rejected change: ${appliedMap[item.recordId]}',
              );
            }
          }
        } else {
          final errorMsg = response.data?['message']?.toString() ??
              'Server returned unexpected response';
          for (final item in sortedBatch) {
            await db.syncQueueDao.recordAttemptFailure(item.id, errorMsg);
          }
          return Result.failure(ServerFailure(message: errorMsg));
        }
      } on DioException catch (e) {
        final errorMsg = e.response?.data is Map
            ? (e.response!.data['error']?['message']?.toString() ??
                e.response!.data['message']?.toString() ??
                e.message ??
                'Sync push error')
            : (e.message ?? 'Sync push error');

        if (e.response?.statusCode == 401) {
          return const Result.failure(
            AuthFailure(message: 'Authentication session expired. Please sign in again.'),
          );
        }

        for (final item in sortedBatch) {
          await db.syncQueueDao.recordAttemptFailure(item.id, errorMsg);
        }
        return Result.failure(ServerFailure(message: errorMsg));
      }
    }

    return Result.success(pushedCount);
  }

  /// Pulls remote catalog, sales, and movements, safely merging in a single transaction
  Future<Result<int>> _pullServerChanges(String ownerId) async {
    try {
      final syncState = await db.syncQueueDao.getSyncState(ownerId);
      final lastCursor = syncState?.lastPullCursor;

      final res = await dio.get(
        '/sync/pull',
        queryParameters: lastCursor != null ? {'lastPulledAt': lastCursor} : null,
      );

      if (res.statusCode != 200 || res.data['success'] != true) {
        return const Result.success(0);
      }

      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return const Result.success(0);

      final serverTimestamp = data['serverTimestamp'] as String? ?? DateTime.now().toIso8601String();
      final changes = data['changes'] as Map<String, dynamic>? ?? {};

      final parts = changes['parts'] as List<dynamic>? ?? [];
      final sales = changes['sales'] as List<dynamic>? ?? [];
      final movements = changes['stockMovements'] as List<dynamic>? ?? [];

      int appliedPullCount = 0;

      await db.transaction(() async {
        // 1. Merge parts without overwriting dirty local rows
        for (final p in parts) {
          if (p is! Map<String, dynamic>) continue;
          final partId = p['id']?.toString();
          if (partId == null) continue;

          final localPart = await (db.select(db.spareParts)..where((t) => t.id.equals(partId))).getSingleOrNull();

          // Rule: Never overwrite newer unsynced local changes!
          if (localPart != null && localPart.syncStatus != SyncStatus.synced) {
            continue;
          }

          final price = p['sellingPrice'] != null ? double.tryParse(p['sellingPrice'].toString()) : null;
          final cost = p['purchasePrice'] != null ? double.tryParse(p['purchasePrice'].toString()) : null;
          final qty = p['cachedQuantity'] != null ? double.tryParse(p['cachedQuantity'].toString()) ?? 0.0 : 0.0;

          await db.into(db.spareParts).insertOnConflictUpdate(
                SparePartsCompanion(
                  id: Value(partId),
                  ownerId: Value(ownerId),
                  name: Value(p['name']?.toString()),
                  partNumber: Value(p['partNumber']?.toString()),
                  photoUrl: Value(p['photoUrl']?.toString()),
                  brandId: Value(p['brandId']?.toString()),
                  categoryId: Value(p['categoryId']?.toString()),
                  locationId: Value(p['locationId']?.toString()),
                  customLocation: Value(p['customLocation']?.toString()),
                  description: Value(p['description']?.toString()),
                  unit: Value(p['unit']?.toString()),
                  purchasePrice: Value(cost),
                  sellingPrice: Value(price),
                  cachedQuantity: Value(qty),
                  quantity: Value(qty),
                  syncStatus: const Value(SyncStatus.synced),
                  updatedAt: Value(DateTime.tryParse(p['updatedAt']?.toString() ?? '') ?? DateTime.now()),
                ),
              );
          appliedPullCount++;
        }

        // 2. Merge sales
        for (final s in sales) {
          if (s is! Map<String, dynamic>) continue;
          final saleId = s['id']?.toString();
          if (saleId == null) continue;

          final total = double.tryParse(s['totalAmount']?.toString() ?? '0') ?? 0.0;
          final profit = double.tryParse(s['totalProfit']?.toString() ?? '0') ?? 0.0;
          final soldAt = DateTime.tryParse(s['soldAt']?.toString() ?? '') ?? DateTime.now();

          await db.into(db.sales).insertOnConflictUpdate(
                SalesCompanion(
                  id: Value(saleId),
                  ownerId: Value(ownerId),
                  receiptNumber: Value(s['receiptNumber']?.toString() ?? ''),
                  saleNumber: Value(s['receiptNumber']?.toString() ?? ''),
                  totalAmount: Value(total),
                  totalProfit: Value(profit),
                  paymentMethod: Value(s['paymentMethod']?.toString() ?? 'Cash'),
                  soldAt: Value(soldAt),
                  saleDate: Value(soldAt),
                  syncStatus: const Value(SyncStatus.synced),
                  createdAt: Value(soldAt),
                  updatedAt: Value(soldAt),
                ),
              );

          final items = s['items'];
          if (items is List) {
            for (final rawItem in items) {
              if (rawItem is! Map<String, dynamic>) continue;
              final itemId = rawItem['id']?.toString() ?? '${saleId}_${rawItem['partId']}';
              final partId = rawItem['partId']?.toString() ?? '';
              final partNameSnapshot = rawItem['partNameSnapshot']?.toString() ?? 'Item';
              final quantity = double.tryParse(rawItem['quantity']?.toString() ?? '1') ?? 1.0;
              final unitCost = double.tryParse(rawItem['unitCostSnapshot']?.toString() ?? '0') ?? 0.0;
              final unitPrice = double.tryParse(rawItem['unitPriceSnapshot']?.toString() ?? '0') ?? 0.0;
              final subtotal = double.tryParse(rawItem['subtotal']?.toString() ?? '0') ?? (quantity * unitPrice);
              final itemProfit = double.tryParse(rawItem['profit']?.toString() ?? '0') ?? (subtotal - (quantity * unitCost));

              await db.into(db.saleItems).insertOnConflictUpdate(
                SaleItemsCompanion(
                  id: Value(itemId),
                  ownerId: Value(ownerId),
                  saleId: Value(saleId),
                  partId: Value(partId),
                  partNameSnapshot: Value(partNameSnapshot),
                  quantity: Value(quantity),
                  unitCost: Value(unitCost),
                  unitPrice: Value(unitPrice),
                  lineTotal: Value(subtotal),
                  lineProfit: Value(itemProfit),
                  syncStatus: const Value(SyncStatus.synced),
                ),
              );
            }
          }
          appliedPullCount++;
        }

        // 3. Merge stock movements
        for (final m in movements) {
          if (m is! Map<String, dynamic>) continue;
          final movementId = m['id']?.toString();
          final partId = m['partId']?.toString();
          if (movementId == null || partId == null) continue;

          final qty = double.tryParse(m['quantity']?.toString() ?? '0') ?? 0.0;
          final cost = m['unitCost'] != null ? double.tryParse(m['unitCost'].toString()) : null;
          final movedAt = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();

          await db.into(db.stockMovements).insertOnConflictUpdate(
                StockMovementsCompanion(
                  id: Value(movementId),
                  ownerId: Value(ownerId),
                  partId: Value(partId),
                  sparePartId: Value(partId),
                  type: const Value(MovementType.initial),
                  movementType: Value(m['movementType']?.toString() ?? 'adjustment'),
                  quantityChange: Value(qty),
                  unitCost: Value(cost),
                  note: Value(m['reason']?.toString()),
                  referenceId: Value(m['referenceId']?.toString()),
                  syncStatus: const Value(SyncStatus.synced),
                  createdAt: Value(movedAt),
                  updatedAt: Value(movedAt),
                ),
              );
          appliedPullCount++;
        }

        // 4. Advance cursor only after transaction commits successfully
        await db.syncQueueDao.saveSyncCursor(ownerId, serverTimestamp);
      });

      return Result.success(appliedPullCount);
    } catch (e) {
      return Result.failure(SyncFailure(message: 'Pull changes failed: $e'));
    }
  }

  /// Uploads local photos and multi-image inventory queue via resumable multipart POST
  Future<int> _uploadPendingPhotos(String ownerId) async {
    int uploaded = 0;
    try {
      // 1. Process multi-image inventory queue from inventory_images table
      final pendingImages = await db.imagesDao.getPendingUploads(ownerId);
      for (final imgRecord in pendingImages) {
        if (imgRecord.retryCount >= 5) continue;

        final file = File(imgRecord.localFilePath);
        if (!await file.exists()) {
          await db.imagesDao.markUploadFailed(imgRecord.id, 'Local file missing');
          continue;
        }

        await db.imagesDao.markUploading(imgRecord.id);

        try {
          final fileName = imgRecord.localFilePath.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            'images': await MultipartFile.fromFile(file.path, filename: fileName),
          });

          final uploadRes = await dio.post(
            '/spare-parts/${imgRecord.partId}/images',
            data: formData,
          );

          if ((uploadRes.statusCode == 200 || uploadRes.statusCode == 201) && uploadRes.data['success'] == true) {
            final dataList = uploadRes.data['data'];
            if (dataList is List && dataList.isNotEmpty) {
              final remote = dataList[0];
              await db.imagesDao.markUploaded(
                imageId: imgRecord.id,
                remoteImageId: remote['id'] as String,
                remoteImageUrl: remote['imageUrl'] as String,
                thumbnailUrl: remote['thumbnailUrl'] as String?,
              );
              uploaded++;
              continue;
            }
          }

          await db.imagesDao.markUploadFailed(
            imgRecord.id,
            'Upload returned HTTP ${uploadRes.statusCode}',
          );
        } catch (e) {
          await db.imagesDao.markUploadFailed(imgRecord.id, e.toString());
        }
      }

      // 2. Process legacy single-photo spare parts
      final partsWithLocalPhoto = await (db.select(db.spareParts)
            ..where((t) =>
                t.ownerId.equals(ownerId) &
                t.photoLocalPath.isNotNull() &
                (t.photoUrl.isNull() | t.photoUrl.equals(''))))
          .get();

      for (final part in partsWithLocalPhoto) {
        final filePath = part.photoLocalPath;
        if (filePath == null || filePath.isEmpty) continue;

        final file = File(filePath);
        if (!await file.exists()) continue;

        try {
          final fileName = filePath.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            'photo': await MultipartFile.fromFile(filePath, filename: fileName),
          });

          final uploadRes = await dio.post(
            '/parts/${part.id}/photo',
            data: formData,
          );

          if (uploadRes.statusCode == 200 && uploadRes.data['success'] == true) {
            final remoteUrl = uploadRes.data['data']?['photoUrl']?.toString();
            if (remoteUrl != null && remoteUrl.isNotEmpty) {
              await (db.update(db.spareParts)..where((t) => t.id.equals(part.id)))
                  .write(SparePartsCompanion(photoUrl: Value(remoteUrl)));
              uploaded++;
            }
          }
        } catch (_) {
          // File upload failures are retried next cycle without blocking record sync
        }
      }
    } catch (_) {}
    return uploaded;
  }
}

/// Riverpod provider for SyncCoordinatorService
final syncCoordinatorServiceProvider = Provider<SyncCoordinatorService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sessionStore = ref.watch(sessionStoreProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  Dio dioClient;
  if (authRepo is ApiAuthRepository) {
    dioClient = authRepo.dio;
  } else {
    dioClient = Dio();
  }

  return SyncCoordinatorService(
    db: db,
    dio: dioClient,
    sessionStore: sessionStore,
  );
});

