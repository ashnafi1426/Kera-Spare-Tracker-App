import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/inventory_filter.dart';
import '../../domain/models/part_item.dart';
import 'metadata_providers.dart';
import 'parts_providers.dart';

/// State of the paginated inventory list.
class InventoryListState {
  final List<PartItem> items;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const InventoryListState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
  });

  InventoryListState copyWith({
    List<PartItem>? items,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventoryListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Filter state manager for the inventory screen.
class InventoryFilterNotifier extends Notifier<InventoryFilter> {
  @override
  InventoryFilter build() => const InventoryFilter();

  void setQuery(String? query) {
    state = state.copyWith(
      query: query,
      clearQuery: query == null || query.trim().isEmpty,
    );
  }

  void setBrand(String? brandId) {
    state = state.copyWith(brandId: brandId, clearBrand: brandId == null);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
  }

  void setLocation(String? locationId) {
    state = state.copyWith(locationId: locationId, clearLocation: locationId == null);
  }

  void setStockFilter(StockFilter filter) {
    state = state.copyWith(stockFilter: filter);
  }

  void setSort(PartsSortBy sortBy, {bool? ascending}) {
    state = state.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? (sortBy == PartsSortBy.name ? true : false),
    );
  }

  void resetFilters() {
    state = InventoryFilter(
      query: state.query,
      sortBy: PartsSortBy.newest,
      sortAscending: false,
    );
  }
}

/// Provider for active search, filter, and sort state.
final inventoryFilterProvider =
    NotifierProvider<InventoryFilterNotifier, InventoryFilter>(
  InventoryFilterNotifier.new,
);

/// Page size for database queries to ensure smooth scrolling with 5,000+ items.
const int kInventoryPageSize = 40;

/// Controller managing lazy paged loading, debounced search updates, and pull-to-refresh.
class InventoryListNotifier extends Notifier<InventoryListState> {
  @override
  InventoryListState build() {
    // Watch filter so whenever filter changes, list automatically re-fetches from page 0
    ref.watch(inventoryFilterProvider);

    // Trigger initial fetch asynchronously
    Future.microtask(() => refresh());

    return const InventoryListState(isLoading: true);
  }

  /// Refreshes the inventory list from page 0 using the current filter.
  Future<void> refresh() async {
    final ownerId = ref.read(currentOwnerIdProvider);
    final filter = ref.read(inventoryFilterProvider);
    final repo = ref.read(partsRepositoryProvider);

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await repo.getPagedParts(
      ownerId: ownerId,
      filter: filter,
      limit: kInventoryPageSize,
      offset: 0,
    );

    if (result.isSuccess) {
      final paged = result.valueOrNull!;
      state = state.copyWith(
        items: paged.items,
        totalCount: paged.totalCount,
        hasMore: paged.hasMore,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message ?? 'Failed to load inventory',
      );
    }
  }

  /// Loads the next page of parts when scrolling near the bottom.
  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final ownerId = ref.read(currentOwnerIdProvider);
    final filter = ref.read(inventoryFilterProvider);
    final repo = ref.read(partsRepositoryProvider);

    state = state.copyWith(isLoadingMore: true);

    final currentOffset = state.items.length;
    final result = await repo.getPagedParts(
      ownerId: ownerId,
      filter: filter,
      limit: kInventoryPageSize,
      offset: currentOffset,
    );

    if (result.isSuccess) {
      final paged = result.valueOrNull!;
      state = state.copyWith(
        items: [...state.items, ...paged.items],
        totalCount: paged.totalCount,
        hasMore: paged.hasMore,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: result.failureOrNull?.message,
      );
    }
  }

  /// Seeds 2,000 realistic test parts for performance benchmarking.
  Future<bool> seedTestParts({int count = 2000}) async {
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(partsRepositoryProvider);

    state = state.copyWith(isLoading: true);
    final result = await repo.seedTestParts(ownerId: ownerId, count: count);
    await refresh();
    return result.isSuccess;
  }

  /// Clears generated test parts.
  Future<bool> clearTestParts() async {
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(partsRepositoryProvider);

    state = state.copyWith(isLoading: true);
    final result = await repo.clearTestParts(ownerId);
    await refresh();
    return result.isSuccess;
  }
}

/// Provider for the lazy paged inventory list state.
final inventoryListProvider =
    NotifierProvider<InventoryListNotifier, InventoryListState>(
  InventoryListNotifier.new,
);
