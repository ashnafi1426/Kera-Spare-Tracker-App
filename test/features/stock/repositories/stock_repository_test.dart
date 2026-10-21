import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/stock/data/repositories/local_stock_repository.dart';

void main() {
  late AppDatabase db;
  late LocalPartsRepository partsRepo;
  late LocalStockRepository stockRepo;

  const ownerId = 'owner_kera_101';
  const otherOwnerId = 'owner_kera_999';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    partsRepo = LocalPartsRepository(db: db);
    stockRepo = LocalStockRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StockRepository - Add Stock (Purchase)', () {
    test('adds stock, updates cached_quantity atomically, and enqueues sync records',
        () async {
      // 1. Create a part with initial quantity 10
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Oil Filter 1R-0716',
        initialQuantity: 10.0,
        purchasePrice: 250.0,
      );
      expect(partRes.isSuccess, isTrue);
      final partId = partRes.valueOrNull!.id;

      // 2. Add 15 units (purchase)
      final addRes = await stockRepo.addStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 15.0,
        unitCost: 260.0,
        note: 'Delivered by supplier A',
      );

      expect(addRes.isSuccess, isTrue);
      final movement = addRes.valueOrNull!;
      expect(movement.type, equals(MovementType.purchase));
      expect(movement.quantityChange, equals(15.0));
      expect(movement.unitCost, equals(260.0));
      expect(movement.note, equals('Delivered by supplier A'));
      expect(movement.runningBalance, equals(25.0));

      // 3. Verify cached quantity in database is exactly 25.0
      final updatedPart = await db.partsDao.getPartById(partId, ownerId);
      expect(updatedPart?.cachedQuantity, equals(25.0));

      // 4. Verify ledger sum matches cached quantity
      final ledgerSum = await db.stockDao.calculateStockForPart(partId, ownerId);
      expect(ledgerSum, equals(25.0));

      // 5. Verify sync_queue contains both movement and part update
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(
        queue.any((q) =>
            q.tableTarget == 'stock_movements' &&
            q.operation == SyncOperation.insert),
        isTrue,
      );
      expect(
        queue.any((q) =>
            q.tableTarget == 'spare_parts' &&
            q.operation == SyncOperation.update &&
            q.recordId == partId),
        isTrue,
      );
    });

    test('rejects adding zero or negative quantity', () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Brake Pad Set',
      );
      final partId = partRes.valueOrNull!.id;

      final zeroRes = await stockRepo.addStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 0.0,
      );
      expect(zeroRes.isFailure, isTrue);
      expect(zeroRes.failureOrNull, isA<ValidationFailure>());

      final negRes = await stockRepo.addStock(
        ownerId: ownerId,
        partId: partId,
        quantity: -5.0,
      );
      expect(negRes.isFailure, isTrue);
      expect(negRes.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('StockRepository - Remove Stock', () {
    test('removes stock, writes negative ledger change, and decrements cached quantity',
        () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Alternator Belt',
        initialQuantity: 20.0,
      );
      final partId = partRes.valueOrNull!.id;

      final removeRes = await stockRepo.removeStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 8.0,
        note: 'Damaged during storage',
      );

      expect(removeRes.isSuccess, isTrue);
      final movement = removeRes.valueOrNull!;
      expect(movement.type, equals(MovementType.adjustment));
      expect(movement.quantityChange, equals(-8.0));
      expect(movement.runningBalance, equals(12.0));
      expect(movement.note, equals('Damaged during storage'));

      final updatedPart = await db.partsDao.getPartById(partId, ownerId);
      expect(updatedPart?.cachedQuantity, equals(12.0));

      final ledgerSum = await db.stockDao.calculateStockForPart(partId, ownerId);
      expect(ledgerSum, equals(12.0));
    });

    test('rejects removing zero or negative quantity', () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Fuel Filter',
        initialQuantity: 5.0,
      );
      final partId = partRes.valueOrNull!.id;

      final res = await stockRepo.removeStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 0.0,
      );
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('StockRepository - Adjust to Counted Number', () {
    test('adjusts upwards when counted quantity > current stock', () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Air Filter',
        initialQuantity: 10.0,
      );
      final partId = partRes.valueOrNull!.id;

      // Counted 14 (difference +4)
      final adjustRes = await stockRepo.adjustStock(
        ownerId: ownerId,
        partId: partId,
        countedQuantity: 14.0,
        note: 'Monthly physical count',
      );

      expect(adjustRes.isSuccess, isTrue);
      final movement = adjustRes.valueOrNull!;
      expect(movement.type, equals(MovementType.adjustment));
      expect(movement.quantityChange, equals(4.0));
      expect(movement.runningBalance, equals(14.0));

      final updatedPart = await db.partsDao.getPartById(partId, ownerId);
      expect(updatedPart?.cachedQuantity, equals(14.0));

      final ledgerSum = await db.stockDao.calculateStockForPart(partId, ownerId);
      expect(ledgerSum, equals(14.0));
    });

    test('adjusts downwards when counted quantity < current stock', () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Spark Plug Pack',
        initialQuantity: 30.0,
      );
      final partId = partRes.valueOrNull!.id;

      // Counted 22 (difference -8)
      final adjustRes = await stockRepo.adjustStock(
        ownerId: ownerId,
        partId: partId,
        countedQuantity: 22.0,
        note: 'Audit correction',
      );

      expect(adjustRes.isSuccess, isTrue);
      final movement = adjustRes.valueOrNull!;
      expect(movement.type, equals(MovementType.adjustment));
      expect(movement.quantityChange, equals(-8.0));
      expect(movement.runningBalance, equals(22.0));

      final updatedPart = await db.partsDao.getPartById(partId, ownerId);
      expect(updatedPart?.cachedQuantity, equals(22.0));

      final ledgerSum = await db.stockDao.calculateStockForPart(partId, ownerId);
      expect(ledgerSum, equals(22.0));
    });
  });

  group('StockRepository - Negative Stock Rule', () {
    test('blocks removeStock when resulting quantity < 0 and allow_negative_stock is false',
        () async {
      // Default setting is false
      expect(await stockRepo.getAllowNegativeStock(), isFalse);

      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Engine Valve',
        initialQuantity: 5.0,
      );
      final partId = partRes.valueOrNull!.id;

      // Attempt to remove 7 (would result in -2)
      final removeRes = await stockRepo.removeStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 7.0,
      );

      expect(removeRes.isFailure, isTrue);
      expect(removeRes.failureOrNull, isA<NegativeStockFailure>());
      final failure = removeRes.failureOrNull as NegativeStockFailure;
      expect(failure.projectedStock, equals(-2.0));

      // Stock remains untouched at 5.0
      final part = await db.partsDao.getPartById(partId, ownerId);
      expect(part?.cachedQuantity, equals(5.0));
      expect(await db.stockDao.calculateStockForPart(partId, ownerId), equals(5.0));
    });

    test('allows removeStock when forceAllowNegative is true (owner confirmed)',
        () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Engine Valve',
        initialQuantity: 5.0,
      );
      final partId = partRes.valueOrNull!.id;

      // Removing with confirmation flag
      final removeRes = await stockRepo.removeStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 8.0,
        forceAllowNegative: true,
      );

      expect(removeRes.isSuccess, isTrue);
      expect(removeRes.valueOrNull!.runningBalance, equals(-3.0));

      final part = await db.partsDao.getPartById(partId, ownerId);
      expect(part?.cachedQuantity, equals(-3.0));
      expect(await db.stockDao.calculateStockForPart(partId, ownerId), equals(-3.0));
    });

    test('allows removeStock when allow_negative_stock setting is enabled in AppSettings',
        () async {
      await stockRepo.setAllowNegativeStock(true);
      expect(await stockRepo.getAllowNegativeStock(), isTrue);

      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Transmission Bearing',
        initialQuantity: 3.0,
      );
      final partId = partRes.valueOrNull!.id;

      final removeRes = await stockRepo.removeStock(
        ownerId: ownerId,
        partId: partId,
        quantity: 5.0,
      );

      expect(removeRes.isSuccess, isTrue);
      expect(removeRes.valueOrNull!.runningBalance, equals(-2.0));

      final part = await db.partsDao.getPartById(partId, ownerId);
      expect(part?.cachedQuantity, equals(-2.0));
      expect(await db.stockDao.calculateStockForPart(partId, ownerId), equals(-2.0));
    });

    test('blocks adjustStock to negative number when setting is false',
        () async {
      await stockRepo.setAllowNegativeStock(false);

      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Hydraulic Hose',
        initialQuantity: 10.0,
      );
      final partId = partRes.valueOrNull!.id;

      final adjustRes = await stockRepo.adjustStock(
        ownerId: ownerId,
        partId: partId,
        countedQuantity: -4.0,
      );

      expect(adjustRes.isFailure, isTrue);
      expect(adjustRes.failureOrNull, isA<NegativeStockFailure>());
      expect((adjustRes.failureOrNull as NegativeStockFailure).projectedStock, equals(-4.0));
    });
  });

  group('StockRepository - Recalculate Cached Quantity Integrity Check', () {
    test('restores cached_quantity to exact ledger sum after drift or tampering',
        () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Clutch Disc',
        initialQuantity: 10.0,
      );
      final partId = partRes.valueOrNull!.id;

      // Add 20 -> stock = 30
      await stockRepo.addStock(ownerId: ownerId, partId: partId, quantity: 20.0);
      // Remove 5 -> stock = 25
      await stockRepo.removeStock(ownerId: ownerId, partId: partId, quantity: 5.0);

      // Verify legitimate state
      expect(await db.stockDao.calculateStockForPart(partId, ownerId), equals(25.0));

      // Simulate corruption/drift directly on spare_parts table
      await db.partsDao.updateCachedQuantity(partId, 999.0);
      var corruptedPart = await db.partsDao.getPartById(partId, ownerId);
      expect(corruptedPart?.cachedQuantity, equals(999.0));

      // Run recalculation integrity check
      final recalcRes = await stockRepo.recalculateCachedQuantity(
        ownerId: ownerId,
        partId: partId,
      );

      expect(recalcRes.isSuccess, isTrue);
      expect(recalcRes.valueOrNull, equals(25.0));

      // Verify cachedQuantity in DB is restored to exact ledger sum
      final restoredPart = await db.partsDao.getPartById(partId, ownerId);
      expect(restoredPart?.cachedQuantity, equals(25.0));
    });
  });

  group('StockRepository - Movement History & Running Balance', () {
    test('calculates accurate chronological running balances across multiple operations',
        () async {
      final partRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Radiator Cap',
        initialQuantity: 10.0,
      );
      final partId = partRes.valueOrNull!.id;

      // 1. Initial stock: 10 (bal: 10)
      // 2. Add: 5 (bal: 15)
      await stockRepo.addStock(ownerId: ownerId, partId: partId, quantity: 5.0, note: 'Shipment 1');
      // 3. Remove: 3 (bal: 12)
      await stockRepo.removeStock(ownerId: ownerId, partId: partId, quantity: 3.0, note: 'Sale 1');
      // 4. Adjust: count 20 (delta: +8, bal: 20)
      await stockRepo.adjustStock(ownerId: ownerId, partId: partId, countedQuantity: 20.0, note: 'Recount');

      final historyRes = await stockRepo.getMovementsWithBalance(
        ownerId: ownerId,
        partId: partId,
      );

      expect(historyRes.isSuccess, isTrue);
      final history = historyRes.valueOrNull!;
      expect(history.length, equals(4));

      // Ordered descending (newest first)
      // Latest: Adjust to 20 (delta +8, running balance 20)
      expect(history[0].type, equals(MovementType.adjustment));
      expect(history[0].quantityChange, equals(8.0));
      expect(history[0].runningBalance, equals(20.0));

      // Second latest: Remove 3 (delta -3, running balance 12)
      expect(history[1].type, equals(MovementType.adjustment));
      expect(history[1].quantityChange, equals(-3.0));
      expect(history[1].runningBalance, equals(12.0));

      // Third latest: Add 5 (delta +5, running balance 15)
      expect(history[2].type, equals(MovementType.purchase));
      expect(history[2].quantityChange, equals(5.0));
      expect(history[2].runningBalance, equals(15.0));

      // Oldest: Initial 10 (running balance 10)
      expect(history[3].type, equals(MovementType.initial));
      expect(history[3].quantityChange, equals(10.0));
      expect(history[3].runningBalance, equals(10.0));
    });
  });

  group('StockRepository - Low Stock Parts Query', () {
    test('retrieves parts at or below low stock threshold for current owner only',
        () async {
      // Part 1: lowStockLevel = 10, current = 8 -> LOW STOCK
      await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Low Stock Part A',
        initialQuantity: 8.0,
        lowStockLevel: 10.0,
      );

      // Part 2: lowStockLevel = 5, current = 12 -> HEALTHY
      await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Healthy Stock Part B',
        initialQuantity: 12.0,
        lowStockLevel: 5.0,
      );

      // Part 3: lowStockLevel is null, current = 3 (default <= 5) -> LOW STOCK
      await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Default Low Stock Part C',
        initialQuantity: 3.0,
      );

      // Part 4: Belonging to other owner -> Should NOT appear
      await partsRepo.createPart(
        ownerId: otherOwnerId,
        name: 'Other Owner Low Part',
        initialQuantity: 1.0,
      );

      final lowPartsRes = await stockRepo.getLowStockParts(ownerId: ownerId);
      expect(lowPartsRes.isSuccess, isTrue);
      final lowParts = lowPartsRes.valueOrNull!;

      expect(lowParts.length, equals(2));
      final names = lowParts.map((p) => p.name).toList();
      expect(names, contains('Low Stock Part A'));
      expect(names, contains('Default Low Stock Part C'));
      expect(names, isNot(contains('Healthy Stock Part B')));
      expect(names, isNot(contains('Other Owner Low Part')));
    });
  });
}
