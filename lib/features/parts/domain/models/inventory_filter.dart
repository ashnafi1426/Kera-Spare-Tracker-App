/// Stock filter options for inventory list.
enum StockFilter {
  all,
  inStock,
  lowStock,
  outOfStock,
}

/// Sort criteria for inventory list.
enum PartsSortBy {
  name,
  newest,
  quantity,
  price,
}

/// Value object representing active inventory search, filter, and sorting criteria.
class InventoryFilter {
  final String? query;
  final String? brandId;
  final String? categoryId;
  final String? locationId;
  final StockFilter stockFilter;
  final PartsSortBy sortBy;
  final bool sortAscending;

  const InventoryFilter({
    this.query,
    this.brandId,
    this.categoryId,
    this.locationId,
    this.stockFilter = StockFilter.all,
    this.sortBy = PartsSortBy.newest,
    this.sortAscending = false,
  });

  /// Returns true if any non-default filter is currently active.
  bool get hasActiveFilters =>
      brandId != null ||
      categoryId != null ||
      locationId != null ||
      stockFilter != StockFilter.all ||
      sortBy != PartsSortBy.newest ||
      sortAscending != false;

  /// Returns the count of active attribute filters (excluding search query and sorting).
  int get filterCount {
    var count = 0;
    if (brandId != null) count++;
    if (categoryId != null) count++;
    if (locationId != null) count++;
    if (stockFilter != StockFilter.all) count++;
    return count;
  }

  InventoryFilter copyWith({
    String? query,
    bool clearQuery = false,
    String? brandId,
    bool clearBrand = false,
    String? categoryId,
    bool clearCategory = false,
    String? locationId,
    bool clearLocation = false,
    StockFilter? stockFilter,
    PartsSortBy? sortBy,
    bool? sortAscending,
  }) {
    return InventoryFilter(
      query: clearQuery ? null : (query ?? this.query),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      stockFilter: stockFilter ?? this.stockFilter,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
