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
import '../datasources/parts_local_data_source.dart';

/// Clean Architecture implementation of [PartsRepository] backed by [PartsLocalDataSource].
/// All reads strictly query SQLite reactive streams, and all writes execute atomic
/// transactions saving to the local database and the sync outbox.
class LocalPartsRepository implements PartsRepository {
  final PartsLocalDataSource localDataSource;
  final AppDatabase db;
  final Uuid uuid;

  LocalPartsRepository({
    required this.db,
    PartsLocalDataSource? localDataSource,
    this.uuid = const Uuid(),
  }) : localDataSource =
            localDataSource ?? PartsLocalDataSource(db: db, uuid: uuid);

  @override
  Stream<List<PartItem>> watchActiveParts(String ownerId) {
    return localDataSource.watchActiveParts(ownerId);
  }

  @override
  Future<Result<List<PartItem>>> getActiveParts(String ownerId) async {
    try {
      final items = await localDataSource.getActiveParts(ownerId);
      return Result.success(items);
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
      final part = await localDataSource.getPartById(ownerId, id);
      if (part == null) {
        return const Result.failure(NotFoundFailure(message: 'Part not found'));
      }
      return Result.success(part);
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
      final created = await localDataSource.savePartWithOutbox(
        ownerId: ownerId,
        name: name,
        partNumber: partNumber,
        photoLocalPath: photoLocalPath,
        photoUrl: photoUrl,
        brandId: brandId,
        categoryId: categoryId,
        locationId: locationId,
        customLocation: customLocation,
        description: description,
        unit: unit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: sizeSpecs,
        notes: notes,
        lowStockLevel: lowStockLevel,
        initialQuantity: initialQuantity,
      );
      return Result.success(created);
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
      final updated = await localDataSource.updatePartWithOutbox(
        ownerId: ownerId,
        id: id,
        name: name,
        partNumber: partNumber,
        photoLocalPath: photoLocalPath,
        photoUrl: photoUrl,
        brandId: brandId,
        categoryId: categoryId,
        locationId: locationId,
        customLocation: customLocation,
        description: description,
        unit: unit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        sizeSpecs: sizeSpecs,
        notes: notes,
        lowStockLevel: lowStockLevel,
      );
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
      await localDataSource.softDeletePartWithOutbox(
        ownerId: ownerId,
        id: id,
      );
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
      final paged = await localDataSource.getPagedParts(
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

  /// Calculates real-time dashboard figures locally from SQLite.
  Future<Result<InventoryDashboardMetrics>> getLocalDashboardMetrics(
      String ownerId) async {
    try {
      final metrics = await localDataSource.getLocalDashboardMetrics(ownerId);
      return Result.success(metrics);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to calculate local dashboard metrics: $e',
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
        {'nameAm': 'ተርቦቻርጀር ስብስብ', 'nameEn': 'Turbocharger Assembly Kit', 'brand': 'CAT', 'cat': 'Engine', 'shelf': 'Shelf 4', 'buy': '14000', 'sell': '21000'},
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

        final double qty;
        if (i % 10 == 0) {
          qty = 0.0;
        } else if (i % 5 == 0) {
          qty = ((i % 4) + 1).toDouble();
        } else {
          qty = (10 + (i * 3) % 36).toDouble();
        }

        final purchasePrice =
            double.tryParse(template['buy'] ?? '500') ?? 500.0;
        final sellingPrice =
            double.tryParse(template['sell'] ?? '800') ?? 800.0;

        companions.add(
          SparePartsCompanion(
            id: Value(id),
            ownerId: Value(ownerId),
            name: Value(name),
            partNumber: Value(partNumber),
            customLocation: Value(template['shelf'] ?? 'Shelf 1'),
            description: Value(
                'Sample ${template["nameEn"]} replacement for heavy machinery'),
            unit: const Value('pcs'),
            purchasePrice: Value(purchasePrice),
            sellingPrice: Value(sellingPrice),
            sizeSpecs: const Value('Std OEM spec'),
            notes: Value('[DEMO] Sample demo spare part #${i + 1}'),
            lowStockLevel: const Value(5.0),
            cachedQuantity: Value(qty),
            quantity: Value(qty),
            createdAt: Value(now.subtract(Duration(minutes: i * 5))),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );
      }

      await db.partsDao.batchInsertParts(companions);

      // Enqueue sync items to outbox
      for (final comp in companions) {
        await db.syncQueueDao.enqueueOperation(
          operationId: uuid.v4(),
          ownerId: ownerId,
          entityType: 'spare_parts',
          entityId: comp.id.value,
          operationType: 'insert',
          payload: jsonEncode({
            'id': comp.id.value,
            'owner_id': ownerId,
            'name': comp.name.value,
            'nameAm': comp.name.value?.split('·').first.trim(),
            'nameEn': comp.name.value?.split('·').last.trim(),
            'part_number': comp.partNumber.value,
            'custom_location': comp.customLocation.value,
            'unit': 'pcs',
            'purchase_price': comp.purchasePrice.value,
            'selling_price': comp.sellingPrice.value,
            'notes': comp.notes.value,
            'isDemo': true,
            'low_stock_level': 5.0,
            'cached_quantity': comp.cachedQuantity.value,
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
}
