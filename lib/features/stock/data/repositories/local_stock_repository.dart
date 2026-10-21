import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../domain/models/stock_movement_item.dart';
import '../../domain/repositories/stock_repository.dart';

/// Local SQLite Drift-backed implementation of [StockRepository].
///
/// Implements the append-only ledger pattern:
/// - Quantities are never mutated in isolation; every change writes a `stock_movements` record.
/// - The `cached_quantity` on `spare_parts` is maintained atomically within the same transaction.
/// - Every movement is enqueued to `sync_queue` for seamless cloud synchronization.
class LocalStockRepository implements StockRepository {
  final AppDatabase db;
  final Uuid uuid;

  static const String settingAllowNegativeStock = 'allow_negative_stock';

  LocalStockRepository({
    required this.db,
    this.uuid = const Uuid(),
  });

  @override
  Future<Result<StockMovementItem>> addStock({
    required String ownerId,
    required String partId,
    required double quantity,
    double? unitCost,
    String? note,
  }) async {
    if (quantity <= 0) {
      return const Result.failure(
        ValidationFailure(message: 'Quantity to add must be greater than zero'),
      );
    }

    try {
      final part = await db.partsDao.getPartById(partId, ownerId);
      if (part == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Spare part not found'),
        );
      }

      final movementId = uuid.v4();
      final now = DateTime.now();
      final currentStock = part.cachedQuantity ?? 0.0;
      final newStock = currentStock + quantity;

      final movement = await db.transaction(() async {
        // 1. Insert into stock_movements ledger
        await db.into(db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: Value(movementId),
                ownerId: ownerId,
                partId: partId,
                type: MovementType.purchase,
                quantityChange: quantity,
                unitCost: Value(unitCost ?? part.purchasePrice),
                note: Value(note?.trim()),
                movedAt: Value(now),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // 2. Update spare_parts cached_quantity
        await (db.update(db.spareParts)..where((t) => t.id.equals(partId))).write(
          SparePartsCompanion(
            cachedQuantity: Value(newStock),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        // 3. Enqueue stock movement creation to sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'stock_movements',
          recordId: movementId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': movementId,
            'owner_id': ownerId,
            'part_id': partId,
            'type': MovementType.purchase.name,
            'quantity_change': quantity,
            'unit_cost': unitCost ?? part.purchasePrice,
            'note': note?.trim(),
            'moved_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
          }),
        );

        // 4. Enqueue spare part cached quantity update to sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: partId,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'cached_quantity': newStock,
            'updated_at': now.toIso8601String(),
          }),
        );

