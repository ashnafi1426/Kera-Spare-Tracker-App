import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/sales/data/repositories/local_sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';
import 'package:kera_spare_tracker/features/stock/data/repositories/local_stock_repository.dart';

void main() {
  late AppDatabase db;
  late LocalPartsRepository partsRepo;
  late LocalStockRepository stockRepo;
  late LocalSalesRepository salesRepo;

  const ownerId = 'owner_kera_sales_01';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    partsRepo = LocalPartsRepository(db: db);
    stockRepo = LocalStockRepository(db: db);
    salesRepo = LocalSalesRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SalesRepository - Core Sales Recording & Snapshots', () {
    test(
        'sale of 3 items updates stock correctly, profit equals sum of line profits, and snapshots are preserved',
        () async {
      // 1. Create 3 parts with varying price configurations
      // Part 1: Cost 100, Selling 150, Stock 10
      final p1Res = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Oil Filter 1R-0716',
        purchasePrice: 100.0,
        sellingPrice: 150.0,
        initialQuantity: 10.0,
      );
      final p1 = p1Res.valueOrNull!;

      // Part 2: Cost 200, Selling 300, Stock 5
      final p2Res = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Fuel Filter 9T-0988',
        purchasePrice: 200.0,
        sellingPrice: 300.0,
        initialQuantity: 5.0,
      );
      final p2 = p2Res.valueOrNull!;

      // Part 3: No purchase price (treated as cost 0), Selling 50, Stock 20
      final p3Res = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'O-Ring Seal Standard',
        sellingPrice: 50.0,
        initialQuantity: 20.0,
      );
      final p3 = p3Res.valueOrNull!;

      // 2. Prepare cart with 3 items:
      // Line 1: p1, qty = 2, default price 150 -> lineTotal = 300, lineProfit = 100
      // Line 2: p2, qty = 1, overridden price 320 -> lineTotal = 320, lineProfit = 120
      // Line 3: p3, qty = 4, default price 50, cost 0 -> lineTotal = 200, lineProfit = 200
      final items = [
        SaleLineItem.fromPart(p1, quantity: 2.0),
        SaleLineItem.fromPart(p2, quantity: 1.0).copyWith(unitPrice: 320.0),
        SaleLineItem.fromPart(p3, quantity: 4.0),
      ];

      expect(items[0].lineTotal, equals(300.0));
      expect(items[0].lineProfit, equals(100.0));

      expect(items[1].lineTotal, equals(320.0));
      expect(items[1].lineProfit, equals(120.0));

      expect(items[2].lineTotal, equals(200.0));
      expect(items[2].lineProfit, equals(200.0));
      expect(items[2].hasNoCostWarning, isTrue);

      const expectedTotalAmount = 300.0 + 320.0 + 200.0; // 820.0
      const expectedTotalProfit = 100.0 + 120.0 + 200.0; // 420.0

      // 3. Complete the sale in one transaction
      final saleRes = await salesRepo.createSale(
        ownerId: ownerId,
        items: items,
        notes: 'Walk-in cash customer',
        paymentMethod: 'Cash',
      );

      expect(saleRes.isSuccess, isTrue);
      final sale = saleRes.valueOrNull!;

      expect(sale.totalAmount, equals(expectedTotalAmount));
      expect(sale.totalProfit, equals(expectedTotalProfit));
      expect(sale.receiptNumber, isNotNull);
      expect(sale.receiptNumber, startsWith('REC-'));
      expect(sale.items.length, equals(3));

      // 4. Verify stock deductions on spare_parts.cached_quantity
      final p1Updated = await db.partsDao.getPartById(p1.id, ownerId);
      final p2Updated = await db.partsDao.getPartById(p2.id, ownerId);
      final p3Updated = await db.partsDao.getPartById(p3.id, ownerId);

      expect(p1Updated?.cachedQuantity, equals(8.0)); // 10 - 2
      expect(p2Updated?.cachedQuantity, equals(4.0)); // 5 - 1
      expect(p3Updated?.cachedQuantity, equals(16.0)); // 20 - 4

      // 5. Verify ledger movements (negative changes of type sale linked by referenceId)
      final p1Movements = await db.stockDao.getMovementsForPart(p1.id, ownerId);
      final p1SaleMovement = p1Movements.firstWhere((m) => m.type == MovementType.sale);
      expect(p1SaleMovement.quantityChange, equals(-2.0));
      expect(p1SaleMovement.referenceId, equals(sale.id));

      final p2Movements = await db.stockDao.getMovementsForPart(p2.id, ownerId);
      final p2SaleMovement = p2Movements.firstWhere((m) => m.type == MovementType.sale);
      expect(p2SaleMovement.quantityChange, equals(-1.0));
      expect(p2SaleMovement.referenceId, equals(sale.id));

      // Ledger sums must exactly match cached quantities
      expect(await db.stockDao.calculateStockForPart(p1.id, ownerId), equals(8.0));
      expect(await db.stockDao.calculateStockForPart(p2.id, ownerId), equals(4.0));
      expect(await db.stockDao.calculateStockForPart(p3.id, ownerId), equals(16.0));

      // 6. Test Snapshot Preservation: Change p1's name, sellingPrice, and purchasePrice later
      await partsRepo.updatePart(
        ownerId: ownerId,
        id: p1.id,
        name: 'Completely Renamed Filter',
        sellingPrice: 9999.0,
        purchasePrice: 8888.0,
      );

      // Verify the sale lines retain original snapshot values
      final fetchedSaleRes = await salesRepo.getSaleById(ownerId: ownerId, saleId: sale.id);
      expect(fetchedSaleRes.isSuccess, isTrue);
      final fetchedSale = fetchedSaleRes.valueOrNull!;

      final line1 = fetchedSale.items.firstWhere((i) => i.partId == p1.id);
      expect(line1.partNameSnapshot, equals('Oil Filter 1R-0716'));
      expect(line1.unitPrice, equals(150.0));
      expect(line1.unitCost, equals(100.0));
      expect(line1.lineTotal, equals(300.0));
      expect(line1.lineProfit, equals(100.0));
      expect(fetchedSale.totalAmount, equals(820.0));
      expect(fetchedSale.totalProfit, equals(420.0));
    });

    test('enqueues sales, sale_items, stock_movements, and spare_parts to sync_queue',
        () async {
      final pRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Spark Plug',
        initialQuantity: 10.0,
        sellingPrice: 80.0,
      );
      final part = pRes.valueOrNull!;

      // Clear sync queue from initial part creation
      await db.delete(db.syncQueue).go();

      final res = await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 2.0)],
      );
      expect(res.isSuccess, isTrue);

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.tableTarget == 'sales' && q.operation == SyncOperation.insert), isTrue);
      expect(queue.any((q) => q.tableTarget == 'sale_items' && q.operation == SyncOperation.insert), isTrue);
      expect(queue.any((q) => q.tableTarget == 'stock_movements' && q.operation == SyncOperation.insert), isTrue);
      expect(queue.any((q) => q.tableTarget == 'spare_parts' && q.operation == SyncOperation.update), isTrue);
    });
  });

  group('SalesRepository - Validation & Negative Stock Rules', () {
    test('blocks empty sale', () async {
      final res = await salesRepo.createSale(
        ownerId: ownerId,
        items: [],
      );
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
    });

    test('blocks sale with invalid non-positive quantity or negative price', () async {
      final pRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Belt',
        initialQuantity: 5.0,
        sellingPrice: 100.0,
      );
      final part = pRes.valueOrNull!;

      final zeroQtyRes = await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 0.0)],
      );
      expect(zeroQtyRes.isFailure, isTrue);

      final negPriceRes = await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 1.0).copyWith(unitPrice: -10.0)],
      );
      expect(negPriceRes.isFailure, isTrue);
    });

    test('blocks sale exceeding current stock when allow_negative_stock is false',
        () async {
      await stockRepo.setAllowNegativeStock(false);

      final pRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Heavy Duty Alternator',
        initialQuantity: 2.0,
        sellingPrice: 1200.0,
      );
      final part = pRes.valueOrNull!;

      // Attempt to sell 3 units when only 2 in stock
      final res = await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 3.0)],
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<NegativeStockFailure>());
      expect((res.failureOrNull as NegativeStockFailure).projectedStock, equals(-1.0));

      // Verify no sale was recorded and stock was not decremented
      final sales = await db.salesDao.getActiveSales(ownerId);
      expect(sales.isEmpty, isTrue);
      final partInDb = await db.partsDao.getPartById(part.id, ownerId);
      expect(partInDb?.cachedQuantity, equals(2.0));
    });

    test('allows sale exceeding stock when forceAllowNegative is true (owner confirmed)',
        () async {
      await stockRepo.setAllowNegativeStock(false);

      final pRes = await partsRepo.createPart(
        ownerId: ownerId,
        name: 'Alternator',
        initialQuantity: 2.0,
        sellingPrice: 1200.0,
      );
      final part = pRes.valueOrNull!;

      final res = await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 5.0)],
        forceAllowNegative: true,
      );

      expect(res.isSuccess, isTrue);
      final partInDb = await db.partsDao.getPartById(part.id, ownerId);
      expect(partInDb?.cachedQuantity, equals(-3.0)); // 2 - 5
    });
  });
}
