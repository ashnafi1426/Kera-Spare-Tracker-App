import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

/// Screen 4: Global Catalog Management (Brands, Categories, Units)
/// matching the finalized Figma Design Specification.
///
/// Features:
/// - Executive Navy Header with breadcrumb "KERA / SPARE TRACKER", title "Global Catalog Management",
///   and integrated tabs (Brands, Categories, Units) with orange indicator.
/// - Title section with live count badge, "Shared across all locations" subtitle, and "+ Add New" orange CTA.
/// - Search capsule with clear action and sort/filter toggle button.
/// - Segmented status filter pills: "All [N]", "Active [N]", "Inactive [N]".
/// - Subheader row: list filter label and "Name A-Z ⇅" sort toggle.
/// - Catalog Item Cards:
///   - Top: Item name and edit pencil icon button.
///   - Bottom: Status badge (Active/Inactive) and Disabled/Active switch toggle.
/// - Reusable add/edit modal dialogs with form validation.
/// - Zero RenderFlex overflows down to 320dp screen width and dark mode support.
class AdminGlobalCatalogScreen extends ConsumerStatefulWidget {
  const AdminGlobalCatalogScreen({super.key});

  @override
  ConsumerState<AdminGlobalCatalogScreen> createState() =>
      _AdminGlobalCatalogScreenState();
}