        return StockMovementItem(
          id: movementId,
          ownerId: ownerId,
          partId: partId,
          type: MovementType.purchase,
          quantityChange: quantity,
          unitCost: unitCost ?? part.purchasePrice,
          note: note?.trim(),
          movedAt: now,
          createdAt: now,
          runningBalance: newStock,
        );
      });

      return Result.success(movement);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to add stock: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<StockMovementItem>> removeStock({
    required String ownerId,
    required String partId,
    required double quantity,
    double? unitCost,
    String? note,
    bool forceAllowNegative = false,
  }) async {
    if (quantity <= 0) {
      return const Result.failure(
        ValidationFailure(message: 'Quantity to remove must be greater than zero'),
      );
    }

    try {
      final part = await db.partsDao.getPartById(partId, ownerId);
      if (part == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Spare part not found'),
        );
      }

      final currentStock = part.cachedQuantity ?? 0.0;
      final projectedStock = currentStock - quantity;

      if (projectedStock < 0 && !forceAllowNegative) {
        final allowNegative = await getAllowNegativeStock();
        if (!allowNegative) {
          return Result.failure(
            NegativeStockFailure(
              message: 'Stock cannot go below zero',
              projectedStock: projectedStock,
            ),
          );
        }
      }

      final movementId = uuid.v4();
      final now = DateTime.now();

      final movement = await db.transaction(() async {
        // 1. Insert into stock_movements ledger with negative change
        await db.into(db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: Value(movementId),
                ownerId: ownerId,
                partId: partId,
                type: MovementType.adjustment,
                quantityChange: -quantity,
                unitCost: Value(unitCost ?? part.purchasePrice),
                note: Value(note?.trim()),
                movedAt: Value(now),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // 2. Update spare_parts cached_quantity
        await (db.update(db.spareParts)..where((t) => t.id.equals(partId))).write(
          SparePartsCompanion(
            cachedQuantity: Value(projectedStock),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        // 3. Enqueue stock movement creation to sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'stock_movements',
          recordId: movementId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': movementId,
            'owner_id': ownerId,
            'part_id': partId,
            'type': MovementType.adjustment.name,
            'quantity_change': -quantity,
            'unit_cost': unitCost ?? part.purchasePrice,
            'note': note?.trim(),
            'moved_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
          }),
        );

        // 4. Enqueue spare part cached quantity update
        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: partId,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'cached_quantity': projectedStock,
            'updated_at': now.toIso8601String(),
          }),
        );

        return StockMovementItem(
          id: movementId,
          ownerId: ownerId,
          partId: partId,
          type: MovementType.adjustment,
          quantityChange: -quantity,
          unitCost: unitCost ?? part.purchasePrice,
          note: note?.trim(),
          movedAt: now,
          createdAt: now,
          runningBalance: projectedStock,
        );
      });

      return Result.success(movement);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to remove stock: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<StockMovementItem>> adjustStock({
    required String ownerId,
    required String partId,
    required double countedQuantity,
    double? unitCost,
    String? note,
    bool forceAllowNegative = false,
  }) async {
    try {
      final part = await db.partsDao.getPartById(partId, ownerId);
      if (part == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Spare part not found'),
        );
      }

      if (countedQuantity < 0 && !forceAllowNegative) {
        final allowNegative = await getAllowNegativeStock();
        if (!allowNegative) {
          return Result.failure(
            NegativeStockFailure(
              message: 'Counted stock cannot be negative',
              projectedStock: countedQuantity,
            ),
          );
        }
      }

      final currentStock = part.cachedQuantity ?? 0.0;
      final delta = countedQuantity - currentStock;

      final movementId = uuid.v4();
      final now = DateTime.now();

      final movement = await db.transaction(() async {
        // 1. Insert into stock_movements ledger with delta change
        await db.into(db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: Value(movementId),
                ownerId: ownerId,
                partId: partId,
                type: MovementType.adjustment,
                quantityChange: delta,
                unitCost: Value(unitCost ?? part.purchasePrice),
                note: Value(note?.trim()),
                movedAt: Value(now),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // 2. Update spare_parts cached_quantity
        await (db.update(db.spareParts)..where((t) => t.id.equals(partId))).write(
          SparePartsCompanion(
            cachedQuantity: Value(countedQuantity),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        // 3. Enqueue stock movement
        await db.syncQueueDao.enqueue(
          tableName: 'stock_movements',
          recordId: movementId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': movementId,
            'owner_id': ownerId,
            'part_id': partId,
            'type': MovementType.adjustment.name,
            'quantity_change': delta,
            'unit_cost': unitCost ?? part.purchasePrice,
            'note': note?.trim(),
            'moved_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
          }),
        );

        // 4. Enqueue spare part update
        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: partId,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'cached_quantity': countedQuantity,
            'updated_at': now.toIso8601String(),
          }),
        );

        return StockMovementItem(
          id: movementId,
          ownerId: ownerId,
          partId: partId,
          type: MovementType.adjustment,
          quantityChange: delta,
          unitCost: unitCost ?? part.purchasePrice,
          note: note?.trim(),
          movedAt: now,
          createdAt: now,
          runningBalance: countedQuantity,
        );
      });

      return Result.success(movement);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to adjust stock: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<double>> recalculateCachedQuantity({
    required String ownerId,
    required String partId,
  }) async {
    try {
      final part = await db.partsDao.getPartById(partId, ownerId);
      if (part == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Spare part not found'),
        );
      }

      // Sum exact ledger entries
      final actualLedgerStock =
          await db.stockDao.calculateStockForPart(partId, ownerId);
      final now = DateTime.now();

      await db.transaction(() async {
        await (db.update(db.spareParts)..where((t) => t.id.equals(partId))).write(
          SparePartsCompanion(
            cachedQuantity: Value(actualLedgerStock),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: partId,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'cached_quantity': actualLedgerStock,
            'updated_at': now.toIso8601String(),
          }),
        );
      });

      return Result.success(actualLedgerStock);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(
          message: 'Failed to recalculate stock quantity: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<StockMovementItem>>> getMovementsWithBalance({
    required String ownerId,
    required String partId,
  }) async {
    try {
      // Fetch movements ascending by movedAt to compute running balance
      final query = db.select(db.stockMovements)
        ..where((t) =>
            t.partId.equals(partId) &
            t.ownerId.equals(ownerId) &
            t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.movedAt), (t) => OrderingTerm.asc(t.createdAt)]);

      final rows = await query.get();

      double cumulativeBalance = 0.0;
      final List<StockMovementItem> computed = [];

      for (final r in rows) {
        cumulativeBalance += r.quantityChange;
        computed.add(
          StockMovementItem(
            id: r.id,
            ownerId: r.ownerId,
            partId: r.partId,
            type: r.type,
            quantityChange: r.quantityChange,
            unitCost: r.unitCost,
            referenceId: r.referenceId,
            note: r.note,
            movedAt: r.movedAt,
            createdAt: r.createdAt,
            runningBalance: cumulativeBalance,
          ),
        );
      }

      // Return descending (most recent first) for UI
      return Result.success(computed.reversed.toList());
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to load movements: $e', cause: e),
      );
    }
  }

  @override
  Stream<List<StockMovementItem>> watchMovementsWithBalance({
    required String ownerId,
    required String partId,
  }) {
    final query = db.select(db.stockMovements)
      ..where((t) =>
          t.partId.equals(partId) &
          t.ownerId.equals(ownerId) &
          t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.movedAt), (t) => OrderingTerm.asc(t.createdAt)]);

    return query.watch().map((rows) {
      double cumulativeBalance = 0.0;
      final List<StockMovementItem> computed = [];

      for (final r in rows) {
        cumulativeBalance += r.quantityChange;
        computed.add(
          StockMovementItem(
            id: r.id,
            ownerId: r.ownerId,
            partId: r.partId,
            type: r.type,
            quantityChange: r.quantityChange,
            unitCost: r.unitCost,
            referenceId: r.referenceId,
            note: r.note,
            movedAt: r.movedAt,
            createdAt: r.createdAt,
            runningBalance: cumulativeBalance,
          ),
        );
      }

      return computed.reversed.toList();
    });
  }

  @override
  Future<Result<List<PartItem>>> getLowStockParts({
    required String ownerId,
  }) async {
    try {
      final parts = await _queryLowStockParts(ownerId).get();
      final items = parts.map(_mapPartJoinedRow).toList();
      return Result.success(items);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to fetch low stock parts: $e', cause: e),
      );
    }
  }

  @override
  Stream<List<PartItem>> watchLowStockParts({
    required String ownerId,
  }) {
    return _queryLowStockParts(ownerId)
        .watch()
        .map((rows) => rows.map(_mapPartJoinedRow).toList());
  }

  JoinedSelectStatement<HasResultSet, dynamic> _queryLowStockParts(
      String ownerId) {
    // Condition: cachedQuantity <= lowStockLevel, or if lowStockLevel is null, cachedQuantity <= 5.0
    final expr = db.spareParts.ownerId.equals(ownerId) &
        db.spareParts.deletedAt.isNull() &
        ((db.spareParts.lowStockLevel.isNotNull() &
                db.spareParts.cachedQuantity
                    .isSmallerOrEqual(db.spareParts.lowStockLevel)) |
            (db.spareParts.lowStockLevel.isNull() &
                db.spareParts.cachedQuantity.isSmallerOrEqualValue(5.0)));

    return db.select(db.spareParts).join([
      leftOuterJoin(db.brands, db.brands.id.equalsExp(db.spareParts.brandId)),
      leftOuterJoin(
          db.categories, db.categories.id.equalsExp(db.spareParts.categoryId)),
      leftOuterJoin(
          db.locations, db.locations.id.equalsExp(db.spareParts.locationId)),
    ])
      ..where(expr)
      ..orderBy([
        OrderingTerm.asc(db.spareParts.cachedQuantity),
        OrderingTerm.asc(db.spareParts.name),
      ]);
  }

  PartItem _mapPartJoinedRow(TypedResult row) {
    final p = row.readTable(db.spareParts);
    final b = row.readTableOrNull(db.brands);
    final c = row.readTableOrNull(db.categories);
    final l = row.readTableOrNull(db.locations);

    return PartItem(
      id: p.id,
      ownerId: p.ownerId,
      name: p.name,
      partNumber: p.partNumber,
      photoLocalPath: p.photoLocalPath,
      photoUrl: p.photoUrl,
      brandId: p.brandId,
      brandName: b?.name,
      categoryId: p.categoryId,
      categoryName: c?.name,
      locationId: p.locationId,
      locationName: l?.name,
      customLocation: p.customLocation,
      description: p.description,
      unit: p.unit,
      purchasePrice: p.purchasePrice,
      sellingPrice: p.sellingPrice,
      sizeSpecs: p.sizeSpecs,
      notes: p.notes,
      lowStockLevel: p.lowStockLevel,
      cachedQuantity: p.cachedQuantity ?? 0.0,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      deletedAt: p.deletedAt,
    );
  }

  @override
  Future<bool> getAllowNegativeStock() async {
    final val = await db.settingsDao.getSetting(settingAllowNegativeStock);
    return val == 'true';
  }

  @override
  Future<void> setAllowNegativeStock(bool allow) async {
    await db.settingsDao.setSetting(
      settingAllowNegativeStock,
      allow ? 'true' : 'false',
    );
  }
}
