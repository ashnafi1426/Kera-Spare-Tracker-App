import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/part_item.dart';

/// Aggregated metrics computed locally from the SQLite database.
class InventoryDashboardMetrics {
  final int totalParts;
  final double totalQuantity;
  final int lowStockCount;
  final int outOfStockCount;
  final double inventoryPurchaseValue;
  final double inventorySellingValue;
  final int pendingSyncCount;

  const InventoryDashboardMetrics({
    required this.totalParts,
    required this.totalQuantity,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inventoryPurchaseValue,
    required this.inventorySellingValue,
    required this.pendingSyncCount,
  });
}

/// Local SQLite data source for parts and offline inventory management.
/// Screens read exclusively from SQLite reactive streams via this data source.
class PartsLocalDataSource {
  final AppDatabase db;
  final Uuid uuid;

  PartsLocalDataSource({
    required this.db,
    this.uuid = const Uuid(),
  });

  /// Continuously watches active spare parts for an owner.
  Stream<List<PartItem>> watchActiveParts(String ownerId) {
    return db.partsDao.watchActiveParts(ownerId).map(
          (rows) => rows.map(_mapRowToPartItem).toList(),
        );
  }

  /// Retrieves active spare parts for an owner.
  Future<List<PartItem>> getActiveParts(String ownerId) async {
    final rows = await db.partsDao.getActiveParts(ownerId);
    return rows.map(_mapRowToPartItem).toList();
  }

  /// Retrieves a specific part by ID.
  Future<PartItem?> getPartById(String ownerId, String id) async {
    final row = await db.partsDao.getPartById(id, ownerId);
    if (row == null) return null;
    return _mapRowToPartItem(row);
  }

  /// Paged search and filtering query with local SQLite aggregation.
  Future<PagedResult<PartItem>> getPagedParts({
    required String ownerId,
    InventoryFilter filter = const InventoryFilter(),
    int limit = 50,
    int offset = 0,
  }) {
    return db.partsDao.getPagedParts(
      ownerId: ownerId,
      filter: filter,
      limit: limit,
      offset: offset,
    );
  }

  /// Atomic creation of a spare part and outbox enqueue in ONE SQLite transaction.
  /// If [initialQuantity] is provided (> 0), atomically logs an initial stock movement
  /// with delta change, never an absolute total.
  Future<PartItem> savePartWithOutbox({
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
    final partId = uuid.v4();
    final now = DateTime.now();
    final hasInitialStock = initialQuantity != null && initialQuantity > 0;
    final cachedQty = hasInitialStock ? initialQuantity : 0.0;

    return db.transaction(() async {
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
              quantity: Value(cachedQty),
              serverVersion: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

      // 2. Enqueue spare_parts insert mutation to sync_queue
      final partOpId = uuid.v4();
      await db.syncQueueDao.enqueueOperation(
        operationId: partOpId,
        ownerId: ownerId,
        entityType: 'spare_parts',
        entityId: partId,
        operationType: 'insert',
        baseVersion: 1,
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
                sparePartId: Value(partId),
                type: MovementType.initial,
                movementType: const Value('initial'),
                quantityChange: initialQuantity,
                quantityBefore: const Value(0.0),
                quantityAfter: Value(initialQuantity),
                unitCost: Value(purchasePrice),
                note: const Value('Initial stock on part creation'),
                movedAt: Value(now),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // Enqueue stock_movement with DELTA change only (+quantity), never absolute total
        final movementOpId = uuid.v4();
        await db.syncQueueDao.enqueueOperation(
          operationId: movementOpId,
          ownerId: ownerId,
          entityType: 'stock_movements',
          entityId: movementId,
          operationType: 'insert',
          dependsOn: partOpId,
          payload: jsonEncode({
            'id': movementId,
            'owner_id': ownerId,
            'part_id': partId,
            'spare_part_id': partId,
            'type': MovementType.initial.name,
            'movement_type': 'initial',
            'quantity_change': initialQuantity,
            'quantity_before': 0.0,
            'quantity_after': initialQuantity,
            'unit_cost': purchasePrice,
            'note': 'Initial stock on part creation',
            'moved_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
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
  }

  /// Atomic update of a spare part and outbox enqueue in ONE SQLite transaction.
  Future<PartItem> updatePartWithOutbox({
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
    final existing = await db.partsDao.getPartById(id, ownerId);
    if (existing == null) {
      throw Exception('Part $id not found for owner $ownerId');
    }

    final now = DateTime.now();
    final nextVersion = existing.serverVersion + 1;

    return db.transaction(() async {
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
          serverVersion: Value(nextVersion),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

      final opId = uuid.v4();
      await db.syncQueueDao.enqueueOperation(
        operationId: opId,
        ownerId: ownerId,
        entityType: 'spare_parts',
        entityId: id,
        operationType: 'update',
        baseVersion: existing.serverVersion,
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
  }

  /// Atomic soft-delete of a spare part (tombstone) and outbox enqueue in ONE SQLite transaction.
  Future<void> softDeletePartWithOutbox({
    required String ownerId,
    required String id,
  }) async {
    final now = DateTime.now();

    await db.transaction(() async {
      await db.partsDao.softDeletePart(id, ownerId);

      final opId = uuid.v4();
      await db.syncQueueDao.enqueueOperation(
        operationId: opId,
        ownerId: ownerId,
        entityType: 'spare_parts',
        entityId: id,
        operationType: 'delete',
        payload: jsonEncode({
          'id': id,
          'owner_id': ownerId,
          'deleted_at': now.toIso8601String(),
        }),
      );
    });
  }

  /// Computes dashboard metrics locally from SQLite without making any network calls.
  Future<InventoryDashboardMetrics> getLocalDashboardMetrics(
      String ownerId) async {
    final activeParts = await db.partsDao.getActiveParts(ownerId);
    final pendingCount = await db.syncQueueDao.countPending();

    int lowStock = 0;
    int outOfStock = 0;
    double totalQty = 0.0;
    double purchaseVal = 0.0;
    double sellingVal = 0.0;

    for (final part in activeParts) {
      final qty = part.cachedQuantity ?? 0.0;
      final threshold = part.lowStockLevel ?? 5.0;

      totalQty += qty;
      if (qty <= 0) {
        outOfStock++;
      } else if (qty <= threshold) {
        lowStock++;
      }

      if (part.purchasePrice != null && qty > 0) {
        purchaseVal += qty * part.purchasePrice!;
      }
      if (part.sellingPrice != null && qty > 0) {
        sellingVal += qty * part.sellingPrice!;
      }
    }

    return InventoryDashboardMetrics(
      totalParts: activeParts.length,
      totalQuantity: totalQty,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
      inventoryPurchaseValue: purchaseVal,
      inventorySellingValue: sellingVal,
      pendingSyncCount: pendingCount,
    );
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
