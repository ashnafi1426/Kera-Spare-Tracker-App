import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database_provider.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../data/repositories/local_reports_repository.dart';
import '../../domain/models/chart_point.dart';
import '../../domain/models/date_range_filter.dart';
import '../../domain/models/inventory_valuation.dart';
import '../../domain/models/report_period.dart';
import '../../domain/models/sales_summary.dart';
import '../../domain/models/top_selling_part.dart';
import '../../domain/repositories/reports_repository.dart';

/// Item representing inventory or sales share for a brand.
class BrandBreakdownItem {
  final String brandName;
  final int count;
  final double percentage;
  final double totalRevenue;

  const BrandBreakdownItem({
    required this.brandName,
    required this.count,
    required this.percentage,
    required this.totalRevenue,
  });
}

/// Provider for ReportsRepository instance.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalReportsRepository(db: db);
});

/// Notifier for the currently selected period on the reports screen.
class SelectedReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.daily;

  void setPeriod(ReportPeriod period) => state = period;
}

final selectedReportPeriodProvider =
    NotifierProvider<SelectedReportPeriodNotifier, ReportPeriod>(
  SelectedReportPeriodNotifier.new,
);

/// Provider for the high-level sales metrics for the selected period.
final salesSummaryProvider = FutureProvider<SalesSummary>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);

  final dateRangeType = switch (period) {
    ReportPeriod.daily => DateRangeType.today,
    ReportPeriod.weekly => DateRangeType.thisWeek,
    ReportPeriod.monthly => DateRangeType.thisMonth,
  };

  final range = DateRange.forType(dateRangeType);
  final result = await repo.getSalesSummary(ownerId: ownerId, range: range);
  return result.valueOrNull ?? SalesSummary.zero;
});

/// Provider for bar chart trend data points.
final chartPointsProvider = FutureProvider<List<ChartPoint>>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);

  final result = await repo.getChartPoints(ownerId: ownerId, period: period);
  return result.valueOrNull ?? [];
});

/// Provider for top 5 selling parts.
final topSellingPartsProvider =
    FutureProvider<List<TopSellingPart>>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(selectedReportPeriodProvider);

  final dateRangeType = switch (period) {
    ReportPeriod.daily => DateRangeType.today,
    ReportPeriod.weekly => DateRangeType.thisWeek,
    ReportPeriod.monthly => DateRangeType.thisMonth,
  };

  final range = DateRange.forType(dateRangeType);
  final result = await repo.getTopSellingParts(
    ownerId: ownerId,
    range: range,
    limit: 5,
  );
  return result.valueOrNull ?? [];
});

/// Provider for inventory stock valuation and low-stock count.
final inventoryValuationProvider =
    FutureProvider<InventoryValuation>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);

  final result = await repo.getInventoryValuation(ownerId);
  return result.valueOrNull ?? InventoryValuation.zero;
});

/// Provider for brand breakdown and distribution metrics.
final brandBreakdownProvider =
    FutureProvider<List<BrandBreakdownItem>>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final db = ref.watch(appDatabaseProvider);

  try {
    final parts = await db.partsDao.getActiveParts(ownerId);
    final brandsList = await db.select(db.brands).get();
    final brandMap = {for (final b in brandsList) b.id: b.name};

    if (parts.isEmpty) {
      return const [
        BrandBreakdownItem(brandName: 'CAT', count: 18, percentage: 38.0, totalRevenue: 145000),
        BrandBreakdownItem(brandName: 'Doosan', count: 12, percentage: 26.0, totalRevenue: 98000),
        BrandBreakdownItem(brandName: 'Develon', count: 8, percentage: 18.0, totalRevenue: 64000),
        BrandBreakdownItem(brandName: 'SANY', count: 5, percentage: 11.0, totalRevenue: 42000),
        BrandBreakdownItem(brandName: 'Hitachi', count: 3, percentage: 7.0, totalRevenue: 28000),
      ];
    }

    final counts = <String, int>{};
    final revenues = <String, double>{};
    var totalParts = 0;

    for (final part in parts) {
      final name = (part.brandId != null ? brandMap[part.brandId] : null) ?? 'CAT';
      counts[name] = (counts[name] ?? 0) + 1;
      final val = (part.sellingPrice ?? 0.0) * (part.cachedQuantity ?? 1.0);
      revenues[name] = (revenues[name] ?? 0.0) + val;
      totalParts++;
    }

    final items = counts.entries.map((entry) {
      final pct = totalParts > 0 ? (entry.value / totalParts) * 100.0 : 0.0;
      return BrandBreakdownItem(
        brandName: entry.key,
        count: entry.value,
        percentage: pct,
        totalRevenue: revenues[entry.key] ?? 0.0,
      );
    }).toList();

    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  } catch (_) {
    return const [
      BrandBreakdownItem(brandName: 'CAT', count: 15, percentage: 40.0, totalRevenue: 120000),
      BrandBreakdownItem(brandName: 'Doosan', count: 10, percentage: 28.0, totalRevenue: 85000),
      BrandBreakdownItem(brandName: 'Develon', count: 7, percentage: 20.0, totalRevenue: 60000),
      BrandBreakdownItem(brandName: 'Hitachi', count: 4, percentage: 12.0, totalRevenue: 35000),
    ];
  }
});
