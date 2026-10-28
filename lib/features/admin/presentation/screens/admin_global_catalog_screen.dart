import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

/// Screen 4: Manage system-wide global catalogs (Brands, Categories, Units).
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
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        ),
        title: Text(title, style: AdminTypography.h3),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(labelText: l10n.name),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.required;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.add),
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
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        ),
        title: Text(l10n.adminRenameItem, style: AdminTypography.h3),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: AdminTypography.bodyMedium,
            decoration: InputDecoration(labelText: l10n.name),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.required;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.save),
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

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminCatalogTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AdminColors.primary,
          indicatorWeight: 3,
          labelColor: AdminColors.primary,
          unselectedLabelColor: AdminColors.textSecondary,
          labelStyle: AdminTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AdminTypography.bodyMedium,
          tabs: [
            Tab(text: l10n.adminTabBrands),
            Tab(text: l10n.adminTabCategories),
            Tab(text: l10n.adminTabUnits),
          ],
        ),
      ),
      body: catalogState.isLoading
          ? const Padding(
              padding: EdgeInsets.all(AdminSpacing.lg),
              child: SkeletonListLoader(count: 6),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Brands Tab
                _CatalogListView(
                  items: catalogState.brands,
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
                ),

                // 2. Categories Tab
                _CatalogListView(
                  items: catalogState.categories,
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
                ),

                // 3. Units Tab
                _CatalogListView(
                  items: catalogState.units,
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
                ),
              ],
            ),
    );
  }
}

class _CatalogListView extends StatefulWidget {
  final List<GlobalCatalogItem> items;
  final VoidCallback onAdd;
  final Future<bool> Function(GlobalCatalogItem item, bool val) onToggleActive;
  final void Function(GlobalCatalogItem item) onRename;

  const _CatalogListView({
    required this.items,
    required this.onAdd,
    required this.onToggleActive,
    required this.onRename,
  });

  @override
  State<_CatalogListView> createState() => _CatalogListViewState();
}

class _CatalogListViewState extends State<_CatalogListView> {
  final TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSwitch(GlobalCatalogItem item, bool newValue) async {
    final l10n = AppLocalizations.of(context)!;
    if (!newValue) {
      // Confirm deactivation
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
    final query = _searchController.text.trim().toLowerCase();

    var filtered = widget.items.where((i) {
      if (query.isEmpty) return true;
      return i.name.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) => _sortAscending
        ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : b.name.toLowerCase().compareTo(a.name.toLowerCase()));

    final activeCount = widget.items.where((i) => i.isActive).length;
    final totalCount = widget.items.length;

    return Column(
      children: [
        // Search & Sort bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.lg,
            AdminSpacing.sm,
            AdminSpacing.lg,
            AdminSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AdminTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '${l10n.search}...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AdminColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.sort_by_alpha_rounded : Icons.sort_by_alpha_outlined,
                  color: AdminColors.textSecondary,
                ),
                tooltip: l10n.adminSortAtoZ,
                onPressed: () => setState(() => _sortAscending = !_sortAscending),
              ),
            ],
          ),
        ),

        // Summary count & Add button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip(
                label: l10n.adminCatalogActiveCount(activeCount, totalCount),
                icon: Icons.inventory_2_outlined,
                color: AdminColors.primary,
                backgroundColor: AdminColors.infoTint,
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                  ),
                ),
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.add),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminColors.border),

        // Items list
        Expanded(
          child: filtered.isEmpty
              ? Center(
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.lg,
                    vertical: AdminSpacing.sm,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AdminSpacing.xs),
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    return ListCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AdminTypography.bodyMedium.copyWith(
                                    fontWeight: item.isActive ? FontWeight.w600 : FontWeight.normal,
                                    color: item.isActive
                                        ? AdminColors.textPrimary
                                        : AdminColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AdminSpacing.xs),
                                StatusChip(
                                  label: item.isActive
                                      ? l10n.adminActiveLabel
                                      : l10n.adminInactiveLabel,
                                  color: item.isActive
                                      ? AdminColors.success
                                      : AdminColors.textSecondary,
                                  backgroundColor: item.isActive
                                      ? AdminColors.successTint
                                      : AdminColors.border,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: AdminColors.primary,
                              size: 22,
                            ),
                            tooltip: l10n.edit,
                            onPressed: () => widget.onRename(item),
                          ),
                          Switch.adaptive(
                            value: item.isActive,
                            activeTrackColor: AdminColors.primary,
                            activeThumbColor: Colors.white,
                            onChanged: (val) => _handleSwitch(item, val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
