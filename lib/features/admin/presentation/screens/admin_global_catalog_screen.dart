import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
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
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
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
        title: Text(l10n.adminRenameItem),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
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
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
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
      appBar: AppBar(
        title: Text(l10n.adminCatalogTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.adminTabBrands),
            Tab(text: l10n.adminTabCategories),
            Tab(text: l10n.adminTabUnits),
          ],
        ),
      ),
      body: catalogState.isLoading
          ? const Center(child: CircularProgressIndicator())
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

class _CatalogListView extends StatelessWidget {
  final List<GlobalCatalogItem> items;
  final VoidCallback onAdd;
  final void Function(GlobalCatalogItem item, bool val) onToggleActive;
  final void Function(GlobalCatalogItem item) onRename;

  const _CatalogListView({
    required this.items,
    required this.onAdd,
    required this.onToggleActive,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} items',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.add),
              ),
            ],
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(l10n.noResultsFound))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.isActive
                                ? null
                                : Theme.of(context).colorScheme.outline,
                            decoration: item.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: l10n.edit,
                              onPressed: () => onRename(item),
                            ),
                            Switch.adaptive(
                              value: item.isActive,
                              onChanged: (val) => onToggleActive(item, val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
