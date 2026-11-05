import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/parts/data/datasources/parts_local_data_source.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/inventory_filter.dart';
import 'package:kera_spare_tracker/features/stock/data/repositories/local_stock_repository.dart';

void main() {
  group('Phase 2 - Offline Inventory (Repository Pattern & SQLite Streams)', () {
    late AppDatabase db;
    late PartsLocalDataSource localDataSource;
    late LocalPartsRepository partsRepository;
    late LocalStockRepository stockRepository;
    const testOwnerId = 'owner-phase2-test-01';

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(), testOwnerId);
      localDataSource = PartsLocalDataSource(db: db);
      partsRepository = LocalPartsRepository(db: db, localDataSource: localDataSource);
      stockRepository = LocalStockRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create part atomically saves to SQLite and enqueues outbox operation in ONE transaction', () async {
      final result = await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Toyota Oil Filter Heavy',
        partNumber: 'TOY-OF-101',
        purchasePrice: 400.0,
        sellingPrice: 750.0,
        lowStockLevel: 5.0,
        initialQuantity: 10.0,
      );

      expect(result.isSuccess, isTrue);
      final created = result.valueOrNull!;
      expect(created.name, equals('Toyota Oil Filter Heavy'));
      expect(created.cachedQuantity, equals(10.0));

      // Verify in SQLite
      final partInDb = await localDataSource.getPartById(testOwnerId, created.id);
      expect(partInDb, isNotNull);
      expect(partInDb!.name, equals('Toyota Oil Filter Heavy'));

      // Verify outbox queue has operations for spare_parts and initial stock movement
      final queueItems = await db.syncQueueDao.getPendingBatch();
      expect(queueItems.length, equals(2)); // 1 for part, 1 for initial movement
      expect(queueItems.any((q) => q.entityType == 'spare_parts'), isTrue);
      expect(queueItems.any((q) => q.entityType == 'stock_movements'), isTrue);
    });

    test('Update part updates SQLite and enqueues update operation in ONE transaction', () async {
      final createRes = await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Original Name',
        partNumber: 'PN-001',
        purchasePrice: 200.0,
        sellingPrice: 350.0,
      );
      final partId = createRes.valueOrNull!.id;

      // Clear previous queue items
      await db.syncQueueDao.clearQueue();

      final updateRes = await partsRepository.updatePart(
        ownerId: testOwnerId,
        id: partId,
        name: 'Updated Name',
        partNumber: 'PN-001-MOD',
        sellingPrice: 400.0,
      );

      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.valueOrNull!.name, equals('Updated Name'));

      final partInDb = await localDataSource.getPartById(testOwnerId, partId);
      expect(partInDb, isNotNull);
      expect(partInDb!.name, equals('Updated Name'));
      expect(partInDb.sellingPrice, equals(400.0));

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.operationType, equals('update'));
      expect(queue.first.entityId, equals(partId));
    });

    test('Delete part soft-deletes with tombstone and enqueues delete operation in ONE transaction', () async {
      final createRes = await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'To Delete',
        partNumber: 'DEL-01',
      );
      final partId = createRes.valueOrNull!.id;

      await db.syncQueueDao.clearQueue();

      final deleteRes = await partsRepository.deletePart(
        ownerId: testOwnerId,
        id: partId,
      );

      expect(deleteRes.isSuccess, isTrue);

      // Verify part is excluded from active parts
      final activeParts = await localDataSource.getActiveParts(testOwnerId);
      expect(activeParts.any((p) => p.id == partId), isFalse);

      // Verify tombstone in raw table
      final rawRow = await (db.select(db.spareParts)..where((t) => t.id.equals(partId))).getSingle();
      expect(rawRow.deletedAt, isNotNull);

      // Verify outbox has delete operation
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.operationType, equals('delete'));
    });

    test('Stock changes are strictly ledger movements sending DELTA (+5, -2), never absolute totals', () async {
      final createRes = await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Brake Disc',
        partNumber: 'BD-88',
        purchasePrice: 1000.0,
        sellingPrice: 1500.0,
        initialQuantity: 20.0,
      );
      final partId = createRes.valueOrNull!.id;
      await db.syncQueueDao.clearQueue();

      // Add 5 stock
      final addRes = await stockRepository.addStock(
        ownerId: testOwnerId,
        partId: partId,
        quantity: 5.0,
      );
      expect(addRes.isSuccess, isTrue);

      // Remove 2 stock
      final removeRes = await stockRepository.removeStock(
        ownerId: testOwnerId,
        partId: partId,
        quantity: 2.0,
      );
      expect(removeRes.isSuccess, isTrue);

      // Verify outbox contains ONLY stock_movement delta records
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(2));
      expect(queue.every((item) => item.entityType == 'stock_movements'), isTrue);

      // Check that delta (+5 and -2) is sent, NOT the running balance
      expect(queue[0].payload, contains('"quantity_change":5.0'));
      expect(queue[1].payload, contains('"quantity_change":-2.0'));

      // Check current local stock balance
      final updatedPart = await localDataSource.getPartById(testOwnerId, partId);
      expect(updatedPart, isNotNull);
      expect(updatedPart!.cachedQuantity, equals(23.0)); // 20 + 5 - 2
    });

    test('Offline search and filters evaluate correctly against local SQLite', () async {
      await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Bosch Fuel Pump',
        partNumber: 'FP-900',
        initialQuantity: 15.0,
        lowStockLevel: 5.0,
      );
      await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Air Filter Element',
        partNumber: 'AF-101',
        initialQuantity: 2.0, // Low stock
        lowStockLevel: 5.0,
      );
      await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Exhaust Gasket Ring',
        partNumber: 'EG-005',
        initialQuantity: 0.0, // Out of stock
        lowStockLevel: 5.0,
      );

      // Search by query
      final searchByName = await localDataSource.getPagedParts(
        ownerId: testOwnerId,
        filter: const InventoryFilter(query: 'pump'),
      );
      expect(searchByName.items.length, equals(1));
      expect(searchByName.items.first.name, equals('Bosch Fuel Pump'));

      // Filter Low stock
      final lowStockResult = await localDataSource.getPagedParts(
        ownerId: testOwnerId,
        filter: const InventoryFilter(stockFilter: StockFilter.lowStock),
      );
      expect(lowStockResult.items.length, equals(1));
      expect(lowStockResult.items.first.name, equals('Air Filter Element'));

      // Filter Out of stock
      final outOfStockResult = await localDataSource.getPagedParts(
        ownerId: testOwnerId,
        filter: const InventoryFilter(stockFilter: StockFilter.outOfStock),
      );
      expect(outOfStockResult.items.length, equals(1));
      expect(outOfStockResult.items.first.name, equals('Exhaust Gasket Ring'));
    });

    test('Local dashboard metrics are computed locally from SQLite without network', () async {
      await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Item A',
        partNumber: 'A-1',
        purchasePrice: 100.0,
        sellingPrice: 150.0,
        initialQuantity: 10.0,
        lowStockLevel: 5.0,
      );
      await partsRepository.createPart(
        ownerId: testOwnerId,
        name: 'Item B',
        partNumber: 'B-1',
        purchasePrice: 200.0,
        sellingPrice: 300.0,
        initialQuantity: 3.0, // Low stock
        lowStockLevel: 5.0,
      );

      final metrics = await localDataSource.getLocalDashboardMetrics(testOwnerId);
      expect(metrics.totalParts, equals(2));
      expect(metrics.totalQuantity, equals(13.0)); // 10 + 3
      expect(metrics.lowStockCount, equals(1));
      expect(metrics.outOfStockCount, equals(0));
      expect(metrics.inventoryPurchaseValue, equals(1600.0)); // 10*100 + 3*200
      expect(metrics.inventorySellingValue, equals(2400.0)); // 10*150 + 3*300
    });
  });
}
