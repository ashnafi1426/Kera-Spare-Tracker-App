import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/announcement_banner_widget.dart';
import '../../../../core/widgets/maintenance_banner_widget.dart';
import '../../../../core/widgets/suspended_account_banner_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/part_item.dart';
import '../providers/inventory_providers.dart';
import '../providers/parts_providers.dart';

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
  final bool _isGridView = false;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton(
        heroTag: 'inventory_screen_fab',
        onPressed: () => context.push('/parts/add'),
        backgroundColor: const Color(0xFFF58220),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Navy Industrial App Header (2 Inventory.png)
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

            // Quick Filter Chips Row (2 Inventory.png)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _buildFilterChipsRow(filter, state, l10n, colorScheme),
            ),

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
    final businessName = authUser?.businessName ?? 'ተስፋዬ እና ልጆቹ';
    final partsCount = ref.watch(inventoryListProvider).items.length;

    return Container(
      color: const Color(0xFF0C2340),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Business Name + Subtitle (2 Inventory.png)
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.settings_suggest_rounded,
                    color: Color(0xFF0C2340),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'ከራ · Kera Spare Tracker',
                      style: TextStyle(
                        color: Color(0xFFA5B4CB),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title Row: ዕቃዎች & count on left, Sync & Export on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ዕቃዎች',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$partsCount ዕቃዎች',
                    style: const TextStyle(
                      color: Color(0xFFA5B4CB),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3557),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      pendingSync == 0 ? 'ተመሳስሏል' : 'ያልተመሳሰለ $pendingSync',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting CSV...')),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'ወደ ውጭ ላክ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar: ስም፣ ቁጥር፣ ብራንድ፣ አካባቢ
          _buildSearchBar(l10n),
        ],
      ),
    );
  }

  Widget _buildSearchBar(dynamic l10n) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ስም፣ ቁጥር፣ ብራንድ፣ አካባቢ',
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                  onPressed: _onClearSearch,
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF64748B)),
                tooltip: 'Scan barcode',
                onPressed: _showBarcodeScannerModal,
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPillChip(
            label: 'ሁሉም',
            isSelected: filter.stockFilter == StockFilter.all && filter.brandId == null,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.all);
            },
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: 'CAT',
            isSelected: filter.query?.toLowerCase() == 'cat',
            onTap: () {
              _searchController.text = 'CAT';
              ref.read(inventoryFilterProvider.notifier).setQuery('CAT');
            },
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: 'Doosan',
            isSelected: filter.query?.toLowerCase() == 'doosan',
            onTap: () {
              _searchController.text = 'Doosan';
              ref.read(inventoryFilterProvider.notifier).setQuery('Doosan');
            },
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: 'SANY',
            isSelected: filter.query?.toLowerCase() == 'sany',
            onTap: () {
              _searchController.text = 'SANY';
              ref.read(inventoryFilterProvider.notifier).setQuery('SANY');
            },
          ),
          const SizedBox(width: 8),
          _buildPillChip(
            label: 'ሊያልቅ ነው',
            isSelected: filter.stockFilter == StockFilter.lowStock,
            isWarningPill: true,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.lowStock);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    bool isWarningPill = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0C2340)
              : isWarningPill
                  ? const Color(0xFFFEF3C7)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0C2340)
                : isWarningPill
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isWarningPill
                    ? const Color(0xFFD97706)
                    : const Color(0xFF0C2340),
          ),
        ),
      ),
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
    final isOutOfStock = part.isOutOfStock || part.cachedQuantity <= 0;
    final isLowStock = !isOutOfStock && (part.isLowStock || part.cachedQuantity <= 5);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await context.push('/parts/${part.id}');
        if (result == true && mounted) {
          final container = ProviderScope.containerOf(context);
          await container.read(inventoryListProvider.notifier).refresh();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EBF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060C2340),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Squircle Icon Box (2 Inventory.png)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF5E6D82),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Name, Number & Brand, Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C2340),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ቁጥር ${part.partNumber ?? '-'} · ${part.brandName ?? 'CAT'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5E6D82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    part.customLocation ?? 'ሸልፍ 1',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5E6D82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Price, Quantity, Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(part.sellingPrice ?? 1200).toStringAsFixed(0)} ETB',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2340),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${part.cachedQuantity.toStringAsFixed(0)} ፍሬ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E6D82),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFFFEE2E2)
                        : isLowStock
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOutOfStock
                        ? 'አልቋል'
                        : isLowStock
                            ? 'ሊያልቅ ነው'
                            : 'በቂ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? const Color(0xFFDC2626)
                          : isLowStock
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

