import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';

void main() {
  late AppDatabase db;
  const ownerA = 'owner_uuid_111';
  const ownerB = 'owner_uuid_222';

  setUp(() {
    // Open in-memory SQLite database for testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - Default Seeding', () {
    test('seeds 7 default brands on first run', () async {
      final allBrands = await db.select(db.brands).get();
      final brandNames = allBrands.map((b) => b.name).toList();

      expect(allBrands.length, equals(AppConstants.defaultBrands.length));
      for (final defaultBrand in AppConstants.defaultBrands) {
        expect(brandNames, contains(defaultBrand));
      }
      expect(allBrands.every((b) => b.isDefault && b.ownerId == 'global'), isTrue);
    });

    test('seeds default shelf locations on first run', () async {
      final allLocations = await db.select(db.locations).get();
      final locationNames = allLocations.map((l) => l.name).toList();

      expect(allLocations.length, equals(AppConstants.defaultShelves.length));
      expect(locationNames, contains('Shelf 1'));
      expect(locationNames, contains('Shelf 2'));
    });
  });

  group('PartsDao - CRUD, Search, and Soft Delete', () {
    test('inserts, queries, and multi-tenant isolates spare parts', () async {
      final partId = await db.partsDao.insertPart(
        SparePartsCompanion.insert(
          ownerId: ownerA,
          name: const Value('CAT Hydraulic Pump 320D'),
          partNumber: const Value('CAT-HP-320D'),
          purchasePrice: const Value(15000.0),
          sellingPrice: const Value(22000.0),
          unit: const Value('Pcs'),
        ),
      );
      expect(partId, isPositive);

      // Owner A can query the part
      final activePartsA = await db.partsDao.getActiveParts(ownerA);
      expect(activePartsA.length, equals(1));
      expect(activePartsA.first.name, equals('CAT Hydraulic Pump 320D'));
      expect(activePartsA.first.partNumber, equals('CAT-HP-320D'));
      expect(activePartsA.first.syncStatus, equals(SyncStatus.pending));

      // Owner B cannot see Owner A's parts
      final activePartsB = await db.partsDao.getActiveParts(ownerB);
      expect(activePartsB, isEmpty);
    });

    test('searches parts by name or part number', () async {
      await db.partsDao.insertPart(
        SparePartsCompanion.insert(
          ownerId: ownerA,
          name: const Value('Doosan Oil Filter'),
          partNumber: const Value('DS-OF-900'),
        ),
      );
      await db.partsDao.insertPart(
        SparePartsCompanion.insert(
          ownerId: ownerA,
          name: const Value('Hitachi Track Roller'),
          partNumber: const Value('HT-TR-100'),
        ),
      );

      final searchByPartNumber = await db.partsDao.searchParts(
        ownerId: ownerA,
        query: 'DS-OF',
      );
      expect(searchByPartNumber.length, equals(1));
      expect(searchByPartNumber.first.name, equals('Doosan Oil Filter'));

      final searchByName = await db.partsDao.searchParts(
        ownerId: ownerA,
        query: 'roller',
      );
      expect(searchByName.length, equals(1));
      expect(searchByName.first.partNumber, equals('HT-TR-100'));
    });

    test('soft deletes a part and excludes it from active queries', () async {
      await db.partsDao.insertPart(
        SparePartsCompanion.insert(
          id: const Value('part_to_delete'),
          ownerId: ownerA,
          name: const Value('CTP O-Ring Kit'),
        ),
      );

      final beforeDelete = await db.partsDao.getActiveParts(ownerA);
      expect(beforeDelete.length, equals(1));

      // Soft delete
      await db.partsDao.softDeletePart('part_to_delete', ownerA);

      // Verify active queries exclude the part
      final afterDelete = await db.partsDao.getActiveParts(ownerA);
      expect(afterDelete, isEmpty);

      // Verify the record still exists in SQLite with deletedAt timestamp
      final rawPart = await (db.select(db.spareParts)
            ..where((t) => t.id.equals('part_to_delete')))
          .getSingle();
      expect(rawPart.deletedAt, isNotNull);
      expect(rawPart.syncStatus, equals(SyncStatus.pending));
    });
  });

  group('StockDao - Ledger Calculation', () {
    const partId = 'part_excavator_bucket';

    test('calculates stock balance as sum of stock movements', () async {
      // 1. Initial stock movement (+10)
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          ownerId: ownerA,
          partId: partId,
          type: MovementType.initial,
          quantityChange: 10.0,
          unitCost: const Value(5000.0),
        ),
      );

      // 2. Additional purchase movement (+5)
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          ownerId: ownerA,
          partId: partId,
          type: MovementType.purchase,
          quantityChange: 5.0,
          unitCost: const Value(5200.0),
        ),
      );

      // 3. Sale deduction movement (-3)
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          ownerId: ownerA,
          partId: partId,
          type: MovementType.sale,
          quantityChange: -3.0,
        ),
      );

      // Balance should be: 10 + 5 - 3 = 12
      final currentBalance =
          await db.stockDao.calculateStockForPart(partId, ownerA);
      expect(currentBalance, equals(12.0));
    });

    test('soft deleted stock movements are excluded from stock calculation', () async {
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          id: const Value('m1'),
          ownerId: ownerA,
          partId: partId,
          type: MovementType.initial,
          quantityChange: 15.0,
        ),
      );
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          id: const Value('m2_erroneous'),
          ownerId: ownerA,
          partId: partId,
          type: MovementType.adjustment,
          quantityChange: 5.0,
        ),
      );

      expect(await db.stockDao.calculateStockForPart(partId, ownerA), equals(20.0));

      // Soft delete erroneous movement
      await (db.update(db.stockMovements)..where((t) => t.id.equals('m2_erroneous')))
          .write(StockMovementsCompanion(deletedAt: Value(DateTime.now())));

      // Balance recalculates to 15.0
      expect(await db.stockDao.calculateStockForPart(partId, ownerA), equals(15.0));
    });
  });

  group('SalesDao - Atomic Transactions & Snapshots', () {
    test('records sale transaction with item snapshots and stock ledger deduction',
        () async {
      const saleId = 'sale_receipt_001';
      const partId = 'part_injector_01';

      // 1. Setup initial stock of 8 units
      await db.stockDao.insertMovement(
        StockMovementsCompanion.insert(
          ownerId: ownerA,
          partId: partId,
          type: MovementType.initial,
          quantityChange: 8.0,
          unitCost: const Value(1200.0),
        ),
      );

      // 2. Execute atomic sale transaction of 2 units
      await db.salesDao.recordSaleTransaction(
        sale: SalesCompanion.insert(
          id: const Value(saleId),
          ownerId: ownerA,
          receiptNumber: const Value('REC-2026-0001'),
          subtotal: 3600.0,
          discount: const Value(100.0),
          totalAmount: 3500.0,
          totalProfit: 1000.0, // (1800 - 1200) * 2 - 100 = 1100 (or computed)
          soldAt: Value(DateTime(2026, 10, 21, 14, 30)),
        ),
        items: [
          SaleItemsCompanion.insert(
            id: const Value('sale_item_01'),
            ownerId: ownerA,
            saleId: saleId,
            partId: partId,
            partNameSnapshot: 'Fuel Injector Nozzle',
            quantity: 2.0,
            unitCost: 1200.0,
            unitPrice: 1800.0,
            lineTotal: 3600.0,
            lineProfit: 1200.0,
          ),
        ],
      );

      // 3. Verify Sale Header is saved
      final activeSales = await db.salesDao.getActiveSales(ownerA);
      expect(activeSales.length, equals(1));
      expect(activeSales.first.receiptNumber, equals('REC-2026-0001'));

      // 4. Verify Sale Item snapshot
      final items = await db.salesDao.getSaleItems(saleId, ownerA);
      expect(items.length, equals(1));
      expect(items.first.partNameSnapshot, equals('Fuel Injector Nozzle'));
      expect(items.first.unitPrice, equals(1800.0));
      expect(items.first.unitCost, equals(1200.0));

      // 5. Verify stock deduction in ledger: 8 - 2 = 6
      final remainingStock =
          await db.stockDao.calculateStockForPart(partId, ownerA);
      expect(remainingStock, equals(6.0));
    });
  });

  group('SyncQueueDao & AppSettings', () {
    test('enqueues mutations, retrieves batch, and increments retry attempts', () async {
      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'p123',
        operation: SyncOperation.insert,
        payload: '{"name":"Gasket"}',
      );

      final batch = await db.syncQueueDao.getPendingBatch();
      expect(batch.length, equals(1));
      expect(batch.first.tableTarget, equals('spare_parts'));
      expect(batch.first.operation, equals(SyncOperation.insert));
      expect(batch.first.attempts, equals(0));

      // Record failure
      await db.syncQueueDao.recordAttemptFailure(batch.first.id, 'Connection timeout');
      final updatedBatch = await db.syncQueueDao.getPendingBatch();
      expect(updatedBatch.first.attempts, equals(1));
      expect(updatedBatch.first.lastError, equals('Connection timeout'));

      // Delete item
      await db.syncQueueDao.deleteItem(batch.first.id);
      expect(await db.syncQueueDao.getPendingBatch(), isEmpty);
    });

    test('sets, gets, and updates app settings', () async {
      await db.settingsDao.setSetting('printer_ip', '192.168.1.100');
      expect(await db.settingsDao.getSetting('printer_ip'), equals('192.168.1.100'));

      await db.settingsDao.setSetting('printer_ip', '192.168.1.105');
      expect(await db.settingsDao.getSetting('printer_ip'), equals('192.168.1.105'));

      await db.settingsDao.deleteSetting('printer_ip');
      expect(await db.settingsDao.getSetting('printer_ip'), isNull);
    });
  });
}
