import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_product_card.dart';
import '../../../../core/design/widgets/kera_status_badge.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/announcement_banner_widget.dart';
import '../../../../core/widgets/maintenance_banner_widget.dart';
import '../../../../core/widgets/suspended_account_banner_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/part_item.dart';
import '../providers/inventory_providers.dart';
import '../providers/parts_providers.dart';
import '../widgets/inventory_filter_sheet.dart';

/// Stitch Screen 12: Inventory Overview (የዕቃዎች ዝርዝር).
///
/// Features deep Navy industrial header, live sync indicator, Bento summary
/// metrics strip (valuation, in-stock, low-stock, out-of-stock), debounced search,
/// multi-criteria filter chips, list/grid view toggle, performant lazy pagination,
/// and complete empty states (Screen 18 & 19).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final initialQuery = ref.read(inventoryFilterProvider).query;
    if (initialQuery != null && initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Load next page when user scrolls within 400px of bottom
    if (currentScroll >= maxScroll - 400) {
      ref.read(inventoryListProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(inventoryFilterProvider.notifier).setQuery(text);
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    ref.read(inventoryFilterProvider.notifier).setQuery(null);
  }

  Future<void> _handleSeedParts() async {
    final l10n = context.l10n;
    context.showSnackBar(l10n.seedingInProgress);

    final success =
        await ref.read(inventoryListProvider.notifier).seedTestParts(count: 2000);

    if (!mounted) return;
    if (success) {
      context.showSnackBar(l10n.seedSuccess);
    } else {
      context.showSnackBar('Failed to seed parts', isError: true);
    }
  }

  Future<void> _handleClearTestParts() async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearTestParts),
        content: Text(l10n.clearTestPartsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(inventoryListProvider.notifier).clearTestParts();
      if (!mounted) return;
      if (success) {
        context.showSnackBar(l10n.clearTestPartsSuccess);
      } else {
        context.showSnackBar('Failed to clear test parts', isError: true);
      }
    }
  }

  void _showBarcodeScannerModal() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: KeraColors.actionBlue),
            const SizedBox(width: 8),
            Text(
              context.tr('የባርኮድ / OEM ፍለጋ', 'Barcode & OEM Search'),
              style: KeraTypography.titleSmall(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'የመለዋወጫ ባርኮድ ወይም የኦሪጅናል ቁጥር (OEM Part #) ያስገቡ ወይም በካሜራ ይቃኙ:',
                'Enter part barcode or OEM part number, or scan with camera:',
              ),
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 1R-0716, 202-0120...',
                prefixIcon: Icon(Icons.numbers_rounded),
                border: OutlineInputBorder(borderRadius: KeraRadii.borderInput),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ሰርዝ', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final query = textController.text.trim();
              Navigator.pop(ctx);
              if (query.isNotEmpty) {
                _searchController.text = query;
                ref.read(inventoryFilterProvider.notifier).setQuery(query);
              }
            },
            child: Text(context.tr('ፈልግ', 'Search')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    final filter = ref.watch(inventoryFilterProvider);
    final state = ref.watch(inventoryListProvider);
    final authUser = ref.watch(authControllerProvider).value;
    final partsStream = ref.watch(partsStreamProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;

    // Calculate inventory metrics from live stream or paged state
    final allParts = partsStream.value ?? state.items;
    double totalValuation = 0.0;
    int inStockCount = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (final p in allParts) {
      final price = p.sellingPrice ?? p.purchasePrice ?? 0.0;
      totalValuation += price * p.cachedQuantity;
      if (p.isOutOfStock || p.cachedQuantity <= 0) {
        outOfStockCount++;
      } else if (p.isLowStock) {
        lowStockCount++;
      } else {
        inStockCount++;
      }
    }

    final totalPartsCount = partsStream.value?.length ?? state.totalCount;

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_screen_fab',
        onPressed: () => context.push('/parts/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
        backgroundColor: KeraColors.actionBlue,
        foregroundColor: KeraColors.textWhite,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Navy Industrial App Header (Stitch Screen 12)
            _buildNavyHeader(
              context: context,
              authUser: authUser,
              pendingSync: pendingSync,
              l10n: l10n,
              filter: filter,
            ),

            // System Alert Banners
            const MaintenanceBannerWidget(),
            const SuspendedAccountBannerWidget(),
            const AnnouncementBannerWidget(),

            // 2. Bento Valuation & Quick Filter Metrics Strip
            _buildBentoMetricsStrip(
              totalValuation: totalValuation,
              totalCount: totalPartsCount,
              inStockCount: inStockCount,
              lowStockCount: lowStockCount,
              outOfStockCount: outOfStockCount,
              activeStockFilter: filter.stockFilter,
              l10n: l10n,
            ),

            // 3. Search and Barcode Scan Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _buildSearchBar(l10n),
            ),

            // 4. Quick Stock Chips & Controls (List/Grid & Filter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: _buildFilterChipsRow(filter, state, l10n, colorScheme),
            ),
            const Divider(height: 8, color: KeraColors.outlineBorder),

            // 5. Main Paginated Inventory List or Grid View
            Expanded(
              child: RefreshIndicator(
                color: KeraColors.actionBlue,
                onRefresh: () =>
                    ref.read(inventoryListProvider.notifier).refresh(),
                child: _buildInventoryBody(context, state, filter, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader({
    required BuildContext context,
    required dynamic authUser,
    required int pendingSync,
    required dynamic l10n,
    required InventoryFilter filter,
  }) {
    return Container(
      color: KeraColors.primaryNavy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 12,
      ),
      child: Row(
        children: [
          // Store Logo / Industrial Icon
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: KeraColors.primaryNavyDark,
              borderRadius: KeraRadii.borderMicro,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.precision_manufacturing_rounded,
                color: KeraColors.tealAccent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Store Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('ኬራ ስፔር', 'Kera Spare'),
                      style: KeraTypography.titleMedium(color: KeraColors.textWhite).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sync Pill Status
                    if (pendingSync > 0)
                      KeraStatusBadge.syncPending(count: pendingSync)
                    else
                      KeraStatusBadge.synced(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  authUser?.businessName ?? l10n.inventoryTab,
                  style: KeraTypography.bodySmall(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Language toggle pill
          Consumer(
            builder: (context, ref, _) {
              final isAmharic = context.isAmharic;
              return InkWell(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(
                        Locale(isAmharic ? 'en' : 'am'),
                      );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'English' : 'አማርኛ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),

          // Barcode Scan Action Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            tooltip: l10n.scannerAction,
            onPressed: _showBarcodeScannerModal,
          ),

          // Filter Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                tooltip: l10n.filter,
                onPressed: () => InventoryFilterSheet.show(context),
              ),
              if (filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: KeraColors.actionBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Seeder / Debug Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (val) {
              if (val == 'seed') {
                _handleSeedParts();
              } else if (val == 'clear_seed') {
                _handleClearTestParts();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: KeraColors.actionBlue, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.seedParts),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_seed',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, color: KeraColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.clearTestParts),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetricsStrip({
    required double totalValuation,
    required int totalCount,
    required int inStockCount,
    required int lowStockCount,
    required int outOfStockCount,
    required StockFilter activeStockFilter,
    required dynamic l10n,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // Top Row: Total Valuation & Parts Count Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: KeraColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('ጠቅላላ ዋጋ:', 'Total Value:'),
                    style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${totalValuation.toStringAsFixed(0)} ${context.tr("ብር", "ETB")}',
                    style: KeraTypography.numericCompact(color: KeraColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: KeraColors.surfaceMuted,
                  borderRadius: KeraRadii.borderMicro,
                ),
                child: Text(
                  '$totalCount ${context.tr("ዕቃዎች", "Items")}',
                  style: KeraTypography.labelSmall(color: KeraColors.primaryNavy).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4-Column Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: context.tr('ጠቅላላ', 'All'),
                  count: totalCount,
                  isSelected: activeStockFilter == StockFilter.all,
                  accentColor: KeraColors.actionBlue,
                  onTap: () => ref
                      .read(inventoryFilterProvider.notifier)
                      .setStockFilter(StockFilter.all),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: context.tr('በክምችት', 'In Stock'),
                  count: inStockCount,
                  isSelected: activeStockFilter == StockFilter.inStock,
                  accentColor: KeraColors.stockInText,
                  onTap: () => ref
                      .read(inventoryFilterProvider.notifier)
                      .setStockFilter(StockFilter.inStock),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: context.tr('አነስተኛ', 'Low Stock'),
                  count: lowStockCount,
                  isSelected: activeStockFilter == StockFilter.lowStock,
                  accentColor: KeraColors.stockLowText,
                  onTap: () => ref
                      .read(inventoryFilterProvider.notifier)
                      .setStockFilter(StockFilter.lowStock),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  label: context.tr('ያለቀባቸው', 'Out of Stock'),
                  count: outOfStockCount,
                  isSelected: activeStockFilter == StockFilter.outOfStock,
                  accentColor: KeraColors.stockOutText,
                  onTap: () => ref
                      .read(inventoryFilterProvider.notifier)
                      .setStockFilter(StockFilter.outOfStock),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KeraRadii.borderMicro,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : KeraColors.surfaceMuted,
          borderRadius: KeraRadii.borderMicro,
          border: Border.all(
            color: isSelected ? accentColor : KeraColors.outlineBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: KeraTypography.numericCompact(
                color: isSelected ? accentColor : KeraColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: KeraTypography.labelSmall(
                color: isSelected ? accentColor : KeraColors.textSecondary,
              ).copyWith(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(dynamic l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderInput,
        border: Border.all(color: KeraColors.outlineBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: KeraTypography.bodyMedium(),
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: KeraTypography.bodyMedium(color: KeraColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: KeraColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: KeraColors.textSecondary),
                  onPressed: _onClearSearch,
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    size: 20, color: KeraColors.actionBlue),
                tooltip: 'Scan barcode',
                onPressed: _showBarcodeScannerModal,
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: const OutlineInputBorder(
            borderRadius: KeraRadii.borderInput,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(
    InventoryFilter filter,
    InventoryListState state,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Horizontal scrollable quick chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStockFilterChip(StockFilter.all, l10n.filterAll, filter.stockFilter),
                const SizedBox(width: 6),
                _buildStockFilterChip(StockFilter.inStock, l10n.filterInStock, filter.stockFilter),
                const SizedBox(width: 6),
                _buildStockFilterChip(StockFilter.lowStock, l10n.filterLowStock, filter.stockFilter),
                const SizedBox(width: 6),
                _buildStockFilterChip(StockFilter.outOfStock, l10n.filterOutOfStock, filter.stockFilter),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Grid / List View Toggle Button
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: KeraColors.textSecondary,
            size: 20,
          ),
          tooltip: _isGridView ? 'List view' : 'Grid view',
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
    );
  }

  Widget _buildStockFilterChip(
    StockFilter filterValue,
    String label,
    StockFilter activeFilter,
  ) {
    final isSelected = filterValue == activeFilter;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        ref.read(inventoryFilterProvider.notifier).setStockFilter(filterValue);
      },
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white,
      selectedColor: KeraColors.primaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: KeraRadii.borderMicro,
        side: BorderSide(color: KeraColors.outlineBorder),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildInventoryBody(
    BuildContext context,
    InventoryListState state,
    InventoryFilter filter,
    dynamic l10n,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: KeraColors.actionBlue),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: KeraColors.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: KeraTypography.bodyMedium(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(inventoryListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KeraColors.actionBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      final isFiltered = filter.hasActiveFilters ||
          (_searchController.text.trim().isNotEmpty);

      if (isFiltered) {
        // Stitch Screen 19: Search Results Empty State
        return _buildSearchEmptyState(l10n);
      } else {
        // Stitch Screen 18: Fresh Store Empty Inventory State
        return _buildStoreEmptyState(l10n);
      }
    }

    // High performance list or grid with pagination indicator
    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

    if (_isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }
          final part = state.items[index];
          return _buildProductCard(part, isGrid: true);
        },
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        final part = state.items[index];
        return _buildProductCard(part, isGrid: false);
      },
    );
  }

  Widget _buildProductCard(PartItem part, {required bool isGrid}) {
    return KeraProductCard(
      isGrid: isGrid,
      title: part.displayName,
      partNumber: part.partNumber,
      brandName: part.brandName,
      shelfLocation: part.customLocation,
      photoPath: part.photoLocalPath,
      price: part.sellingPrice,
      currencySymbol: context.tr('ብር', 'ETB'),
      stockQuantity: part.cachedQuantity,
      unit: part.unit,
      isLowStock: part.isLowStock,
      isOutOfStock: part.isOutOfStock,
      outOfStockLabel: context.tr('ያለቀ', 'Out of Stock'),
      onTap: () async {
        final result = await context.push('/parts/${part.id}');
        if (result == true && mounted) {
          final container = ProviderScope.containerOf(context);
          await container.read(inventoryListProvider.notifier).refresh();
        }
      },
    );
  }

  /// Stitch Screen 18: Empty Inventory State (ባዶ መጋዘን)
  Widget _buildStoreEmptyState(dynamic l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: KeraColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 46,
                color: KeraColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('ባዶ መጋዘን', 'Inventory Empty'),
              style: KeraTypography.titleMedium().copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'በመጋዘንዎ ውስጥ ምንም የተመዘገበ መለዋወጫ ዕቃ የለም። አዲስ ዕቃ በመመዝገብ ወይም የሙከራ ዕቃዎችን በመጫን ይጀምሩ።',
                'There are no spare parts recorded in your inventory. Start by adding a part or loading sample data.',
              ),
              textAlign: TextAlign.center,
              style: KeraTypography.bodyMedium(color: KeraColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/parts/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.actionBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _handleSeedParts,
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(context.tr('የናሙና ዕቃዎች ጫን', 'Load Sample Parts')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch Screen 19: Search Results Empty State (የዕቃዎች ፍለጋ ውጤቶች)
  Widget _buildSearchEmptyState(dynamic l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: KeraColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: KeraColors.actionBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noFilteredPartsTitle,
              style: KeraTypography.titleMedium().copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noFilteredPartsDesc,
              textAlign: TextAlign.center,
              style: KeraTypography.bodyMedium(color: KeraColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _onClearSearch();
                ref.read(inventoryFilterProvider.notifier).resetFilters();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.resetFilters),
              style: OutlinedButton.styleFrom(
                foregroundColor: KeraColors.actionBlue,
                side: const BorderSide(color: KeraColors.actionBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
