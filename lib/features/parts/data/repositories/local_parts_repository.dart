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
    int count = 25,
  }) async {
    try {
      final List<Map<String, String>> templateParts = [
        {'nameAm': 'የዘይት ማጣሪያ', 'nameEn': 'Oil Filter Heavy Duty', 'brand': 'CAT', 'cat': 'Filters', 'shelf': 'Shelf 1', 'buy': '450', 'sell': '700'},
        {'nameAm': 'የናፍጣ ማጣሪያ', 'nameEn': 'Fuel Filter Secondary', 'brand': 'CTP', 'cat': 'Filters', 'shelf': 'Shelf 2', 'buy': '650', 'sell': '950'},
        {'nameAm': 'የሃይድሮሊክ ሲሊንደር ማሸጊያ', 'nameEn': 'Hydraulic Cylinder Seal Kit', 'brand': 'Hitachi', 'cat': 'Seals & Gaskets', 'shelf': 'Shelf 3', 'buy': '2400', 'sell': '3800'},
        {'nameAm': 'የትራክ ሮለር', 'nameEn': 'Track Roller Assembly', 'brand': 'Doosan', 'cat': 'Undercarriage', 'shelf': 'Shelf 5', 'buy': '8500', 'sell': '12500'},
        {'nameAm': 'የኢንጀክተር ኖዝል', 'nameEn': 'Fuel Injector Nozzle', 'brand': 'IPD', 'cat': 'Engine', 'shelf': 'Shelf 4', 'buy': '3200', 'sell': '4900'},
        {'nameAm': 'አልተርኔተር 24V', 'nameEn': 'Alternator 24V 60A', 'brand': 'Develon', 'cat': 'Electrical', 'shelf': 'Shelf 6', 'buy': '7200', 'sell': '11000'},
        {'nameAm': 'እስጣርተር ሞተር', 'nameEn': 'Starter Motor 24V 7.5kW', 'brand': 'SANY', 'cat': 'Electrical', 'shelf': 'Shelf 2', 'buy': '11500', 'sell': '16800'},
        {'nameAm': 'የፒስተን ሪንግ', 'nameEn': 'Piston Ring Set STD', 'brand': 'CTP', 'cat': 'Engine', 'shelf': 'Shelf 3', 'buy': '1800', 'sell': '2900'},
        {'nameAm': 'የውሃ ፓምፕ', 'nameEn': 'Water Pump Assembly', 'brand': 'CAT', 'cat': 'Engine', 'shelf': 'Shelf 4', 'buy': '5400', 'sell': '8200'},
        {'nameAm': 'የባሊ ጥርስ', 'nameEn': 'Bucket Tooth Tiger', 'brand': 'SANY', 'cat': 'Undercarriage', 'shelf': 'Shelf 1', 'buy': '1200', 'sell': '1950'},
        {'nameAm': 'የውጭ አየር ማጣሪያ', 'nameEn': 'Air Filter Outer Element', 'brand': 'Doosan', 'cat': 'Filters', 'shelf': 'Shelf 2', 'buy': '1100', 'sell': '1750'},
        {'nameAm': 'ዋና ቤሪንግ ስብስብ', 'nameEn': 'Main Bearing Set Standard', 'brand': 'IPD', 'cat': 'Engine', 'shelf': 'Shelf 3', 'buy': '3600', 'sell': '5500'},
        {'nameAm': 'የሃይድሮሊክ ዋና ፓምፕ ቫልቭ', 'nameEn': 'Hydraulic Pump Relief Valve', 'brand': 'Hitachi', 'cat': 'Hydraulic', 'shelf': 'Shelf 1', 'buy': '4200', 'sell': '6400'},
        {'nameAm': 'የፍሬን ዲስክ', 'nameEn': 'Brake Friction Disc', 'brand': 'Develon', 'cat': 'Hardware & Fasteners', 'shelf': 'Shelf 5', 'buy': '2100', 'sell': '3300'},
        {'nameAm': 'የቀበቶ መወጠሪያ', 'nameEn': 'Fan Belt Tensioner Pulley', 'brand': 'CAT', 'cat': 'Engine', 'shelf': 'Shelf 6', 'buy': '1450', 'sell': '2300'},
      ];

      final now = DateTime.now();
      final List<SparePartsCompanion> companions = [];

      for (var i = 0; i < count; i++) {
        final id = uuid.v4();
        final template = templateParts[i % templateParts.length];
        final name = '${template["nameAm"]} · ${template["nameEn"]} #${i + 1}';
        final partNumber = '${template["brand"]}-${1000 + i * 11}';

        // Stock distribution: 10% out of stock (0), 20% low stock (1 to 4), 70% in stock (10 to 45)
        final double qty;
        if (i % 10 == 0) {
          qty = 0.0;
        } else if (i % 5 == 0) {
          qty = ((i % 4) + 1).toDouble();
        } else {
          qty = (10 + (i * 3) % 36).toDouble();
        }

        final purchasePrice = double.tryParse(template['buy'] ?? '500') ?? 500.0;
        final sellingPrice = double.tryParse(template['sell'] ?? '800') ?? 800.0;

        companions.add(
          SparePartsCompanion(
            id: Value(id),
            ownerId: Value(ownerId),
            name: Value(name),
            partNumber: Value(partNumber),
            customLocation: Value(template['shelf'] ?? 'Shelf 1'),
            description: Value('Sample ${template["nameEn"]} replacement for heavy machinery'),
            unit: const Value('pcs'),
            purchasePrice: Value(purchasePrice),
            sellingPrice: Value(sellingPrice),
            sizeSpecs: Value('Std OEM spec'),
            notes: Value('[DEMO] Sample demo spare part #${i + 1}'),
            lowStockLevel: const Value(5.0),
            cachedQuantity: Value(qty),
            createdAt: Value(now.subtract(Duration(minutes: i * 5))),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );
      }

      await db.partsDao.batchInsertParts(companions);

      // Enqueue sync items so sample parts sync normally
      for (final comp in companions) {
        await db.syncQueueDao.enqueue(
          ownerId: ownerId,
          entityType: 'spare_parts',
          entityId: comp.id.value,
          operation: 'CREATE',
          payload: jsonEncode({
            'id': comp.id.value,
            'ownerId': ownerId,
            'name': comp.name.value,
            'nameAm': comp.name.value?.split('·').first.trim(),
            'nameEn': comp.name.value?.split('·').last.trim(),
            'partNumber': comp.partNumber.value,
            'customLocation': comp.customLocation.value,
            'unit': 'pcs',
            'purchasePrice': comp.purchasePrice.value,
            'sellingPrice': comp.sellingPrice.value,
            'notes': comp.notes.value,
            'isDemo': true,
            'lowStockLevel': 5.0,
            'cachedQuantity': comp.cachedQuantity.value,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );
      }

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
