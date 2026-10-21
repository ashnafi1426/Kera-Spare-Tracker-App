import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/paged_result.dart';
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

  @override
  Future<Result<PagedResult<PartItem>>> getPagedParts({
    required String ownerId,
    InventoryFilter filter = const InventoryFilter(),
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final paged = await db.partsDao.getPagedParts(
        ownerId: ownerId,
        filter: filter,
        limit: limit,
        offset: offset,
      );
      return Result.success(paged);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to load paged parts: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<int>> seedTestParts({
    required String ownerId,
    int count = 2000,
  }) async {
    try {
      final brands = await (db.select(db.brands)
            ..where((t) =>
                (t.ownerId.equals(ownerId) | t.isDefault.equals(true)) &
                t.deletedAt.isNull()))
          .get();

      final categories = await (db.select(db.categories)
            ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull()))
          .get();

      final locations = await (db.select(db.locations)
            ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull()))
          .get();

      final List<String> partNames = [
        'Oil Filter High Efficiency',
        'Air Filter Heavy Duty',
        'Fuel Filter Secondary',
        'Hydraulic Filter Return',
        'Water Separator Element',
        'Turbocharger Assembly',
        'Cylinder Head Gasket',
        'Piston Ring Set Standard',
        'Crankshaft Main Bearing',
        'Connecting Rod Bushing',
        'Hydraulic Main Pump',
        'Control Valve Spool',
        'Boom Cylinder Seal Kit',
        'Bucket Cylinder Seal Kit',
        'Arm Cylinder Seal Kit',
        'Brake Pad Heavy Duty',
        'Brake Shoe Assembly',
        'Brake Master Cylinder',
        'Track Roller Single Flange',
        'Carrier Roller Assembly',
        'Alternator 24V 60A',
        'Starter Motor 24V 7.5kW',
        'Engine Stop Solenoid',
        'Water Temperature Sensor',
        'Oil Pressure Switch',
        'Radiator Cooling Fan',
        'Water Pump Heavy Duty',
        'Thermostat 71C',
        'Fan Belt Set',
        'Tensioner Pulley',
        'Fuel Injection Pump',
        'Injector Nozzle Tip',
        'Feed Pump Manual',
        'Common Rail Sensor',
        'Glow Plug 24V',
        'Clutch Disc Assembly',
        'Pressure Plate',
        'Release Bearing',
        'Universal Joint Cross',
        'Drive Shaft Center Bearing',
      ];

      final List<String> partPrefixes = [
        'CAT-1R',
        'KOM-708',
        'TOY-044',
        'HOL-353',
        'BOS-044',
        'DON-P55',
        'HIT-918',
        'PER-U5P',
        'CUM-328',
        'DEN-101',
        'ISU-897',
        'MITS-ME',
      ];

      final now = DateTime.now();
      final List<SparePartsCompanion> companions = [];

      for (var i = 0; i < count; i++) {
        final id = uuid.v4();
        final nameBase = partNames[i % partNames.length];
        final prefix = partPrefixes[i % partPrefixes.length];
        final numberSuffix = (1000 + (i * 3) % 9000).toString();
        final partNumber = '$prefix-$numberSuffix';
        final name = '$nameBase #$i';

        final brandId = brands.isNotEmpty ? brands[i % brands.length].id : null;
        final categoryId =
            categories.isNotEmpty ? categories[i % categories.length].id : null;
        final locationId =
            locations.isNotEmpty ? locations[i % locations.length].id : null;

        // Distribute stock: 10% out of stock (0), 20% low stock (<=5), 70% in stock (>5)
        final double qty;
        if (i % 10 == 0) {
          qty = 0.0;
        } else if (i % 5 == 0) {
          qty = ((i % 5) + 1).toDouble(); // 1 to 5
        } else {
          qty = (6 + (i * 7) % 65).toDouble(); // 6 to 70
        }

        final purchasePrice = (500 + (i * 17) % 15000).toDouble();
        final sellingPrice = (purchasePrice * 1.25).roundToDouble();

        companions.add(
          SparePartsCompanion(
            id: Value(id),
            ownerId: Value(ownerId),
            name: Value(name),
            partNumber: Value(partNumber),
            brandId: Value(brandId),
            categoryId: Value(categoryId),
            locationId: Value(locationId),
            customLocation: Value('Spot ${(i % 20) + 1}'),
            description: Value('High grade replacement component for $nameBase'),
            unit: const Value('pcs'),
            purchasePrice: Value(purchasePrice),
            sellingPrice: Value(sellingPrice),
            sizeSpecs: Value('Spec ${(i % 12) + 1}'),
            notes: const Value('[TEST_SEED] Performance benchmark part'),
            lowStockLevel: const Value(5.0),
            cachedQuantity: Value(qty),
            createdAt: Value(now.subtract(Duration(minutes: i % 10000))),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );
      }

      await db.partsDao.batchInsertParts(companions);
      return Result.success(count);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to seed test parts: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<int>> clearTestParts(String ownerId) async {
    try {
      final deleted = await db.partsDao.deleteTestParts(ownerId);
      return Result.success(deleted);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to clear test parts: $e',
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