class _AdminGlobalCatalogScreenState
    extends ConsumerState<AdminGlobalCatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog({
    required String title,
    required Future<bool> Function(String name) onAdd,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: l10n.name,
              hintText: context.tr('ስም ያስገቡ', 'Enter name...'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.required;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              l10n.add,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await onAdd(controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.success : l10n.error),
            backgroundColor: success ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog({
    required String currentName,
    required Future<bool> Function(String newName) onRename,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          l10n.adminRenameItem,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: l10n.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.required;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.navyDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await onRename(controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.success : l10n.error),
            backgroundColor: success ? AdminColors.success : AdminColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalogState = ref.watch(adminCatalogProvider);
    final notifier = ref.read(adminCatalogProvider.notifier);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Executive Navy Header matching Figma
          _buildExecutiveNavyHeader(context, l10n),

          // 2. Tab Views
          Expanded(
            child: catalogState.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: SkeletonListLoader(count: 6),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Brands
                      _FigmaCatalogSectionView(
                        categoryName: context.tr('ብራንዶች', 'Brands'),
                        items: catalogState.brands,
                        searchHint: context.tr('ብራንድ ፈልግ...', 'Search brands...'),
                        onAdd: () => _showAddDialog(
                          title: l10n.adminAddBrand,
                          onAdd: notifier.addBrand,
                        ),
                        onToggleActive: (item, val) =>
                            notifier.updateBrand(item.id, isActive: val),
                        onRename: (item) => _showRenameDialog(
                          currentName: item.name,
                          onRename: (newName) =>
                              notifier.updateBrand(item.id, name: newName),
                        ),
                        isDark: isDark,
                      ),

                      // Tab 2: Categories
                      _FigmaCatalogSectionView(
                        categoryName: context.tr('ምድቦች', 'Categories'),
                        items: catalogState.categories,
                        searchHint: context.tr('ምድብ ፈልግ...', 'Search categories...'),
                        onAdd: () => _showAddDialog(
                          title: l10n.adminAddCategory,
                          onAdd: notifier.addCategory,
                        ),
                        onToggleActive: (item, val) =>
                            notifier.updateCategory(item.id, isActive: val),
                        onRename: (item) => _showRenameDialog(
                          currentName: item.name,
                          onRename: (newName) =>
                              notifier.updateCategory(item.id, name: newName),
                        ),
                        isDark: isDark,
                      ),

                      // Tab 3: Units
                      _FigmaCatalogSectionView(
                        categoryName: context.tr('መለኪያዎች', 'Units'),
                        items: catalogState.units,
                        searchHint: context.tr('መለኪያ ፈልግ...', 'Search units...'),
                        onAdd: () => _showAddDialog(
                          title: l10n.adminAddUnit,
                          onAdd: notifier.addUnit,
                        ),
                        onToggleActive: (item, val) =>
                            notifier.updateUnit(item.id, isActive: val),
                        onRename: (item) => _showRenameDialog(
                          currentName: item.name,
                          onRename: (newName) =>
                              notifier.updateUnit(item.id, name: newName),
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 1. Executive Navy Header matching Figma
  Widget _buildExecutiveNavyHeader(BuildContext context, AppLocalizations l10n) {
    final isDark = context.isDark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF071322) : const Color(0xFF173655),
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb text: KERA / SPARE TRACKER
          Text(
            'KERA / SPARE TRACKER',
            style: TextStyle(
              color: const Color(0xFFA5B4CB).withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // Header Title
          Text(
            context.tr('አጠቃላይ ካታሎግ አስተዳደር', 'Global Catalog Management'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Tabs: Brands, Categories, Units
          TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AdminColors.keraOrange,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFA5B4CB),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: l10n.adminTabBrands),
              Tab(text: l10n.adminTabCategories),
              Tab(text: l10n.adminTabUnits),
            ],
          ),
        ],
      ),
    );
  }
}

/// Catalog Section View representing a single tab (Brands / Categories / Units).
class _FigmaCatalogSectionView extends StatefulWidget {
  final String categoryName;
  final List<GlobalCatalogItem> items;
  final String searchHint;
  final VoidCallback onAdd;
  final Future<bool> Function(GlobalCatalogItem item, bool val) onToggleActive;
  final void Function(GlobalCatalogItem item) onRename;
  final bool isDark;

  const _FigmaCatalogSectionView({
    required this.categoryName,
    required this.items,
    required this.searchHint,
    required this.onAdd,
    required this.onToggleActive,
    required this.onRename,
    required this.isDark,
  });

  @override
  State<_FigmaCatalogSectionView> createState() =>
      _FigmaCatalogSectionViewState();
}

enum _CatalogStatusFilter { all, active, inactive }

class _FigmaCatalogSectionViewState extends State<_FigmaCatalogSectionView> {
  final TextEditingController _searchController = TextEditingController();
  _CatalogStatusFilter _selectedFilter = _CatalogStatusFilter.all;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSwitch(GlobalCatalogItem item, bool newValue) async {
    final l10n = AppLocalizations.of(context)!;
    if (!newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => ConfirmDialog(
          title: l10n.adminConfirmDeactivateTitle,
          description: l10n.adminConfirmDeactivateMessage(item.name),
          confirmLabel: l10n.adminInactiveLabel,
          isDestructive: true,
          requireReason: false,
        ),
      );
      if (confirmed != true) return;
    }

    final success = await widget.onToggleActive(item, newValue);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDark;
    final query = _searchController.text.trim().toLowerCase();

    // 1. Apply status filter
    var list = widget.items.where((i) {
      if (_selectedFilter == _CatalogStatusFilter.active) return i.isActive;
      if (_selectedFilter == _CatalogStatusFilter.inactive) return !i.isActive;
      return true;
    }).toList();

    // 2. Apply search query
    if (query.isNotEmpty) {
      list = list.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    // 3. Apply sorting
    list.sort((a, b) => _sortAscending
        ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : b.name.toLowerCase().compareTo(a.name.toLowerCase()));

    final totalCount = widget.items.length;
    final activeCount = widget.items.where((i) => i.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return RefreshIndicator(
      color: AdminColors.keraOrange,
      onRefresh: () async {
        // Trigger parent state reload through context or ref
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // A. Section Header: Title + Badge + Subtitle + "+ Add New" Button
          _buildTitleRow(context, totalCount),
          const SizedBox(height: 14),

          // B. Search Field + Filter Button Row
          _buildSearchRow(context),
          const SizedBox(height: 14),

          // C. Segmented Status Filter Bar (All N | Active N | Inactive N)
          _buildStatusFilterSegment(
            context,
            totalCount: totalCount,
            activeCount: activeCount,
            inactiveCount: inactiveCount,
          ),
          const SizedBox(height: 16),

          // D. Subheader: "All brands" / "Active brands" + "Name A-Z ⇅"
          _buildSubheaderRow(context, list.length),
          const SizedBox(height: 12),

          // E. Catalog Cards List
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: EmptyState(
                  icon: Icons.category_outlined,
                  title: l10n.noResultsFound,
                  onAction: query.isNotEmpty
                      ? () {
                          _searchController.clear();
                          setState(() {});
                        }
                      : widget.onAdd,
                  actionLabel: query.isNotEmpty ? l10n.refresh : l10n.add,
                ),
              ),
            )
          else
            ...list.map((item) => _buildCatalogItemCard(context, item, isDark)),
        ],
      ),
    );
  }

  // A. Section Title & Add Action Row
  Widget _buildTitleRow(BuildContext context, int totalCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Count Badge & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.categoryName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEAF1FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF173655),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('በሁሉም ቦታዎች የተጋራ', 'Shared across all locations'),
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // "+ Add New" Orange Button
        ElevatedButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
          label: Text(
            context.tr('አዲስ ጨምር', 'Add New'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.keraOrange,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // B. Search Bar + Filter Action Row
  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        // Search Capsule
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: context.textSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: widget.searchHint,
                      hintStyle: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: context.textSecondaryColor,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sort/Filter Square Button
        InkWell(
          onTap: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: context.textPrimaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // C. Segmented Status Filter Bar (All N | Active N | Inactive N)
  Widget _buildStatusFilterSegment(
    BuildContext context, {
    required int totalCount,
    required int activeCount,
    required int inactiveCount,
  }) {
    final isDark = widget.isDark;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              context,
              label: '${context.tr("ሁሉም", "All")}  $totalCount',
              isSelected: _selectedFilter == _CatalogStatusFilter.all,
              onTap: () => setState(() => _selectedFilter = _CatalogStatusFilter.all),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              context,
              label: '${context.tr("ንቁ", "Active")}  $activeCount',
              isSelected: _selectedFilter == _CatalogStatusFilter.active,
              onTap: () => setState(() => _selectedFilter = _CatalogStatusFilter.active),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              context,
              label: '${context.tr("ያልሰራ", "Inactive")}  $inactiveCount',
              isSelected: _selectedFilter == _CatalogStatusFilter.inactive,
              onTap: () => setState(() => _selectedFilter = _CatalogStatusFilter.inactive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? context.textPrimaryColor
                    : context.textSecondaryColor,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  // D. Subheader Row: "All brands" / "Active brands" + "Name A-Z ⇅"
  Widget _buildSubheaderRow(BuildContext context, int displayCount) {
    String filterLabel;
    switch (_selectedFilter) {
      case _CatalogStatusFilter.all:
        filterLabel = context.tr('ሁሉም ${widget.categoryName}', 'All ${widget.categoryName.toLowerCase()}');
        break;
      case _CatalogStatusFilter.active:
        filterLabel = context.tr('ንቁ ${widget.categoryName}', 'Active ${widget.categoryName.toLowerCase()}');
        break;
      case _CatalogStatusFilter.inactive:
        filterLabel = context.tr('ያልሰሩ ${widget.categoryName}', 'Inactive ${widget.categoryName.toLowerCase()}');
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            filterLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Sort toggle indicator
        InkWell(
          onTap: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortAscending ? 'Name A–Z' : 'Name Z–A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // E. Figma Catalog Item Card (Brand, Category, Unit)
  Widget _buildCatalogItemCard(
    BuildContext context,
    GlobalCatalogItem item,
    bool isDark,
  ) {
    return ListCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Item Name + Edit Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Edit pencil button
              InkWell(
                onTap: () => widget.onRename(item),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Status Badge (Left) + Disabled/Active Switch (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F7EF))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isActive
                          ? const Color(0xFF159B55).withValues(alpha: 0.3)
                          : context.borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    item.isActive
                        ? context.tr('ንቁ', 'Active')
                        : context.tr('ያልሰራ', 'Inactive'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.isActive
                          ? const Color(0xFF159B55)
                          : context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Disabled / Active Switch Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.isActive
                        ? context.tr('ተሰናድቷል', 'Active')
                        : context.tr('ተሰናክሏል', 'Disabled'),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: item.isActive,
                      activeTrackColor: AdminColors.keraOrange,
                      activeThumbColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) => _handleSwitch(item, val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
