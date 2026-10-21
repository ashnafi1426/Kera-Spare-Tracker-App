import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database_provider.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../reports/domain/models/date_range_filter.dart';
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
