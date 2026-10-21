import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/reports/data/repositories/local_reports_repository.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/date_range_filter.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/report_period.dart';
import 'package:kera_spare_tracker/features/sales/data/repositories/local_sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';

void main() {
  late AppDatabase db;
  late LocalReportsRepository reportsRepo;
  late LocalSalesRepository salesRepo;
  late LocalPartsRepository partsRepo;

  const ownerA = 'owner_kera_1';
  const ownerB = 'owner_kera_2';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reportsRepo = LocalReportsRepository(db: db);
    salesRepo = LocalSalesRepository(db: db);
    partsRepo = LocalPartsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<PartItem> insertPart({
    required String ownerId,
    required String name,
    required double qty,
    required double purchasePrice,
    required double sellingPrice,
    double threshold = 2.0,
  }) async {
    final res = await partsRepo.createPart(
      ownerId: ownerId,
      name: name,
      partNumber: 'PN-$name',
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      initialQuantity: qty,
      lowStockLevel: threshold,
    );
    return res.valueOrNull!;
  }

  group('ReportsRepository - SQL Aggregations & Calculations', () {
    test('sales summary accurately aggregates count, revenue, and profit across date range', () async {
      final part1 = await insertPart(
        ownerId: ownerA,
        name: 'Oil Filter',
        qty: 50,
        purchasePrice: 200,
        sellingPrice: 350,
      );
      final part2 = await insertPart(
        ownerId: ownerA,
        name: 'Brake Pad',
        qty: 30,
        purchasePrice: 800,
        sellingPrice: 1200,
      );

      // Sale 1: 2 x Oil Filter = 700 rev, 300 profit
      await salesRepo.createSale(
        ownerId: ownerA,
        items: [SaleLineItem.fromPart(part1, quantity: 2)],
      );

      // Sale 2: 1 x Brake Pad = 1200 rev, 400 profit
      await salesRepo.createSale(
        ownerId: ownerA,
        items: [SaleLineItem.fromPart(part2, quantity: 1)],
      );

      // Sale 3 for Owner B (should NOT leak into Owner A)
      final partB = await insertPart(
        ownerId: ownerB,
        name: 'Gasket',
        qty: 10,
        purchasePrice: 100,
        sellingPrice: 500,
      );
      await salesRepo.createSale(
        ownerId: ownerB,
        items: [SaleLineItem.fromPart(partB, quantity: 1)],
      );

      final todayRange = DateRange.forType(DateRangeType.today);
      final summaryRes = await reportsRepo.getSalesSummary(
        ownerId: ownerA,
        range: todayRange,
      );

      expect(summaryRes.isSuccess, true);
      final summary = summaryRes.valueOrNull!;

      // Owner A: 2 sales, 700 + 1200 = 1900 revenue, 300 + 400 = 700 profit
      expect(summary.salesCount, 2);
      expect(summary.totalRevenue, 1900.0);
      expect(summary.totalProfit, 700.0);
    });

    test('top 5 selling parts orders by quantity sold and aggregates line totals in SQL', () async {
      final p1 = await insertPart(ownerId: ownerA, name: 'Filter A', qty: 100, purchasePrice: 50, sellingPrice: 100);
      final p2 = await insertPart(ownerId: ownerA, name: 'Filter B', qty: 100, purchasePrice: 60, sellingPrice: 120);
      final p3 = await insertPart(ownerId: ownerA, name: 'Filter C', qty: 100, purchasePrice: 70, sellingPrice: 140);

      // Sell 10 of p2, 5 of p1, 25 of p3
      await salesRepo.createSale(
        ownerId: ownerA,
        items: [
          SaleLineItem.fromPart(p1, quantity: 5), // 5 * 100 = 500
          SaleLineItem.fromPart(p2, quantity: 10), // 10 * 120 = 1200
          SaleLineItem.fromPart(p3, quantity: 25), // 25 * 140 = 3500
        ],
      );

      final topPartsRes = await reportsRepo.getTopSellingParts(ownerId: ownerA);
      expect(topPartsRes.isSuccess, true);
      final topParts = topPartsRes.valueOrNull!;

      expect(topParts.length, 3);
      // Rank 1: Filter C (25 qty, 3500 rev)
      expect(topParts[0].partName, 'Filter C');
      expect(topParts[0].quantitySold, 25.0);
      expect(topParts[0].totalRevenue, 3500.0);

      // Rank 2: Filter B (10 qty, 1200 rev)
      expect(topParts[1].partName, 'Filter B');
      expect(topParts[1].quantitySold, 10.0);
      expect(topParts[1].totalRevenue, 1200.0);

      // Rank 3: Filter A (5 qty, 500 rev)
      expect(topParts[2].partName, 'Filter A');
      expect(topParts[2].quantitySold, 5.0);
      expect(topParts[2].totalRevenue, 500.0);
    });

    test('inventory valuation aggregates total stock value and low stock count', () async {
      // Part 1: 10 qty @ 200 purchase price = 2000 value (threshold 5 -> not low stock)
      await insertPart(
        ownerId: ownerA,
        name: 'Turbocharger',
        qty: 10,
        purchasePrice: 200,
        sellingPrice: 300,
        threshold: 5,
      );

      // Part 2: 2 qty @ 500 purchase price = 1000 value (threshold 5 -> LOW STOCK)
      await insertPart(
        ownerId: ownerA,
        name: 'Injector',
        qty: 2,
        purchasePrice: 500,
        sellingPrice: 750,
        threshold: 5,
      );

      // Part 3: 0 qty @ 1000 purchase price = 0 value (threshold 1 -> LOW STOCK)
      await insertPart(
        ownerId: ownerA,
        name: 'Piston',
        qty: 0,
        purchasePrice: 1000,
        sellingPrice: 1500,
        threshold: 1,
      );

      final valuationRes = await reportsRepo.getInventoryValuation(ownerA);
      expect(valuationRes.isSuccess, true);
      final valuation = valuationRes.valueOrNull!;

      // Total value: (10 * 200) + (2 * 500) + (0 * 1000) = 2000 + 1000 = 3000
      expect(valuation.totalStockValue, 3000.0);
      // Low stock count: Injector (2 <= 5) and Piston (0 <= 1) = 2 items
      expect(valuation.lowStockCount, 2);
      expect(valuation.totalActiveParts, 3);
    });

    test('getChartPoints computes interval points for daily, weekly, and monthly', () async {
      final part = await insertPart(
        ownerId: ownerA,
        name: 'Seal Ring',
        qty: 50,
        purchasePrice: 50,
        sellingPrice: 100,
      );

      await salesRepo.createSale(
        ownerId: ownerA,
        items: [SaleLineItem.fromPart(part, quantity: 4)],
      );

      final dailyPointsRes = await reportsRepo.getChartPoints(
        ownerId: ownerA,
        period: ReportPeriod.daily,
      );
      expect(dailyPointsRes.isSuccess, true);
      expect(dailyPointsRes.valueOrNull!.length, 7);

      final weeklyPointsRes = await reportsRepo.getChartPoints(
        ownerId: ownerA,
        period: ReportPeriod.weekly,
      );
      expect(weeklyPointsRes.isSuccess, true);
      expect(weeklyPointsRes.valueOrNull!.length, 4);

      final monthlyPointsRes = await reportsRepo.getChartPoints(
        ownerId: ownerA,
        period: ReportPeriod.monthly,
      );
      expect(monthlyPointsRes.isSuccess, true);
      expect(monthlyPointsRes.valueOrNull!.length, 6);
    });
  });
}
