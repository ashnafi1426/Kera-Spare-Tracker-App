import 'package:flutter/material.dart';

import '../../features/parts/domain/models/picker_item.dart';
import '../utils/context_extensions.dart';

/// Reusable bottom sheet picker with search and quick "Add New" capability.
class AppPickerBottomSheet extends StatefulWidget {
  final String title;
  final List<PickerItem> items;
  final String? selectedId;
  final String? searchHint;
  final Future<PickerItem?> Function()? onQuickAdd;

  const AppPickerBottomSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedId,
    this.searchHint,
    this.onQuickAdd,
  });

  /// Static helper to display the picker bottom sheet with smooth animation.
  static Future<PickerItem?> show({
    required BuildContext context,
    required String title,
    required List<PickerItem> items,
    String? selectedId,
    String? searchHint,
    Future<PickerItem?> Function()? onQuickAdd,
  }) {
    return showModalBottomSheet<PickerItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppPickerBottomSheet(
        title: title,
        items: items,
        selectedId: selectedId,
        searchHint: searchHint,
        onQuickAdd: onQuickAdd,
      ),
    );
  }

  @override
  State<AppPickerBottomSheet> createState() => _AppPickerBottomSheetState();
}

class _AppPickerBottomSheetState extends State<AppPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<PickerItem> _filteredItems;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant AppPickerBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _handleQuickAdd() async {
    if (widget.onQuickAdd == null || _isAdding) return;

    setState(() => _isAdding = true);
    try {
      final newItem = await widget.onQuickAdd!();
      if (newItem != null && mounted) {
        Navigator.pop(context, newItem);
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Title & Quick Add / Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onQuickAdd != null) ...[
                  TextButton.icon(
                    onPressed: _isAdding ? null : _handleQuickAdd,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.quickAddNew),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? l10n.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Items List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noDataTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.noDataDesc,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (widget.onQuickAdd != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isAdding ? null : _handleQuickAdd,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.quickAddNew),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.selectedId == item.id;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : null,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (item.isDefault) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.globalDefaultBadge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        subtitle: item.subtitle != null
                            ? Text(item.subtitle!)
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}
