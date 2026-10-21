import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/date_range_filter.dart';
import 'package:kera_spare_tracker/features/sales/data/repositories/local_sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sales_day_group.dart';

void main() {
  late AppDatabase db;
  late LocalSalesRepository salesRepo;
  late LocalPartsRepository partsRepo;

  const ownerId = 'owner_history_test';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    salesRepo = LocalSalesRepository(db: db);
    partsRepo = LocalPartsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<PartItem> insertPart({
    required String name,
    required double qty,
    required double purchasePrice,
    required double sellingPrice,
  }) async {
    final res = await partsRepo.createPart(
      ownerId: ownerId,
      name: name,
      partNumber: 'PN-$name',
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      initialQuantity: qty,
      lowStockLevel: 2.0,
    );
    return res.valueOrNull!;
  }

  group('Sales History - Search, Date Filter, and Day Grouping', () {
    test('search sales by item name matches sales containing that part', () async {
      final p1 = await insertPart(name: 'Fuel Injector', qty: 20, purchasePrice: 400, sellingPrice: 600);
      final p2 = await insertPart(name: 'Cabin Filter', qty: 20, purchasePrice: 150, sellingPrice: 250);

      // Sale 1 contains Fuel Injector
      final sale1 = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(p1, quantity: 2)],
      )).valueOrNull!;

      // Sale 2 contains Cabin Filter
      final sale2 = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(p2, quantity: 1)],
      )).valueOrNull!;

      // Search by "Injector"
      final injectorSales = await salesRepo
          .watchFilteredSales(ownerId: ownerId, query: 'Injector')
          .first;

      expect(injectorSales.length, 1);
      expect(injectorSales.first.id, sale1.id);

      // Search by "Filter"
      final filterSales = await salesRepo
          .watchFilteredSales(ownerId: ownerId, query: 'Filter')
          .first;

      expect(filterSales.length, 1);
      expect(filterSales.first.id, sale2.id);

      // Search by non-existent item
      final noneSales = await salesRepo
          .watchFilteredSales(ownerId: ownerId, query: 'Alternator')
          .first;

      expect(noneSales.isEmpty, true);
    });

    test('search sales by receipt number', () async {
      final part = await insertPart(name: 'Gasket Set', qty: 10, purchasePrice: 50, sellingPrice: 100);
      final sale = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 1)],
      )).valueOrNull!;

      final receiptPart = sale.receiptNumber!.substring(0, 4);
      final matchedSales = await salesRepo
          .watchFilteredSales(ownerId: ownerId, query: receiptPart)
          .first;

      expect(matchedSales.isNotEmpty, true);
      expect(matchedSales.first.id, sale.id);
    });

    test('date range filter restricts sales within start and end timestamps', () async {
      final part = await insertPart(name: 'Fan Belt', qty: 10, purchasePrice: 80, sellingPrice: 120);

      await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 1)],
      );

      final todayRange = DateRange.forType(DateRangeType.today);
      final todaySales = await salesRepo
          .watchFilteredSales(
            ownerId: ownerId,
            startDate: todayRange.start,
            endDate: todayRange.end,
          )
          .first;

      expect(todaySales.length, 1);

      // Past date range (yesterday or last year) should return 0 sales
      final pastStart = DateTime(2020, 1, 1);
      final pastEnd = DateTime(2020, 1, 2);
      final pastSales = await salesRepo
          .watchFilteredSales(
            ownerId: ownerId,
            startDate: pastStart,
            endDate: pastEnd,
          )
          .first;

      expect(pastSales.isEmpty, true);
    });

    test('SalesDayGroup.groupSales groups sales by calendar day and computes daily totals', () async {
      final part = await insertPart(name: 'Bushing', qty: 50, purchasePrice: 10, sellingPrice: 20);

      final sale1 = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 5)], // 100
      )).valueOrNull!;

      final sale2 = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 10)], // 200
      )).valueOrNull!;

      final groups = SalesDayGroup.groupSales([sale1, sale2]);

      expect(groups.length, 1);
      expect(groups.first.sales.length, 2);
      expect(groups.first.totalAmount, 300.0);
    });

    test('deleteSale soft deletes the sale and removes it from active list', () async {
      final part = await insertPart(name: 'Bulb', qty: 20, purchasePrice: 5, sellingPrice: 15);
      final sale = (await salesRepo.createSale(
        ownerId: ownerId,
        items: [SaleLineItem.fromPart(part, quantity: 2)],
      )).valueOrNull!;

      final beforeDelete = await salesRepo.watchActiveSales(ownerId).first;
      expect(beforeDelete.length, 1);

      final deleteRes = await salesRepo.deleteSale(ownerId: ownerId, saleId: sale.id);
      expect(deleteRes.isSuccess, true);

      final afterDelete = await salesRepo.watchActiveSales(ownerId).first;
      expect(afterDelete.isEmpty, true);
    });
  });
}
