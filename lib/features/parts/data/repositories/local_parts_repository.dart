import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/part_item.dart';
import '../../domain/repositories/parts_repository.dart';

/// SQLite and sync_queue backed implementation of [PartsRepository].
class LocalPartsRepository implements PartsRepository {
  final AppDatabase db;
  final Uuid uuid;

  LocalPartsRepository({
    required this.db,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<PartItem>> watchActiveParts(String ownerId) {
    return db.partsDao.watchActiveParts(ownerId).map(
          (rows) => rows.map(_mapRowToPartItem).toList(),
        );
  }

  @override
  Future<Result<List<PartItem>>> getActiveParts(String ownerId) async {
    try {
      final rows = await db.partsDao.getActiveParts(ownerId);
      return Result.success(rows.map(_mapRowToPartItem).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to retrieve active parts: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<PartItem>> getPartById({
    required String ownerId,
    required String id,
  }) async {
    try {
      final row = await db.partsDao.getPartById(id, ownerId);
      if (row == null) {
        return const Result.failure(NotFoundFailure(message: 'Part not found'));
      }
      return Result.success(_mapRowToPartItem(row));
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to retrieve part: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<PartItem>> createPart({
    required String ownerId,
    String? name,
    String? partNumber,
    String? photoLocalPath,
    String? photoUrl,
    String? brandId,
    String? categoryId,
    String? locationId,
    String? customLocation,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? sizeSpecs,
    String? notes,
    double? lowStockLevel,
    double? initialQuantity,
  }) async {
    // Validate non-negative numbers
    if (purchasePrice != null && purchasePrice < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Purchase price cannot be negative'),
      );
    }
    if (sellingPrice != null && sellingPrice < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Selling price cannot be negative'),
      );
    }
    if (lowStockLevel != null && lowStockLevel < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Low stock level cannot be negative'),
      );
    }
    if (initialQuantity != null && initialQuantity < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Quantity cannot be negative'),
      );
    }

    try {
      final partId = uuid.v4();
      final now = DateTime.now();
      final hasInitialStock = initialQuantity != null && initialQuantity > 0;
      final cachedQty = hasInitialStock ? initialQuantity : 0.0;

      final createdPart = await db.transaction(() async {
        // 1. Insert spare_parts row
        await db.into(db.spareParts).insert(
              SparePartsCompanion.insert(
                id: Value(partId),
                ownerId: ownerId,
                name: Value(name?.trim()),
                partNumber: Value(partNumber?.trim()),
                photoLocalPath: Value(photoLocalPath),
                photoUrl: Value(photoUrl),
                brandId: Value(brandId),
                categoryId: Value(categoryId),
                locationId: Value(locationId),
                customLocation: Value(customLocation?.trim()),
                description: Value(description?.trim()),
                unit: Value(unit?.trim()),
                purchasePrice: Value(purchasePrice),
                sellingPrice: Value(sellingPrice),
                sizeSpecs: Value(sizeSpecs?.trim()),
                notes: Value(notes?.trim()),
                lowStockLevel: Value(lowStockLevel),
                cachedQuantity: Value(cachedQty),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // 2. Enqueue spare_parts insert mutation to sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: partId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': partId,
            'owner_id': ownerId,
            'name': name?.trim(),
            'part_number': partNumber?.trim(),
            'photo_local_path': photoLocalPath,
            'photo_url': photoUrl,
            'brand_id': brandId,
            'category_id': categoryId,
            'location_id': locationId,
            'custom_location': customLocation?.trim(),
            'description': description?.trim(),
            'unit': unit?.trim(),
            'purchase_price': purchasePrice,
            'selling_price': sellingPrice,
            'size_specs': sizeSpecs?.trim(),
            'notes': notes?.trim(),
            'low_stock_level': lowStockLevel,
            'cached_quantity': cachedQty,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        // 3. If initial stock is entered, insert initial stock_movement ledger entry
        if (hasInitialStock) {
          final movementId = uuid.v4();
          await db.into(db.stockMovements).insert(
                StockMovementsCompanion.insert(
                  id: Value(movementId),
                  ownerId: ownerId,
                  partId: partId,
                  type: MovementType.initial,
                  quantityChange: initialQuantity,
                  unitCost: Value(purchasePrice),
                  note: const Value('Initial stock on part creation'),
                  movedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          await db.syncQueueDao.enqueue(
            tableName: 'stock_movements',
            recordId: movementId,
            operation: SyncOperation.insert,
            payload: jsonEncode({
              'id': movementId,
              'owner_id': ownerId,
              'part_id': partId,
              'type': MovementType.initial.name,
              'quantity_change': initialQuantity,
              'unit_cost': purchasePrice,
              'note': 'Initial stock on part creation',
              'moved_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            }),
          );
        }

        return PartItem(
          id: partId,
          ownerId: ownerId,
          name: name?.trim(),
          partNumber: partNumber?.trim(),
          photoLocalPath: photoLocalPath,
          photoUrl: photoUrl,
          brandId: brandId,
          categoryId: categoryId,
          locationId: locationId,
          customLocation: customLocation?.trim(),
          description: description?.trim(),
          unit: unit?.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          sizeSpecs: sizeSpecs?.trim(),
          notes: notes?.trim(),
          lowStockLevel: lowStockLevel,
          cachedQuantity: cachedQty,
          createdAt: now,
          updatedAt: now,
        );
      });

      return Result.success(createdPart);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to create spare part: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<PartItem>> updatePart({
    required String ownerId,
    required String id,
    String? name,
    String? partNumber,
    String? photoLocalPath,
    String? photoUrl,
    String? brandId,
    String? categoryId,
    String? locationId,
    String? customLocation,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? sizeSpecs,
    String? notes,
    double? lowStockLevel,
  }) async {
    if (purchasePrice != null && purchasePrice < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Purchase price cannot be negative'),
      );
    }
    if (sellingPrice != null && sellingPrice < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Selling price cannot be negative'),
      );
    }
    if (lowStockLevel != null && lowStockLevel < 0) {
      return const Result.failure(
        ValidationFailure(message: 'Low stock level cannot be negative'),
      );
    }

    try {
      final existing = await db.partsDao.getPartById(id, ownerId);
      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Part not found'));
      }

      final now = DateTime.now();

      final updated = await db.transaction(() async {
        await (db.update(db.spareParts)..where((t) => t.id.equals(id))).write(
          SparePartsCompanion(
            name: Value(name?.trim()),
            partNumber: Value(partNumber?.trim()),
            photoLocalPath: Value(photoLocalPath),
            photoUrl: Value(photoUrl),
            brandId: Value(brandId),
            categoryId: Value(categoryId),
            locationId: Value(locationId),
            customLocation: Value(customLocation?.trim()),
            description: Value(description?.trim()),
            unit: Value(unit?.trim()),
            purchasePrice: Value(purchasePrice),
            sellingPrice: Value(sellingPrice),
            sizeSpecs: Value(sizeSpecs?.trim()),
            notes: Value(notes?.trim()),
            lowStockLevel: Value(lowStockLevel),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: id,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'name': name?.trim(),
            'part_number': partNumber?.trim(),
            'photo_local_path': photoLocalPath,
            'photo_url': photoUrl,
            'brand_id': brandId,
            'category_id': categoryId,
            'location_id': locationId,
            'custom_location': customLocation?.trim(),
            'description': description?.trim(),
            'unit': unit?.trim(),
            'purchase_price': purchasePrice,
            'selling_price': sellingPrice,
            'size_specs': sizeSpecs?.trim(),
            'notes': notes?.trim(),
            'low_stock_level': lowStockLevel,
            'updated_at': now.toIso8601String(),
          }),
        );

        return PartItem(
          id: id,
          ownerId: ownerId,
          name: name?.trim(),
          partNumber: partNumber?.trim(),
          photoLocalPath: photoLocalPath,
          photoUrl: photoUrl,
          brandId: brandId,
          categoryId: categoryId,
          locationId: locationId,
          customLocation: customLocation?.trim(),
          description: description?.trim(),
          unit: unit?.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          sizeSpecs: sizeSpecs?.trim(),
          notes: notes?.trim(),
          lowStockLevel: lowStockLevel,
          cachedQuantity: existing.cachedQuantity ?? 0.0,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
      });

      return Result.success(updated);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to update spare part: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deletePart({
    required String ownerId,
    required String id,
  }) async {
    try {
      final existing = await db.partsDao.getPartById(id, ownerId);
      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Part not found'));
      }

      final now = DateTime.now();

      await db.transaction(() async {
        await db.partsDao.softDeletePart(id, ownerId);

        await db.syncQueueDao.enqueue(
          tableName: 'spare_parts',
          recordId: id,
          operation: SyncOperation.delete,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'deleted_at': now.toIso8601String(),
          }),
        );
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to soft delete spare part: $e',
        cause: e,
      ));
    }
  }

  PartItem _mapRowToPartItem(SparePart row) {
    return PartItem(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      partNumber: row.partNumber,
      photoLocalPath: row.photoLocalPath,
      photoUrl: row.photoUrl,
      brandId: row.brandId,
      categoryId: row.categoryId,
      locationId: row.locationId,
      customLocation: row.customLocation,
      description: row.description,
      unit: row.unit,
      purchasePrice: row.purchasePrice,
      sellingPrice: row.sellingPrice,
      sizeSpecs: row.sizeSpecs,
      notes: row.notes,
      lowStockLevel: row.lowStockLevel,
      cachedQuantity: row.cachedQuantity ?? 0.0,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
