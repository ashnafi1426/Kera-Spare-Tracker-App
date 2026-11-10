import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/owner_header_bar.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/announcement_banner_widget.dart';
import '../../../../core/widgets/kera_image_widget.dart';
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

/// Commercial Enterprise Inventory Screen for Kera Spare Tracker.
/// Fixed dark navy curved masthead, 4 KPI cards (Total, In Stock, Low Stock, Out of Stock),
/// search bar, filter pills, sorting, real product images fetched from backend or local,
/// and floating "+ Add Part" button.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

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
            const Icon(Icons.qr_code_scanner_rounded, color: KeraColors.brandOrange),
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
                hintText: 'e.g. CAT-1000, 1R-0716...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C2340),
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('ፈልግ', 'Search')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    final ownerId = ref.read(currentOwnerIdProvider);
    if (ownerId.isEmpty) return;
    try {
      context.showSnackBar(context.tr('ወደ ውጭ በመላክ ላይ...', 'Exporting CSV...'));
      final file = await ref.read(exportBackupServiceProvider).exportInventoryCsv(ownerId: ownerId);
      if (mounted) {
        context.showSnackBar(context.tr('ፋይል ተቀምጧል: ${file.path}', 'File exported: ${file.path}'));
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(context.tr('ወደ ውጭ መላክ አልተሳካም: $e', 'Export failed: $e'), isError: true);
      }
    }
  }

  Future<void> _handleCardAction(String action, PartItem part) async {
    if (action == 'view') {
      final result = await context.push('/parts/${part.id}');
      if (result == true && mounted) {
        await ref.read(inventoryListProvider.notifier).refresh();
      }
    } else if (action == 'edit') {
      final result = await context.push('/parts/${part.id}/edit');
      if (result == true && mounted) {
        await ref.read(inventoryListProvider.notifier).refresh();
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('ዕቃ ሰርዝ?', 'Delete Part?')),
          content: Text(context.tr('ይህን ዕቃ መሰረዝ እርግጠኛ ነዎት?', 'Are you sure you want to delete this part?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('ተመለስ', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: KeraColors.error),
              child: Text(context.tr('ሰርዝ', 'Delete')),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        final res = await ref.read(partsRepositoryProvider).deletePart(
              ownerId: ref.read(currentOwnerIdProvider),
              id: part.id,
            );
        if (res.isSuccess && mounted) {
          context.showSnackBar(context.tr('ዕቃው ተሰርዟል', 'Part deleted'));
          await ref.read(inventoryListProvider.notifier).refresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(inventoryFilterProvider);
    final state = ref.watch(inventoryListProvider);
    final authUser = ref.watch(authControllerProvider).value;
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;

    final allParts = ref.watch(partsStreamProvider).value ?? [];
    final allCount = allParts.length;
    final inStockCount = allParts.where((p) => p.cachedQuantity > (p.lowStockLevel ?? 5) && p.cachedQuantity > 0).length;
    final lowStockCount = allParts.where((p) => p.cachedQuantity > 0 && p.cachedQuantity <= (p.lowStockLevel ?? 5)).length;
    final outOfStockCount = allParts.where((p) => p.cachedQuantity <= 0).length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Pinned Dark Navy Curved Masthead (Stays fixed at top)
            _buildPinnedMasthead(context, authUser),

            // System Alert Banners
            const MaintenanceBannerWidget(),
            const SuspendedAccountBannerWidget(),
            const AnnouncementBannerWidget(),

            // 2. Top-Clamped Body Content (CustomScrollView with ClampingScrollPhysics)
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFF7941D),
                onRefresh: () => ref.read(inventoryListProvider.notifier).refresh(),
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // Section A: Title, Pending & Export Row
                      SliverToBoxAdapter(
                        child: _buildInventoryTitleRow(context, pendingSync),
                      ),

                      // Section B: 4 KPI Cards (2x2 Grid)
                      SliverToBoxAdapter(
                        child: _buildKpiGrid(
                          context,
                          allCount: allCount,
                          inStockCount: inStockCount,
                          lowStockCount: lowStockCount,
                          outOfStockCount: outOfStockCount,
                          filter: filter,
                        ),
                      ),

                      // Section C: Search Bar
                      SliverToBoxAdapter(
                        child: _buildSearchBar(),
                      ),

                      // Section D: Filter Status Pills
                      SliverToBoxAdapter(
                        child: _buildFilterPills(
                          filter: filter,
                          allCount: allCount,
                          inStockCount: inStockCount,
                          lowStockCount: lowStockCount,
                          outOfStockCount: outOfStockCount,
                        ),
                      ),

                      // Section E: Filter & Sort Action Row
                      SliverToBoxAdapter(
                        child: _buildFilterAndSortRow(filter),
                      ),

                      // Section F: List Header (Item Count & Inline Add Part CTA matching Figma)
                      SliverToBoxAdapter(
                        child: _buildListHeaderRow(context, state.totalCount ?? allCount),
                      ),

                      // Section G: Products List or Empty States
                      _buildProductsListSliver(state, filter, l10n),

                      // Bottom spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. PINNED DARK NAVY MASTHEAD (MATCHING APPROVED FIGMA DESIGN)
  Widget _buildPinnedMasthead(BuildContext context, dynamic authUser) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1528) : const Color(0xFF173655),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Logo squircle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.settings_suggest_rounded,
                color: Color(0xFF173655),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kera Spare Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Track · Manage · Grow',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFA5B4CB),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Theme toggle
          const OwnerThemeToggle(),
          const SizedBox(width: 4),
          // Notification bell with unread badge 2
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Profile Avatar
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: KeraAvatarWidget(
                photoUrl: authUser?.photoUrl,
                name: authUser?.businessName ?? 'HK',
                radius: 17,
                isDark: true,
                backgroundColor: const Color(0xFF1E3A5F),
                textColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. INVENTORY TITLE + PENDING & EXPORT BUTTONS
  Widget _buildInventoryTitleRow(BuildContext context, int pendingSync) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('ዕቃዎች', 'Inventory'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('የመለዋወጫ ዕቃዎችዎን ያስተዳድሩ።', 'Manage your spare parts inventory.'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Pending pill + Export button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF173655),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pending ($pendingSync)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF173655),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _handleExport,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173655),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F173655),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

  // 3. 4 KPI SUMMARY CARDS (2x2 Grid matching Figma specification)
  Widget _buildKpiGrid(
    BuildContext context, {
    required int allCount,
    required int inStockCount,
    required int lowStockCount,
    required int outOfStockCount,
    required InventoryFilter filter,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: context.tr('ጠቅላላ ዕቃዎች', 'Total Items'),
                  count: allCount,
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFF2563EB),
                  iconBgLight: const Color(0xFFEFF6FF),
                  bgLight: const Color(0xFFEFF6FF),
                  borderLight: const Color(0xFFDBEAFE),
                  bgDark: const Color(0xFF0F1E36),
                  borderDark: const Color(0xFF1E3A8A),
                  isSelected: filter.stockFilter == StockFilter.all,
                  onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.all),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: context.tr('ክምችት ያለው', 'In Stock'),
                  count: inStockCount,
                  icon: Icons.check_circle_rounded,
                  accentColor: const Color(0xFF16A34A),
                  iconBgLight: const Color(0xFFECFDF5),
                  bgLight: const Color(0xFFF0FDF4),
                  borderLight: const Color(0xFFDCFCE7),
                  bgDark: const Color(0xFF06231A),
                  borderDark: const Color(0xFF14532D),
                  isSelected: filter.stockFilter == StockFilter.inStock,
                  onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.inStock),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: context.tr('ሊያልቅ ነው', 'Low Stock'),
                  count: lowStockCount,
                  icon: Icons.warning_amber_rounded,
                  accentColor: const Color(0xFFD97706),
                  iconBgLight: const Color(0xFFFEF3C7),
                  bgLight: const Color(0xFFFFFBEB),
                  borderLight: const Color(0xFFFEF3C7),
                  bgDark: const Color(0xFF261908),
                  borderDark: const Color(0xFF78350F),
                  isSelected: filter.stockFilter == StockFilter.lowStock,
                  onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.lowStock),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: context.tr('ያለቀ', 'Out of Stock'),
                  count: outOfStockCount,
                  icon: Icons.cancel_rounded,
                  accentColor: const Color(0xFFDC2626),
                  iconBgLight: const Color(0xFFFEE2E2),
                  bgLight: const Color(0xFFFEF2F2),
                  borderLight: const Color(0xFFFEE2E2),
                  bgDark: const Color(0xFF260D0D),
                  borderDark: const Color(0xFF7F1D1D),
                  isSelected: filter.stockFilter == StockFilter.outOfStock,
                  onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(StockFilter.outOfStock),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color iconBgLight,
    required Color bgLight,
    required Color borderLight,
    required Color bgDark,
    required Color borderDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? bgDark : bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : (isDark ? borderDark : borderLight),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? accentColor.withValues(alpha: 0.2) : iconBgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. SEARCH BAR
  Widget _buildSearchBar() {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0C2340),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
            hintText: 'Search by part name, OEM, brand...',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: _onClearSearch,
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF0C2340),
                    size: 22,
                  ),
                  tooltip: 'Scan barcode or QR code',
                  onPressed: _showBarcodeScannerModal,
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  // 5. FILTER PILLS ROW
  Widget _buildFilterPills({
    required InventoryFilter filter,
    required int allCount,
    required int inStockCount,
    required int lowStockCount,
    required int outOfStockCount,
  }) {
    final pills = [
      (label: context.tr('ሁሉም ($allCount)', 'All ($allCount)'), filter: StockFilter.all, hasIcon: true),
      (label: context.tr('ክምችት ያለው ($inStockCount)', 'In Stock ($inStockCount)'), filter: StockFilter.inStock, hasIcon: false),
      (label: context.tr('ሊያልቅ ነው ($lowStockCount)', 'Low Stock ($lowStockCount)'), filter: StockFilter.lowStock, hasIcon: false),
      (label: context.tr('ያለቀ ($outOfStockCount)', 'Out of Stock ($outOfStockCount)'), filter: StockFilter.outOfStock, hasIcon: false),
    ];

    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills.map((p) {
            final isSelected = filter.stockFilter == p.filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(p.filter),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF7941D)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF7941D)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF7941D).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.hasIcon && isSelected) ...[
                        const Icon(Icons.grid_view_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 6. FILTER & SORT OPTION ROW
  Widget _buildFilterAndSortRow(InventoryFilter filter) {
    final isDark = context.isDark;
    final sortLabel = switch (filter.sortBy) {
      PartsSortBy.newest => 'Recently Added',
      PartsSortBy.name => 'Name (A-Z)',
      PartsSortBy.quantity => 'Quantity',
      PartsSortBy.price => 'Price',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter button
          InkWell(
            onTap: () => InventoryFilterSheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filter.filterCount > 0
                      ? const Color(0xFFF7941D)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          // Sort button
          PopupMenuButton<PartsSortBy>(
            onSelected: (sort) {
              ref.read(inventoryFilterProvider.notifier).setSort(
                    sort,
                    ascending: sort == PartsSortBy.name ? true : false,
                  );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: PartsSortBy.newest, child: Text('Recently Added')),
              PopupMenuItem(value: PartsSortBy.name, child: Text('Name (A-Z)')),
              PopupMenuItem(value: PartsSortBy.quantity, child: Text('Quantity')),
              PopupMenuItem(value: PartsSortBy.price, child: Text('Price')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Sort by: $sortLabel',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. PRODUCT CARD
  Widget _buildProductCard(PartItem part) {
    final isOutOfStock = part.isOutOfStock || part.cachedQuantity <= 0;
    final isLowStock = !isOutOfStock && (part.isLowStock || part.cachedQuantity <= 5);
    final isDark = context.isDark;

    final oemText = (part.partNumber != null && part.partNumber!.isNotEmpty)
        ? part.partNumber!
        : (part.brandName != null ? part.brandName! : 'OEM');
    final locationText = part.customLocation ?? 'Shelf 1';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleCardAction('view', part),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x22000000) : const Color(0x060C2340),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Photo Thumbnail (64x64)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: KeraPartImage(
                  localPath: part.photoLocalPath,
                  remoteUrl: part.photoUrl,
                  width: 64,
                  height: 64,
                  borderRadius: 12,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Middle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0C2340),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$oemText • $locationText',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Stock badge
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOutOfStock
                                ? Icons.error_outline_rounded
                                : isLowStock
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded,
                            size: 13,
                            color: isOutOfStock
                                ? const Color(0xFFDC2626)
                                : isLowStock
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock
                                ? context.tr('ያለቀ', 'Out of Stock')
                                : isLowStock
                                    ? context.tr('ሊያልቅ ነው', 'Low Stock')
                                    : context.tr('ክምችት ያለው', 'In Stock'),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: Price & quantity + more menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(part.sellingPrice ?? 0).toStringAsFixed(0)} ETB',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0C2340),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${part.cachedQuantity.toStringAsFixed(0)} ${context.tr("ፍሬ", "pcs")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onSelected: (val) => _handleCardAction(val, part),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'view', child: Text('View Details')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 8. PRODUCTS LIST SLIVER
  Widget _buildProductsListSliver(
    InventoryListState state,
    InventoryFilter filter,
    dynamic l10n,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: KeraLoadingIndicator()),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: KeraColors.error),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: KeraTypography.bodyMedium(color: context.textPrimaryColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(inventoryListProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C2340),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      final isFiltered = filter.hasActiveFilters || (_searchController.text.trim().isNotEmpty);
      return SliverFillRemaining(
        child: isFiltered ? _buildSearchEmptyState(l10n) : _buildStoreEmptyState(l10n),
      );
    }

    final itemCount = state.items.length + (state.hasMore ? 1 : 0);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= state.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: KeraLoadingIndicator.small(),
              ),
            );
          }
          final part = state.items[index];
          return _buildProductCard(part);
        },
        childCount: itemCount,
      ),
    );
  }

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
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 46,
                color: Color(0xFF0C2340),
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
                    backgroundColor: const Color(0xFF0C2340),
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
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF0C2340),
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
                foregroundColor: const Color(0xFF0C2340),
                side: const BorderSide(color: Color(0xFF0C2340)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
