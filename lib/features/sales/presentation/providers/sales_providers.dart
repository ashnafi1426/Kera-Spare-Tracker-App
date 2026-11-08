import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database_provider.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../../../reports/domain/models/sales_summary.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../data/repositories/local_sales_repository.dart';
import '../../domain/models/sale_line_item.dart';
import '../../domain/models/sale_model.dart';
import '../../domain/models/sales_day_group.dart';
import '../../domain/repositories/sales_repository.dart';

/// Provider for SalesRepository instance.
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalSalesRepository(db: db);
});

/// Stream of active sales for the authenticated owner.
final activeSalesStreamProvider = StreamProvider<List<SaleModel>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(salesRepositoryProvider);
  return repo.watchActiveSales(ownerId);
});

/// Notifier for selected date filter for the sales history screen.
class SalesHistoryDateFilterNotifier extends Notifier<DateRangeType> {
  @override
  DateRangeType build() => DateRangeType.thisMonth;

  void setFilter(DateRangeType type) => state = type;
}

final salesHistoryDateFilterProvider =
    NotifierProvider<SalesHistoryDateFilterNotifier, DateRangeType>(
  SalesHistoryDateFilterNotifier.new,
);

/// Notifier for selected custom date range when date filter is custom.
class SalesHistoryCustomRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
}

final salesHistoryCustomRangeProvider =
    NotifierProvider<SalesHistoryCustomRangeNotifier, DateTimeRange?>(
  SalesHistoryCustomRangeNotifier.new,
);

/// Notifier for search query string on sales history screen.
class SalesHistorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final salesHistorySearchQueryProvider =
    NotifierProvider<SalesHistorySearchQueryNotifier, String>(
  SalesHistorySearchQueryNotifier.new,
);

/// Filtered sales stream respecting active search query and date range.
final filteredSalesStreamProvider = StreamProvider<List<SaleModel>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final dateType = ref.watch(salesHistoryDateFilterProvider);
  final customRange = ref.watch(salesHistoryCustomRangeProvider);
  final query = ref.watch(salesHistorySearchQueryProvider);

  final range = DateRange.forType(dateType, customRange: customRange);

  return repo.watchFilteredSales(
    ownerId: ownerId,
    query: query,
    startDate: range.start,
    endDate: range.end,
  );
});

/// Grouped sales by day with totals per day.
final salesDayGroupsProvider =
    Provider<AsyncValue<List<SalesDayGroup>>>((ref) {
  final salesAsync = ref.watch(filteredSalesStreamProvider);
  return salesAsync.whenData((sales) => SalesDayGroup.groupSales(sales));
});

/// Future provider for fetching a specific sale by ID.
final saleByIdProvider =
    FutureProvider.family<SaleModel?, String>((ref, saleId) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(salesRepositoryProvider);
  final result = await repo.getSaleById(ownerId: ownerId, saleId: saleId);
  return result.valueOrNull;
});

/// State notifier managing the active in-memory cart on the New Sale screen.
class NewSaleCartNotifier extends Notifier<List<SaleLineItem>> {
  @override
  List<SaleLineItem> build() => [];

