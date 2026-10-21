import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../parts/domain/models/category_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';

/// Management screen for spare part categories.
/// Allows owners to add, edit, and deactivate their custom categories.
class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends ConsumerState<CategoriesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditDialog({CategoryItem? existing}) async {
    final l10n = context.l10n;
    final isEditing = existing != null;
    final controller = TextEditingController(text: existing?.name ?? '');
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? l10n.editCategory : l10n.addCategory),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.categoryName,
                      hintText: l10n.categoryNameHint,
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => errorText = l10n.fieldRequired);
                      return;
                    }
                    Navigator.pop(ctx, name);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(categoriesRepositoryProvider);

    if (isEditing) {
      final updateResult = await repo.updateCategory(
        ownerId: ownerId,
        id: existing.id,
        name: result,
      );
      if (!mounted) return;
      if (updateResult.isFailure) {
        context.showSnackBar(
          updateResult.failureOrNull?.message ==
                  'An item with this name already exists'
              ? l10n.duplicateNameError
              : (updateResult.failureOrNull?.message ?? 'Error'),
          isError: true,
        );
      }
    } else {
      final createResult = await repo.createCategory(
        ownerId: ownerId,
        name: result,
      );
      if (!mounted) return;
      if (createResult.isFailure) {
        context.showSnackBar(
          createResult.failureOrNull?.message ==
                  'An item with this name already exists'
              ? l10n.duplicateNameError
              : (createResult.failureOrNull?.message ?? 'Error'),
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmDeactivate(CategoryItem category) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateConfirmTitle),
        content: Text(l10n.deactivateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivate),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ownerId = ref.read(currentOwnerIdProvider);
      final repo = ref.read(categoriesRepositoryProvider);
      final res =
          await repo.deactivateCategory(ownerId: ownerId, id: category.id);
      if (!mounted) return;
      if (res.isFailure) {
        context.showSnackBar(
          res.failureOrNull?.message ?? 'Error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addCategory),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchCategories,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (categories) {
                final filtered = _searchQuery.isEmpty
                    ? categories
                    : categories
                        .where((c) =>
                            c.name.toLowerCase().contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 56,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noCategoriesFound,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l10n.edit,
                              onPressed: () =>
                                  _showAddEditDialog(existing: category),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: colorScheme.error,
                              ),
                              tooltip: l10n.deactivate,
                              onPressed: () => _confirmDeactivate(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
