import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';

/// Progress state for the initial catalog pull on a new or empty phone (Rule 6).
class InitialSyncProgress {
  final int downloaded;
  final int total;
  final bool firstBatchReady;
  final bool isCompleted;

  const InitialSyncProgress({
    required this.downloaded,
    required this.total,
    required this.firstBatchReady,
    required this.isCompleted,
  });
}

/// Service pulling catalog data from backend on first login (Rule 6).
class InitialSyncService {
  final Dio dio;
  final AppDatabase db;

  InitialSyncService({required this.dio, required this.db});

  /// Pulls remote catalog for new or empty phone.
  /// Emits progress and marks [firstBatchReady] = true as soon as the first page is written to Drift.
  Stream<InitialSyncProgress> pullInitialCatalog(String ownerId) async* {
    int downloaded = 0;
    int total = 0;
    const pageSize = 50;
    int offset = 0;

    try {
      // First page request
      final res = await dio.get(
        '/parts',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as List<dynamic>;
        final meta = res.data['meta'] as Map<String, dynamic>?;
        total = meta?['total'] as int? ?? data.length;

        if (data.isEmpty || total == 0) {
          await pullSales(ownerId);
          yield const InitialSyncProgress(
            downloaded: 0,
            total: 0,
            firstBatchReady: true,
            isCompleted: true,
          );
          return;
        }

        await _saveBatchToDrift(data, ownerId);
        downloaded += data.length;

        // Yield first batch ready: app can now immediately navigate to inventory screen!
        yield InitialSyncProgress(
          downloaded: downloaded,
          total: total,
          firstBatchReady: true,
          isCompleted: downloaded >= total,
        );

        offset += pageSize;

        // Pull remaining pages in background
        while (downloaded < total) {
          final nextRes = await dio.get(
            '/parts',
            queryParameters: {'limit': pageSize, 'offset': offset},
          );
          if (nextRes.statusCode != 200 || nextRes.data['success'] != true) {
            break;
          }
          final nextData = nextRes.data['data'] as List<dynamic>;
          if (nextData.isEmpty) break;

          await _saveBatchToDrift(nextData, ownerId);
          downloaded += nextData.length;
          offset += pageSize;

          yield InitialSyncProgress(
            downloaded: downloaded,
            total: total,
            firstBatchReady: true,
            isCompleted: downloaded >= total,
          );
        }

        // Also pull remote sales history into Drift
        await pullSales(ownerId);
      }
    } catch (e) {
      debugPrint('[InitialSyncService] Error during catalog pull: $e');
      yield InitialSyncProgress(
        downloaded: downloaded,
        total: total,
        firstBatchReady: downloaded > 0,
        isCompleted: true,
      );
    }
  }

  Future<void> _saveBatchToDrift(List<dynamic> items, String ownerId) async {
    final companions = items.map((raw) {
      final item = raw as Map<String, dynamic>;
      final id = item['id']?.toString() ?? const Uuid().v4();
      final name = item['name']?.toString() ?? 'Part';
      final partNumber = item['partNumber']?.toString();
      final photoUrl = item['photoUrl']?.toString();
      final brandId = item['brandId']?.toString();
      final categoryId = item['categoryId']?.toString();
      final locationId = item['locationId']?.toString();
      final purchasePrice =
          (item['costPrice'] ?? item['purchasePrice'] as num?)?.toDouble();
      final sellingPrice = (item['sellingPrice'] as num?)?.toDouble();
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final minStock =
          (item['minStock'] ?? item['lowStockLevel'] as num?)?.toDouble() ?? 5.0;

      return SparePartsCompanion.insert(
        id: Value(id),
        ownerId: ownerId,
        name: Value(name),
        partNumber: Value(partNumber),
        photoUrl: Value(photoUrl),
        brandId: Value(brandId),
        categoryId: Value(categoryId),
        locationId: Value(locationId),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        cachedQuantity: Value(quantity),
        lowStockLevel: Value(minStock),
        syncStatus: const Value(SyncStatus.synced),
      );
    }).toList();

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.spareParts, companions);
    });
  }

  /// Pulls remote sales and sale items from backend and persists to local Drift database.
  Future<void> pullSales(String ownerId) async {
    try {
      final res = await dio.get(
        '/sales',
        queryParameters: {'limit': 200, 'offset': 0},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final salesData = res.data['data'] as List<dynamic>? ?? [];
        if (salesData.isEmpty) return;

        final salesCompanions = <SalesCompanion>[];
        final itemsCompanions = <SaleItemsCompanion>[];

        for (final raw in salesData) {
          final s = raw as Map<String, dynamic>;
          final saleId = s['id']?.toString();
          if (saleId == null) continue;

          final soldAt = s['soldAt'] != null
              ? (DateTime.tryParse(s['soldAt'].toString()) ?? DateTime.now())
              : DateTime.now();
          final totalAmount = (s['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final totalProfit = (s['totalProfit'] as num?)?.toDouble() ?? 0.0;
          final receiptNumber = s['receiptNumber']?.toString();
          final paymentMethod = s['paymentMethod']?.toString();
          final notes = s['notes']?.toString();

          salesCompanions.add(
            SalesCompanion.insert(
              id: Value(saleId),
              ownerId: ownerId,
              receiptNumber: Value(receiptNumber),
              soldAt: Value(soldAt),
              subtotal: totalAmount,
              discount: const Value(0.0),
              totalAmount: totalAmount,
              totalProfit: totalProfit,
              paymentMethod: Value(paymentMethod),
              notes: Value(notes),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );

          if (s['items'] is List) {
            for (final rawItem in (s['items'] as List)) {
              final item = rawItem as Map<String, dynamic>;
              final itemId = item['id']?.toString() ?? const Uuid().v4();
              final partId = item['partId']?.toString() ?? '';
              final partNameSnapshot = item['partNameSnapshot']?.toString() ?? 'Part';
              final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
              final unitCost = (item['unitCostSnapshot'] as num?)?.toDouble() ?? 0.0;
              final unitPrice = (item['unitPriceSnapshot'] as num?)?.toDouble() ?? 0.0;
              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? (qty * unitPrice);
              final profit = (item['profit'] as num?)?.toDouble() ?? (subtotal - (qty * unitCost));

              itemsCompanions.add(
                SaleItemsCompanion.insert(
                  id: Value(itemId),
                  ownerId: ownerId,
                  saleId: saleId,
                  partId: partId,
                  partNameSnapshot: partNameSnapshot,
                  quantity: qty,
                  unitCost: unitCost,
                  unitPrice: unitPrice,
                  lineTotal: subtotal,
                  lineProfit: profit,
                  syncStatus: const Value(SyncStatus.synced),
                ),
              );
            }
          }
        }

        await db.batch((batch) {
          batch.insertAllOnConflictUpdate(db.sales, salesCompanions);
          if (itemsCompanions.isNotEmpty) {
            batch.insertAllOnConflictUpdate(db.saleItems, itemsCompanions);
          }
        });
      }
    } catch (e) {
      debugPrint('[InitialSyncService] Error pulling sales: $e');
    }
  }
}
