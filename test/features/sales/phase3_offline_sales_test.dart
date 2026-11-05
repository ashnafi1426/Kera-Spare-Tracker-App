import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/datasources/parts_local_data_source.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/sales/data/repositories/local_sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';

void main() {
  group('Phase 3 - Offline Sales (Atomic Transactions, Unit Cost & Retry Safety)', () {
    late AppDatabase db;
    late PartsLocalDataSource partsLocalDataSource;
    late LocalPartsRepository partsRepo;
    late LocalSalesRepository salesRepo;
    const testOwnerId = 'owner-phase3-sales-01';

    setUp(() {
      db = AppDatabase(NativeDatabase.memory(), testOwnerId);
      partsLocalDataSource = PartsLocalDataSource(db: db);
      partsRepo = LocalPartsRepository(db: db, localDataSource: partsLocalDataSource);
      salesRepo = LocalSalesRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('One SQLite transaction validates locally, creates sale + items, stock movement, reduces stock, and enqueues ONE sale operation', () async {
      // Create spare part with purchase price 200, sell 350, stock 15
      final pRes = await partsRepo.createPart(
        ownerId: testOwnerId,
        name: 'Clutch Master Cylinder',
        partNumber: 'CMC-505',
        purchasePrice: 200.0,
        sellingPrice: 350.0,
        initialQuantity: 15.0,
      );
      final part = pRes.valueOrNull!;

      // Clear sync queue from part creation
      await db.syncQueueDao.clearQueue();

      // Record sale of 3 units
      final saleRes = await salesRepo.createSale(
        ownerId: testOwnerId,
        items: [SaleLineItem.fromPart(part, quantity: 3.0)],
        paymentMethod: 'Cash',
        notes: 'Counter sale',
      );

      expect(saleRes.isSuccess, isTrue);
      final sale = saleRes.valueOrNull!;
      expect(sale.totalAmount, equals(1050.0)); // 3 * 350
      expect(sale.totalProfit, equals(450.0)); // 3 * (350 - 200)

      // 1. Verify sale header in SQLite
      final saleInDb = await (db.select(db.sales)..where((t) => t.id.equals(sale.id))).getSingle();
      expect(saleInDb.totalAmount, equals(1050.0));
      expect(saleInDb.totalCost, equals(600.0)); // 3 * 200
      expect(saleInDb.totalProfit, equals(450.0));

      // 2. Verify sale items with historical unit_cost snapshot
      final itemsInDb = await (db.select(db.saleItems)..where((t) => t.saleId.equals(sale.id))).get();
      expect(itemsInDb.length, equals(1));
      expect(itemsInDb.first.unitCost, equals(200.0)); // Captured at sale time
      expect(itemsInDb.first.unitPrice, equals(350.0));
      expect(itemsInDb.first.quantity, equals(3.0));
      expect(itemsInDb.first.profit, equals(450.0));

      // 3. Verify stock movement ledger entry
      final movements = await (db.select(db.stockMovements)..where((t) => t.referenceId.equals(sale.id))).get();
      expect(movements.length, equals(1));
      expect(movements.first.quantityChange, equals(-3.0));
      expect(movements.first.type, equals(MovementType.sale));
      expect(movements.first.quantityBefore, equals(15.0));
      expect(movements.first.quantityAfter, equals(12.0));

      // 4. Verify local quantity was decremented
      final updatedPart = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(updatedPart!.cachedQuantity, equals(12.0)); // 15 - 3

      // 5. Verify exactly ONE atomic sale operation is enqueued in the outbox
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.entityType, equals('sales'));
      expect(queue.first.entityId, equals(sale.id));
      expect(queue.first.payload, contains('CMC-505'));
      expect(queue.first.payload, contains('"quantity":3.0'));
      expect(queue.first.payload, contains('"unit_cost":200.0'));
    });

    test('Retry-safe: Attempting to record a sale with the same saleId NEVER reduces stock twice', () async {
      final pRes = await partsRepo.createPart(
        ownerId: testOwnerId,
        name: 'Radiator Hose Upper',
        partNumber: 'RH-201',
        purchasePrice: 120.0,
        sellingPrice: 200.0,
        initialQuantity: 10.0,
      );
      final part = pRes.valueOrNull!;
      await db.syncQueueDao.clearQueue();

      const uniqueSaleId = 'retry-safe-sale-uuid-777';

      // 1. First execution
      final firstRes = await salesRepo.createSale(
        ownerId: testOwnerId,
        saleId: uniqueSaleId,
        items: [SaleLineItem.fromPart(part, quantity: 4.0)],
      );
      expect(firstRes.isSuccess, isTrue);

      final partAfterFirst = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(partAfterFirst!.cachedQuantity, equals(6.0)); // 10 - 4

      // 2. Retry execution with the same saleId (network retry or re-submission)
      final retryRes = await salesRepo.createSale(
        ownerId: testOwnerId,
        saleId: uniqueSaleId,
        items: [SaleLineItem.fromPart(part, quantity: 4.0)],
      );
      expect(retryRes.isSuccess, isTrue);

      // Verify stock was NOT reduced a second time
      final partAfterRetry = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(partAfterRetry!.cachedQuantity, equals(6.0)); // Remains 6.0, NEVER 2.0!

      // Verify ledger only has 1 sale movement, not 2
      final movements = await (db.select(db.stockMovements)
            ..where((t) => t.referenceId.equals(uniqueSaleId)))
          .get();
      expect(movements.length, equals(1));
    });

    test('Local stock validation prevents sale when quantity is insufficient', () async {
      final pRes = await partsRepo.createPart(
        ownerId: testOwnerId,
        name: 'Low Stock Item',
        partNumber: 'LSI-01',
        purchasePrice: 50.0,
        sellingPrice: 100.0,
        initialQuantity: 2.0,
      );
      final part = pRes.valueOrNull!;

      // Try to sell 5 units when only 2 are available
      final failRes = await salesRepo.createSale(
        ownerId: testOwnerId,
        items: [SaleLineItem.fromPart(part, quantity: 5.0)],
        forceAllowNegative: false,
      );

      expect(failRes.isFailure, isTrue);

      // Verify stock remained intact
      final intactPart = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(intactPart!.cachedQuantity, equals(2.0));
    });

    test('Sales are immutable; returns use returnSale operation to restore stock via positive ledger movements', () async {
      final pRes = await partsRepo.createPart(
        ownerId: testOwnerId,
        name: 'Shock Absorber Rear',
        partNumber: 'SA-901',
        purchasePrice: 800.0,
        sellingPrice: 1300.0,
        initialQuantity: 10.0,
      );
      final part = pRes.valueOrNull!;

      // Complete sale of 2 units
      final saleRes = await salesRepo.createSale(
        ownerId: testOwnerId,
        items: [SaleLineItem.fromPart(part, quantity: 2.0)],
      );
      final saleId = saleRes.valueOrNull!.id;

      final partAfterSale = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(partAfterSale!.cachedQuantity, equals(8.0)); // 10 - 2

      await db.syncQueueDao.clearQueue();

      // Return the sale
      final returnRes = await salesRepo.returnSale(
        ownerId: testOwnerId,
        saleId: saleId,
        reason: 'Customer brought back wrong part model',
      );
      expect(returnRes.isSuccess, isTrue);

      // Verify stock was restored via positive return movement
      final restoredPart = await partsLocalDataSource.getPartById(testOwnerId, part.id);
      expect(restoredPart!.cachedQuantity, equals(10.0)); // 8 + 2 = 10

      // Verify return ledger entry exists
      final returnMovements = await (db.select(db.stockMovements)
            ..where((t) => t.referenceId.equals('return_$saleId')))
          .get();
      expect(returnMovements.length, equals(1));
      expect(returnMovements.first.quantityChange, equals(2.0));
      expect(returnMovements.first.type, equals(MovementType.returned));

      // Verify original sale amounts remain IMMUTABLE
      final saleInDb = await (db.select(db.sales)..where((t) => t.id.equals(saleId))).getSingle();
      expect(saleInDb.totalAmount, equals(2600.0)); // Still 2600.0!
      expect(saleInDb.notes, contains('RETURNED'));

      // Verify return operation was enqueued to outbox
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.entityType == 'sale_returns'), isTrue);
    });
  });
}

