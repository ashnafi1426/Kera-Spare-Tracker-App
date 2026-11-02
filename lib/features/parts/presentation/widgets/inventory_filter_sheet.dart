import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/app_picker_bottom_sheet.dart';
import '../../domain/models/inventory_filter.dart';
import '../providers/inventory_providers.dart';
import '../providers/metadata_providers.dart';

/// Stitch Screen 17: Inventory Filter Bottom Sheet (የዕቃዎች ማጣሪያ).
///
/// Modal bottom sheet allowing users to filter inventory by stock status, brand,
/// category, storage shelf, and apply custom sorting orders.
class InventoryFilterSheet extends ConsumerStatefulWidget {
  const InventoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: KeraRadii.borderSheet,
          ),
          child: Column(
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: KeraColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: KeraColors.primaryNavy, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'የዕቃዎች ማጣሪያ (Filter)',
                      style: KeraTypography.titleMedium(color: KeraColors.primaryNavy).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: Text(
                        l10n.resetFilters,
                        style: const TextStyle(
                          color: KeraColors.actionBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: KeraColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: KeraColors.outlineBorder),

              // 3. Filter Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // A. Stock Status (Stitch Screen 17)
                    Text(
                      l10n.stockStatus,
                      style: KeraTypography.titleSmall().copyWith(
                        color: KeraColors.primaryNavy,
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

                    // B. Brand Filter
                    Text(
                      l10n.brand,
                      style: KeraTypography.titleSmall().copyWith(
                        color: KeraColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.directions_car_outlined,
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

                    // C. Category Filter
                    Text(
                      l10n.category,
                      style: KeraTypography.titleSmall().copyWith(
                        color: KeraColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.folder_open_outlined,
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

                    // D. Storage Location Filter
                    Text(
                      l10n.storageLocation,
                      style: KeraTypography.titleSmall().copyWith(
                        color: KeraColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.shelves,
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

                    // E. Sorting Criteria (Stitch Screen 17)
                    Text(
                      l10n.sortBy,
                      style: KeraTypography.titleSmall().copyWith(
                        color: KeraColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceMuted,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.outlineBorder),
                      ),
                      child: Column(
                        children: [
                          _buildSortTile(
                            sortBy: PartsSortBy.newest,
                            ascending: false,
                            label: l10n.sortNewest,
                          ),
                          const Divider(height: 1, color: KeraColors.outlineBorder),
                          _buildSortTile(
                            sortBy: PartsSortBy.name,
                            ascending: true,
                            label: l10n.sortName,
                          ),
                          const Divider(height: 1, color: KeraColors.outlineBorder),
                          _buildSortTile(
                            sortBy: PartsSortBy.quantity,
                            ascending: false,
                            label: l10n.sortQuantityHigh,
                          ),
                          const Divider(height: 1, color: KeraColors.outlineBorder),
                          _buildSortTile(
                            sortBy: PartsSortBy.quantity,
                            ascending: true,
                            label: l10n.sortQuantityLow,
                          ),
                          const Divider(height: 1, color: KeraColors.outlineBorder),
                          _buildSortTile(
                            sortBy: PartsSortBy.price,
                            ascending: false,
                            label: l10n.sortPriceHigh,
                          ),
                          const Divider(height: 1, color: KeraColors.outlineBorder),
                          _buildSortTile(
                            sortBy: PartsSortBy.price,
                            ascending: true,
                            label: l10n.sortPriceLow,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Sticky Apply Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: KeraColors.outlineBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: AppConstants.standardButtonHeight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KeraColors.actionBlue,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: KeraRadii.borderButton,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      l10n.applyFilters,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    onPressed: _apply,
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

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _stockFilter = filter),
      backgroundColor: KeraColors.surfaceMuted,
      selectedColor: KeraColors.primaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: KeraRadii.borderMicro,
        side: BorderSide(color: KeraColors.outlineBorder),
      ),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : KeraColors.textPrimary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: KeraRadii.borderInput,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: KeraRadii.borderInput,
          border: Border.all(
            color: hasValue ? KeraColors.actionBlue : KeraColors.outlineBorder,
            width: hasValue ? 1.5 : 1.0,
          ),
          color: hasValue
              ? KeraColors.actionBlue.withValues(alpha: 0.08)
              : KeraColors.surfaceMuted,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue ? KeraColors.actionBlue : KeraColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: KeraTypography.bodyMedium().copyWith(
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? KeraColors.textPrimary : KeraColors.textSecondary,
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
              const Icon(Icons.arrow_drop_down_rounded, color: KeraColors.textSecondary),
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

    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = sortBy;
          _sortAscending = ascending;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? KeraColors.actionBlue : KeraColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: KeraTypography.bodyMedium().copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? KeraColors.actionBlue : KeraColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
