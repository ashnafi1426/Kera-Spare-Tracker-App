import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/app_picker_bottom_sheet.dart';
import '../../domain/models/inventory_filter.dart';
import '../providers/inventory_providers.dart';
import '../providers/metadata_providers.dart';

/// Modal bottom sheet allowing users to filter inventory by stock status, brand,
/// category, location, and apply custom sorting orders.
class InventoryFilterSheet extends ConsumerStatefulWidget {
  const InventoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const InventoryFilterSheet(),
    );
  }

  @override
  ConsumerState<InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends ConsumerState<InventoryFilterSheet> {
  late StockFilter _stockFilter;
  late PartsSortBy _sortBy;
  late bool _sortAscending;
  String? _brandId;
  String? _brandName;
  String? _categoryId;
  String? _categoryName;
  String? _locationId;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    final current = ref.read(inventoryFilterProvider);
    _stockFilter = current.stockFilter;
    _sortBy = current.sortBy;
    _sortAscending = current.sortAscending;
    _brandId = current.brandId;
    _categoryId = current.categoryId;
    _locationId = current.locationId;
  }

  void _reset() {
    setState(() {
      _stockFilter = StockFilter.all;
      _sortBy = PartsSortBy.newest;
      _sortAscending = false;
      _brandId = null;
      _brandName = null;
      _categoryId = null;
      _categoryName = null;
      _locationId = null;
      _locationName = null;
    });
  }

  void _apply() {
    final notifier = ref.read(inventoryFilterProvider.notifier);
    notifier.setStockFilter(_stockFilter);
    notifier.setSort(_sortBy, ascending: _sortAscending);
    notifier.setBrand(_brandId);
    notifier.setCategory(_categoryId);
    notifier.setLocation(_locationId);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final brandsAsync = ref.watch(brandsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final locationsAsync = ref.watch(locationsStreamProvider);

    // Resolve names if IDs are set
    if (_brandId != null && _brandName == null) {
      final b = brandsAsync.value?.where((x) => x.id == _brandId).firstOrNull;
      if (b != null) _brandName = b.name;
    }
    if (_categoryId != null && _categoryName == null) {
      final c = categoriesAsync.value?.where((x) => x.id == _categoryId).firstOrNull;
      if (c != null) _categoryName = c.name;
    }
    if (_locationId != null && _locationName == null) {
      final l = locationsAsync.value?.where((x) => x.id == _locationId).firstOrNull;
      if (l != null) _locationName = l.name;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.filters,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: Text(l10n.resetFilters),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Stock Status
                    Text(
                      l10n.stockStatus,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStockChip(StockFilter.all, l10n.filterAll),
                        _buildStockChip(StockFilter.inStock, l10n.filterInStock),
                        _buildStockChip(StockFilter.lowStock, l10n.filterLowStock),
                        _buildStockChip(StockFilter.outOfStock, l10n.filterOutOfStock),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Brand Filter
                    Text(
                      l10n.brand,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.label_outline_rounded,
                      title: _brandName ?? l10n.brand,
                      hasValue: _brandId != null,
                      onTap: () async {
                        final brands = brandsAsync.value ?? [];
                        final items = brands.map((b) => b.toPickerItem()).toList();

                        final selected = await AppPickerBottomSheet.show(
                          context: context,
                          title: l10n.brand,
                          items: items,
                          selectedId: _brandId,
                        );

                        if (selected != null) {
                          setState(() {
                            _brandId = selected.id;
                            _brandName = selected.name;
                          });
                        }
                      },
                      onClear: () => setState(() {
                        _brandId = null;
                        _brandName = null;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // 3. Category Filter
                    Text(
                      l10n.category,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.category_outlined,
                      title: _categoryName ?? l10n.category,
                      hasValue: _categoryId != null,
                      onTap: () async {
                        final categories = categoriesAsync.value ?? [];
                        final items =
                            categories.map((c) => c.toPickerItem()).toList();

                        final selected = await AppPickerBottomSheet.show(
                          context: context,
                          title: l10n.category,
                          items: items,
                          selectedId: _categoryId,
                        );

                        if (selected != null) {
                          setState(() {
                            _categoryId = selected.id;
                            _categoryName = selected.name;
                          });
                        }
                      },
                      onClear: () => setState(() {
                        _categoryId = null;
                        _categoryName = null;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // 4. Storage Location Filter
                    Text(
                      l10n.storageLocation,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.place_outlined,
                      title: _locationName ?? l10n.storageLocation,
                      hasValue: _locationId != null,
                      onTap: () async {
                        final locations = locationsAsync.value ?? [];
                        final items =
                            locations.map((l) => l.toPickerItem()).toList();

                        final selected = await AppPickerBottomSheet.show(
                          context: context,
                          title: l10n.storageLocation,
                          items: items,
                          selectedId: _locationId,
                        );

                        if (selected != null) {
                          setState(() {
                            _locationId = selected.id;
                            _locationName = selected.name;
                          });
                        }
                      },
                      onClear: () => setState(() {
                        _locationId = null;
                        _locationName = null;
                      }),
                    ),
                    const SizedBox(height: 24),

                    // 5. Sorting Criteria
                    Text(
                      l10n.sortBy,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSortTile(
                      sortBy: PartsSortBy.newest,
                      ascending: false,
                      label: l10n.sortNewest,
                    ),
                    _buildSortTile(
                      sortBy: PartsSortBy.name,
                      ascending: true,
                      label: l10n.sortName,
                    ),
                    _buildSortTile(
                      sortBy: PartsSortBy.quantity,
                      ascending: false,
                      label: l10n.sortQuantityHigh,
                    ),
                    _buildSortTile(
                      sortBy: PartsSortBy.quantity,
                      ascending: true,
                      label: l10n.sortQuantityLow,
                    ),
                    _buildSortTile(
                      sortBy: PartsSortBy.price,
                      ascending: false,
                      label: l10n.sortPriceHigh,
                    ),
                    _buildSortTile(
                      sortBy: PartsSortBy.price,
                      ascending: true,
                      label: l10n.sortPriceLow,
                    ),
                  ],
                ),
              ),

              // Bottom Apply Action
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: AppConstants.minTouchTargetSize,
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: Text(
                      l10n.applyFilters,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockChip(StockFilter filter, String label) {
    final isSelected = _stockFilter == filter;
    final colorScheme = context.colorScheme;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _stockFilter = filter),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? colorScheme.onPrimaryContainer : null,
      ),
    );
  }

  Widget _buildSelectorCard({
    required IconData icon,
    required String title,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final colorScheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: hasValue ? 1.5 : 1.0,
          ),
          color: hasValue
              ? colorScheme.primaryContainer.withValues(alpha: 0.2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (hasValue)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile({
    required PartsSortBy sortBy,
    required bool ascending,
    required String label,
  }) {
    final isSelected = _sortBy == sortBy && _sortAscending == ascending;
    final colorScheme = context.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = sortBy;
          _sortAscending = ascending;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color:
                  isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
