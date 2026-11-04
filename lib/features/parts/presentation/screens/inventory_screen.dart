import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/owner_header_bar.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/announcement_banner_widget.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../../core/widgets/maintenance_banner_widget.dart';
import '../../../../core/widgets/suspended_account_banner_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/data/services/export_backup_service.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/part_item.dart';
import '../providers/inventory_providers.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';
import '../widgets/inventory_filter_sheet.dart';
import '../widgets/sample_parts_dialog.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/design/widgets/kera_app_footer.dart';



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

  void _handleSeedParts() {
    SamplePartsDialog.show(context);
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
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
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
    final businessName = authUser?.businessName ?? context.tr('ተስፋዬ እና ልጆቹ', 'Tesfaye & Sons');
    final partsCount = ref.watch(inventoryListProvider).items.length;
    final isDark = context.isDark;

    return Container(
      color: isDark ? const Color(0xFF071322) : const Color(0xFF0C2340),
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
                    Text(
                      context.tr('ከራ · Kera Spare Tracker', 'Kera · Spare Tracker'),
                      style: const TextStyle(
                        color: Color(0xFFA5B4CB),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const OwnerThemeToggle(),
              const SizedBox(width: 6),
              const OwnerLanguageToggle(),
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
                  Text(
                    context.tr('ዕቃዎች', 'Inventory'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.tr('$partsCount ዕቃዎች', '$partsCount items'),
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
                      pendingSync == 0
                          ? context.tr('ተመሳስሏል', 'Synced')
                          : context.tr('ያልተመሳሰለ $pendingSync', 'Pending $pendingSync'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final ownerId = ref.read(currentOwnerIdProvider);
                      if (ownerId.isEmpty) return;
                      try {
                        context.showSnackBar(context.tr('ወደ ውጭ በመላክ ላይ...', 'Exporting CSV...'));
                        final file = await ref.read(exportBackupServiceProvider).exportInventoryCsv(ownerId: ownerId);
                        if (context.mounted) {
                          context.showSnackBar(context.tr('ፋይል ተቀምጧል: ${file.path}', 'File exported: ${file.path}'));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBar(context.tr('ወደ ውጭ መላክ አልተሳካም: $e', 'Export failed: $e'), isError: true);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('ወደ ውጭ ላክ', 'Export'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _handleSeedParts,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7941D).withValues(alpha: 0.25),
                          border: Border.all(color: const Color(0xFFF7941D)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.science_rounded, color: Color(0xFFF7941D), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('ናሙና (Dev)', 'Sample (Dev)'),
                              style: const TextStyle(
                                color: Color(0xFFF7941D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    final isDark = context.isDark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
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
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: context.tr('ስም፣ ቁጥር፣ ብራንድ፣ አካባቢ', 'Search name, OEM, brand, shelf...'),
          hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  onPressed: _onClearSearch,
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFFF58220)),
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
    final partsList = ref.watch(partsStreamProvider).value ?? [];
    final allCount = partsList.length;
    final inStockCount = partsList.where((p) => p.isInStock).length;
    final lowStockCount = partsList.where((p) => p.isLowStock).length;
    final outOfStockCount = partsList.where((p) => p.isOutOfStock).length;
    final activeFilterCount = filter.filterCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filter Sheet Launcher button with active badge
          InkWell(
            onTap: () => InventoryFilterSheet.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: activeFilterCount > 0
                    ? const Color(0xFFF7941D)
                    : (context.isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeFilterCount > 0
                      ? const Color(0xFFF7941D)
                      : (context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: activeFilterCount > 0 ? Colors.white : context.textPrimaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('አጣራ', 'Filters'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: activeFilterCount > 0 ? Colors.white : context.textPrimaryColor,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          color: Color(0xFFF7941D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // All (ሁሉም) Chip
          _buildPillChip(
            label: context.tr('ሁሉም ($allCount)', 'All ($allCount)'),
            isSelected: filter.stockFilter == StockFilter.all,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.all);
            },
          ),
          const SizedBox(width: 8),

          // In Stock (ክምችት ያለው) Chip
          _buildPillChip(
            label: context.tr('ክምችት ያለው ($inStockCount)', 'In Stock ($inStockCount)'),
            isSelected: filter.stockFilter == StockFilter.inStock,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.inStock);
            },
          ),
          const SizedBox(width: 8),

          // Low Stock (ሊያልቅ ነው) Chip
          _buildPillChip(
            label: context.tr('ሊያልቅ ነው ($lowStockCount)', 'Low Stock ($lowStockCount)'),
            isSelected: filter.stockFilter == StockFilter.lowStock,
            isWarningPill: true,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.lowStock);
            },
          ),
          const SizedBox(width: 8),

          // Out of Stock (ያለቀ) Chip
          _buildPillChip(
            label: context.tr('ያለቀ ($outOfStockCount)', 'Out of Stock ($outOfStockCount)'),
            isSelected: filter.stockFilter == StockFilter.outOfStock,
            isErrorPill: true,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.outOfStock);
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
    bool isErrorPill = false,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340))
              : isWarningPill
                  ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                  : isErrorPill
                      ? (isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6))
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF0C2340))
                : isWarningPill
                    ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                    : isErrorPill
                        ? (isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3))
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                    ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                    : isErrorPill
                        ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))
                        : context.textPrimaryColor,
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
      return KeraLoadingView(
        message: context.tr('ዕቃዎችን በመጫን ላይ...', 'Loading inventory items...'),
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
                style: KeraTypography.bodyMedium(color: context.textPrimaryColor),
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
                child: KeraLoadingIndicator.small(),
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
              child: KeraLoadingIndicator.small(),
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
    final isDark = context.isDark;

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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x22000000) : const Color(0x060C2340),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Squircle Part Image Thumbnail
            KeraPartImage(
              localPath: part.photoLocalPath,
              photoUrl: part.photoUrl,
              width: 50,
              height: 50,
              borderRadius: 14,
            ),
            const SizedBox(width: 12),

            // Middle: Name, Number & Brand, Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (part.isDemo)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: KeraColors.brandOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KeraColors.brandOrange),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.tr("ቁጥር", "No.")} ${part.partNumber?.isNotEmpty == true ? part.partNumber : "-"} · ${part.brandName?.isNotEmpty == true ? part.brandName : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (part.customLocation != null && part.customLocation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 12, color: context.textSecondaryColor),
                        const SizedBox(width: 2),
                        Text(
                          part.customLocation!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Price, Quantity, Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(part.sellingPrice ?? 0).toStringAsFixed(0)} ETB',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${part.cachedQuantity.toStringAsFixed(0)} ${context.tr("ፍሬ", "pcs")}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                        : isLowStock
                            ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                            : (isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOutOfStock
                        ? context.tr('አልቋል', 'Out of Stock')
                        : isLowStock
                            ? context.tr('ሊያልቅ ነው', 'Low Stock')
                            : context.tr('በቂ', 'In Stock'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                          : isLowStock
                              ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                              : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                    ),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: context.textSecondaryColor),
              onSelected: (val) async {
                if (val == 'view') {
                  final result = await context.push('/parts/${part.id}');
                  if (result == true && mounted) {
                    ref.read(inventoryListProvider.notifier).refresh();
                  }
                } else if (val == 'edit') {
                  final result = await context.push('/parts/${part.id}/edit');
                  if (result == true && mounted) {
                    ref.read(inventoryListProvider.notifier).refresh();
                  }
                } else if (val == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(context.tr('ዕቃ ሰርዝ?', 'Delete Part?')),
                      content: Text(context.tr('ይህን ዕቃ መሰረዝ እርግጠኛ ነዎት?', 'Are you sure you want to delete this part?')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('ተመለስ', 'Cancel'))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: KeraColors.statusError),
                          child: Text(context.tr('ሰርዝ', 'Delete')),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    final res = await ref.read(partsRepositoryProvider).deletePart(
                      ownerId: ref.read(currentOwnerIdProvider),
                      partId: part.id,
                    );
                    if (res.isSuccess && mounted) {
                      context.showSnackBar(context.tr('ዕቃው ተሰርዟል', 'Part deleted'));
                      ref.read(inventoryListProvider.notifier).refresh();
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'view', child: Text(context.tr('ዝርዝር አሳይ', 'View Details'))),
                PopupMenuItem(value: 'edit', child: Text(context.tr('አስተካክል', 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(context.tr('ሰርዝ', 'Delete'), style: const TextStyle(color: Colors.red))),
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

