import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/database_manager.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';

void main() {
  group('Phase 1 - Local Database per Owner & Outbox Schema Tests', () {
    late AppDatabase db;
    const testOwnerId = 'owner-uuid-kera-101';

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(), testOwnerId);
    });

    tearDown(() async {
      await db.close();
    });

    test('DatabaseManager produces isolated database names per owner', () {
      final nameOwner1 = DatabaseManager.getDatabaseFileName('owner_123');
      final nameOwner2 = DatabaseManager.getDatabaseFileName('owner_456');
      final nameDefault = DatabaseManager.getDatabaseFileName(null);

      expect(nameOwner1, equals('kera_owner_owner_123.sqlite'));
      expect(nameOwner2, equals('kera_owner_owner_456.sqlite'));
      expect(nameDefault, equals('kera_spare_tracker.sqlite'));
      expect(nameOwner1, isNot(equals(nameOwner2)));
    });

    test('spare_parts table contains all required Phase 1 fields', () async {
      final partId = const Uuid().v4();
      final insertResult = await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              id: Value(partId),
              ownerId: testOwnerId,
              serverId: const Value('srv-part-999'),
              name: const Value('Brembo Brake Pads'),
              partNumber: const Value('BP-9988'),
              photoLocalPath: const Value('/data/user/0/photos/part1.jpg'),
              photoUrl: const Value('https://s3.aws.com/parts/part1.jpg'),
              brand: const Value('Brembo'),
              category: const Value('Braking System'),
              description: const Value('Ceramic performance brake pads'),
              unit: const Value('Set'),
              quantity: const Value(25.0),
              purchasePrice: const Value(1200.0),
              sellingPrice: const Value(1850.0),
              storageLocation: const Value('Shelf A3'),
              customLocation: const Value('Near rear counter'),
              notes: const Value('Fits Toyota Land Cruiser HZJ79'),
              specifications: const Value('Thickness 16.5mm'),
              minimumStock: const Value(5.0),
              serverVersion: const Value(2),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

      expect(insertResult, isPositive);

      final fetched = await (db.select(db.spareParts)
            ..where((t) => t.id.equals(partId)))
          .getSingle();

      expect(fetched.id, equals(partId));
      expect(fetched.serverId, equals('srv-part-999'));
      expect(fetched.ownerId, equals(testOwnerId));
      expect(fetched.name, equals('Brembo Brake Pads'));
      expect(fetched.partNumber, equals('BP-9988'));
      expect(fetched.photoLocalPath, equals('/data/user/0/photos/part1.jpg'));
      expect(fetched.photoUrl, equals('https://s3.aws.com/parts/part1.jpg'));
      expect(fetched.brand, equals('Brembo'));
      expect(fetched.category, equals('Braking System'));
      expect(fetched.unit, equals('Set'));
      expect(fetched.quantity, equals(25.0));
      expect(fetched.purchasePrice, equals(1200.0));
      expect(fetched.sellingPrice, equals(1850.0));
      expect(fetched.storageLocation, equals('Shelf A3'));
      expect(fetched.customLocation, equals('Near rear counter'));
      expect(fetched.notes, equals('Fits Toyota Land Cruiser HZJ79'));
      expect(fetched.specifications, equals('Thickness 16.5mm'));
      expect(fetched.minimumStock, equals(5.0));
      expect(fetched.serverVersion, equals(2));
      expect(fetched.syncStatus, equals(SyncStatus.pending));
    });

    test('sales and sale_items tables contain all required Phase 1 fields',
        () async {
      final saleId = const Uuid().v4();
      final saleItemId = const Uuid().v4();
      final partId = const Uuid().v4();
      final now = DateTime.now();

      await db.into(db.sales).insert(
            SalesCompanion.insert(
              id: Value(saleId),
              ownerId: testOwnerId,
              serverId: const Value('srv-sale-101'),
              saleNumber: const Value('SL-2026-0001'),
              receiptNumber: const Value('REC-001'),
              totalAmount: 5000.0,
              totalCost: const Value(3500.0),
              totalProfit: 1500.0,
              paymentMethod: const Value('Cash'),
              saleDate: Value(now),
              subtotal: 5000.0,
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

      await db.into(db.saleItems).insert(
            SaleItemsCompanion.insert(
              id: Value(saleItemId),
              ownerId: testOwnerId,
              serverId: const Value('srv-item-501'),
              saleId: saleId,
              partId: partId,
              sparePartId: Value(partId),
              partNameSnapshot: 'Clutch Disc Hilux',
              quantity: 2.0,
              unitCost: 1750.0,
              unitPrice: 2500.0,
              lineTotal: 5000.0,
              subtotal: const Value(5000.0),
              lineProfit: 1500.0,
              profit: const Value(1500.0),
            ),
          );

      final fetchedSale = await (db.select(db.sales)
            ..where((t) => t.id.equals(saleId)))
          .getSingle();

      expect(fetchedSale.id, equals(saleId));
      expect(fetchedSale.serverId, equals('srv-sale-101'));
      expect(fetchedSale.saleNumber, equals('SL-2026-0001'));
      expect(fetchedSale.totalAmount, equals(5000.0));
      expect(fetchedSale.totalCost, equals(3500.0));
      expect(fetchedSale.totalProfit, equals(1500.0));
      expect(fetchedSale.paymentMethod, equals('Cash'));

      final fetchedItem = await (db.select(db.saleItems)
            ..where((t) => t.id.equals(saleItemId)))
          .getSingle();

      expect(fetchedItem.saleId, equals(saleId));
      expect(fetchedItem.sparePartId, equals(partId));
      expect(fetchedItem.quantity, equals(2.0));
      expect(fetchedItem.unitCost, equals(1750.0));
      expect(fetchedItem.unitPrice, equals(2500.0));
      expect(fetchedItem.profit, equals(1500.0));
    });

    test('stock_movements ledger contains all required Phase 1 fields',
        () async {
      final movementId = const Uuid().v4();
      final partId = const Uuid().v4();

      await db.into(db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: Value(movementId),
              ownerId: testOwnerId,
              partId: partId,
              sparePartId: Value(partId),
              type: MovementType.sale,
              movementType: const Value('sale'),
              quantityChange: -3.0,
              quantityBefore: const Value(10.0),
              quantityAfter: const Value(7.0),
              referenceId: const Value('ref-sale-123'),
              note: const Value('Sold at front counter'),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

      final movement = await (db.select(db.stockMovements)
            ..where((t) => t.id.equals(movementId)))
          .getSingle();

      expect(movement.id, equals(movementId));
      expect(movement.ownerId, equals(testOwnerId));
      expect(movement.sparePartId, equals(partId));
      expect(movement.type, equals(MovementType.sale));
      expect(movement.quantityChange, equals(-3.0));
      expect(movement.quantityBefore, equals(10.0));
      expect(movement.quantityAfter, equals(7.0));
      expect(movement.referenceId, equals('ref-sale-123'));
    });

    test('sync_queue outbox and sync_state operate correctly with cursors',
        () async {
      final opId = const Uuid().v4();

      await db.syncQueueDao.enqueueOperation(
        operationId: opId,
        ownerId: testOwnerId,
        entityType: 'spare_parts',
        entityId: 'part-uuid-1',
        operationType: 'insert',
        baseVersion: 1,
        payload: '{"name":"Fuel Filter"}',
        dependsOn: null,
      );

      final hasUnsynced = await db.syncQueueDao.hasUnsyncedChanges();
      expect(hasUnsynced, isTrue);

      final count = await db.syncQueueDao.countPending();
      expect(count, equals(1));

      // Claim batch for single flight
      final batch = await db.syncQueueDao.claimBatch(limit: 10);
      expect(batch.length, equals(1));
      expect(batch.first.operationId, equals(opId));
      expect(batch.first.queueStatus, equals('in_progress'));
      expect(batch.first.claimedAt, isNotNull);

      // Save and retrieve sync state cursor
      await db.syncQueueDao
          .saveSyncCursor(testOwnerId, '2026-11-05T10:00:00.000Z');
      final state = await db.syncQueueDao.getSyncState(testOwnerId);
      expect(state, isNotNull);
      expect(state!.ownerId, equals(testOwnerId));
      expect(state.lastPullCursor, equals('2026-11-05T10:00:00.000Z'));
      expect(state.lastSuccessAt, isNotNull);

      // Mark operation as synced
      await db.syncQueueDao.markOperationSynced(opId);
      final remaining = await db.syncQueueDao.countPending();
      expect(remaining, equals(0));
    });

    test('foreign keys are enforced in SQLite', () async {
      final result = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      final fkEnabled = result.data.values.first;
      expect(fkEnabled, equals(1));
    });
  });
}

