import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/domain/models/chart_point.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../../../reports/domain/models/report_period.dart';
import '../../../reports/domain/models/sales_summary.dart';
import '../../../reports/domain/models/top_selling_part.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

// Re-export pendingSyncCountProvider from auth_controller
export '../../../auth/presentation/controllers/auth_controller.dart'
    show pendingSyncCountProvider;

/// State notifier for the dashboard date filter.
class DashboardDateRangeNotifier extends Notifier<DateRange> {
  @override
  DateRange build() => DateRange.forType(DateRangeType.today);

  void setType(DateRangeType type, {DateTimeRange? customRange}) {
    state = DateRange.forType(type, customRange: customRange);
  }
}

final dashboardDateRangeProvider =
    NotifierProvider<DashboardDateRangeNotifier, DateRange>(
  DashboardDateRangeNotifier.new,
);

/// Sales summary for the currently selected dashboard date range.
final dashboardSalesSummaryProvider = FutureProvider<SalesSummary>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final range = ref.watch(dashboardDateRangeProvider);
  final res = await repo.getSalesSummary(ownerId: ownerId, range: range);
  return res.valueOrNull ?? SalesSummary.zero;
});

/// Chart period notifier for the dashboard sales performance chart.
class DashboardChartPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.daily;

  void setPeriod(ReportPeriod period) => state = period;
}

final dashboardChartPeriodProvider =
    NotifierProvider<DashboardChartPeriodNotifier, ReportPeriod>(
  DashboardChartPeriodNotifier.new,
);

/// Chart points for the dashboard sales performance chart.
final dashboardChartPointsProvider =
    FutureProvider<List<ChartPoint>>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final period = ref.watch(dashboardChartPeriodProvider);
  final res = await repo.getChartPoints(ownerId: ownerId, period: period);
  return res.valueOrNull ?? [];
});

/// Top selling parts for the dashboard insights.
final dashboardTopSellingPartsProvider =
    FutureProvider<List<TopSellingPart>>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final range = ref.watch(dashboardDateRangeProvider);
  final res = await repo.getTopSellingParts(
    ownerId: ownerId,
    range: range,
    limit: 5,
  );
  return res.valueOrNull ?? [];
});

/// Aggregate business metrics for the owner dashboard computed strictly from local SQLite.
class BusinessDashboardMetrics {
  final int totalSkus;
  final double totalQuantity;
  final double inventoryValue;
  final double inventorySellingValue;
  final double todayRevenue;
  final double todayProfit;
  final double profitMargin;
  final int lowStockCount;
  final int outOfStockCount;
  final int pendingSyncCount;
  final bool hasItems;

  const BusinessDashboardMetrics({
    this.totalSkus = 0,
    this.totalQuantity = 0.0,
    this.inventoryValue = 0.0,
    this.inventorySellingValue = 0.0,
    this.todayRevenue = 0.0,
    this.todayProfit = 0.0,
    this.profitMargin = 0.0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.pendingSyncCount = 0,
    this.hasItems = false,
  });
}

/// Provider computing real-time business statistics from Drift SQLite and active streams.
final businessDashboardMetricsProvider =
    Provider<AsyncValue<BusinessDashboardMetrics>>((ref) {
  final partsAsync = ref.watch(partsStreamProvider);
  final salesSummaryAsync = ref.watch(salesSummaryProvider);
  final pendingCountAsync = ref.watch(pendingSyncCountProvider);

  if (partsAsync.isLoading && !partsAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final parts = partsAsync.value ?? [];
  final salesSummary = salesSummaryAsync.value;
  final pendingCount = pendingCountAsync.value ?? 0;

  final totalSkus = parts.length;
  final totalQuantity =
      parts.fold<double>(0.0, (acc, item) => acc + item.cachedQuantity);
  final lowStockCount = parts.where((p) => p.isLowStock).length;
  final outOfStockCount = parts.where((p) => p.isOutOfStock).length;

  final inventoryValue = parts.fold<double>(
    0.0,
    (acc, item) =>
        acc + ((item.purchasePrice ?? 0.0) * (item.cachedQuantity > 0 ? item.cachedQuantity : 0.0)),
  );
  final inventorySellingValue = parts.fold<double>(
    0.0,
    (acc, item) =>
        acc +
        (((item.sellingPrice ?? item.purchasePrice) ?? 0.0) *
            (item.cachedQuantity > 0 ? item.cachedQuantity : 0.0)),
  );

  final todayRevenue = salesSummary?.totalRevenue ?? 0.0;
  final todayProfit = salesSummary?.totalProfit ?? 0.0;
  final profitMargin =
      todayRevenue > 0 ? (todayProfit / todayRevenue) * 100 : 0.0;

  final metrics = BusinessDashboardMetrics(
    totalSkus: totalSkus,
    totalQuantity: totalQuantity,
    inventoryValue: inventoryValue,
    inventorySellingValue: inventorySellingValue,
    todayRevenue: todayRevenue,
    todayProfit: todayProfit,
    profitMargin: profitMargin,
    lowStockCount: lowStockCount,
    outOfStockCount: outOfStockCount,
    pendingSyncCount: pendingCount,
    hasItems: parts.isNotEmpty,
  );

  return AsyncValue.data(metrics);
});