  /// Adds a part to the sale cart, or increments quantity if already present.
  void addPart(PartItem part) {
    final existingIndex = state.indexWhere((item) => item.part.id == part.id);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      final updated = current.copyWith(quantity: current.quantity + 1.0);
      final list = [...state];
      list[existingIndex] = updated;
      state = list;
    } else {
      state = [...state, SaleLineItem.fromPart(part)];
    }
  }

  /// Updates quantity for a specific line item.
  void updateQuantity(String partId, double quantity) {
    if (quantity <= 0) {
      removeItem(partId);
      return;
    }
    state = state.map((item) {
      if (item.part.id == partId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  /// Overrides the selling unit price for a specific line item.
  void updateUnitPrice(String partId, double newPrice) {
    state = state.map((item) {
      if (item.part.id == partId) {
        return item.copyWith(unitPrice: newPrice);
      }
      return item;
    }).toList();
  }

  /// Removes an item from the sale cart.
  void removeItem(String partId) {
    state = state.where((item) => item.part.id != partId).toList();
  }

  /// Clears the active cart.
  void clear() {
    state = [];
  }
}

final newSaleCartProvider =
    NotifierProvider<NewSaleCartNotifier, List<SaleLineItem>>(
  NewSaleCartNotifier.new,
);

/// Model for the 3 performance summary cards on the Sales POS screen.
class SalesPosMetrics {
  final int salesCount;
  final double totalRevenue;
  final double totalProfit;
  final double salesCountTrendPct;
  final double revenueTrendPct;
  final double profitTrendPct;

  const SalesPosMetrics({
    required this.salesCount,
    required this.totalRevenue,
    required this.totalProfit,
    this.salesCountTrendPct = 0.0,
    this.revenueTrendPct = 0.0,
    this.profitTrendPct = 0.0,
  });

  static const zero = SalesPosMetrics(
    salesCount: 0,
    totalRevenue: 0.0,
    totalProfit: 0.0,
  );
}

/// Date filter notifier specifically for the Sales & POS screen.
class SalesPosDateFilterNotifier extends Notifier<DateRangeType> {
  @override
  DateRangeType build() => DateRangeType.today;

  void setFilter(DateRangeType type) => state = type;
}

final salesPosDateFilterProvider =
    NotifierProvider<SalesPosDateFilterNotifier, DateRangeType>(
  SalesPosDateFilterNotifier.new,
);

/// Custom date range notifier for the Sales & POS screen.
class SalesPosCustomRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
}

final salesPosCustomRangeProvider =
    NotifierProvider<SalesPosCustomRangeNotifier, DateTimeRange?>(
  SalesPosCustomRangeNotifier.new,
);

/// Computes live sales KPI metrics (count, revenue, profit, trends) from SQLite.
final salesPosMetricsProvider = FutureProvider<SalesPosMetrics>((ref) async {
  final ownerId = ref.watch(currentOwnerIdProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  final dateType = ref.watch(salesPosDateFilterProvider);
  final customRange = ref.watch(salesPosCustomRangeProvider);

  final currentRange = DateRange.forType(dateType, customRange: customRange);
  final currentSummaryRes = await repo.getSalesSummary(
    ownerId: ownerId,
    range: currentRange,
  );
  final currentSummary = currentSummaryRes.valueOrNull ?? SalesSummary.zero;

  // Compute previous range for trend comparison
  DateRange? previousRange;
  final now = DateTime.now();
  switch (dateType) {
    case DateRangeType.today:
      final yesterday = now.subtract(const Duration(days: 1));
      previousRange =
          DateRange.forType(DateRangeType.today, referenceTime: yesterday);
      break;
    case DateRangeType.thisWeek:
      final lastWeek = now.subtract(const Duration(days: 7));
      previousRange =
          DateRange.forType(DateRangeType.thisWeek, referenceTime: lastWeek);
      break;
    case DateRangeType.thisMonth:
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      previousRange =
          DateRange.forType(DateRangeType.thisMonth, referenceTime: lastMonth);
      break;
    case DateRangeType.custom:
      previousRange = null;
      break;
  }

  double countTrend = 0.0;
  double revenueTrend = 0.0;
  double profitTrend = 0.0;

  if (previousRange != null) {
    final prevRes =
        await repo.getSalesSummary(ownerId: ownerId, range: previousRange);
    final prevSummary = prevRes.valueOrNull ?? SalesSummary.zero;

    if (prevSummary.salesCount > 0) {
      countTrend =
          ((currentSummary.salesCount - prevSummary.salesCount) /
                  prevSummary.salesCount) *
              100;
    } else if (currentSummary.salesCount > 0) {
      countTrend = 100.0;
    }

    if (prevSummary.totalRevenue > 0) {
      revenueTrend =
          ((currentSummary.totalRevenue - prevSummary.totalRevenue) /
                  prevSummary.totalRevenue) *
              100;
    } else if (currentSummary.totalRevenue > 0) {
      revenueTrend = 100.0;
    }

    if (prevSummary.totalProfit > 0) {
      profitTrend =
          ((currentSummary.totalProfit - prevSummary.totalProfit) /
                  prevSummary.totalProfit) *
              100;
    } else if (currentSummary.totalProfit > 0) {
      profitTrend = 100.0;
    }
  }

  return SalesPosMetrics(
    salesCount: currentSummary.salesCount,
    totalRevenue: currentSummary.totalRevenue,
    totalProfit: currentSummary.totalProfit,
    salesCountTrendPct: countTrend,
    revenueTrendPct: revenueTrend,
    profitTrendPct: profitTrend,
  );
});
