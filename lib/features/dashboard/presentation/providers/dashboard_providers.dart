import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

// Re-export pendingSyncCountProvider from auth_controller
export '../../../auth/presentation/controllers/auth_controller.dart'
    show pendingSyncCountProvider;

/// Aggregate business metrics for the owner dashboard.
class BusinessDashboardMetrics {
  final int totalSkus;
  final double totalQuantity;
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

  final todayRevenue = salesSummary?.totalRevenue ?? 0.0;
  final todayProfit = salesSummary?.totalProfit ?? 0.0;
  final profitMargin =
      todayRevenue > 0 ? (todayProfit / todayRevenue) * 100 : 0.0;

  final metrics = BusinessDashboardMetrics(
    totalSkus: totalSkus,
    totalQuantity: totalQuantity,
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
