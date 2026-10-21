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

/// Provider for ReportsRepository instance.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalReportsRepository(db: db);
});

/// Currently selected period on the reports screen (daily, weekly, monthly).
final selectedReportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.daily);

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
