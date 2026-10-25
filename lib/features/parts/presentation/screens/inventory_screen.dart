import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/inventory_filter.dart';
import '../../domain/models/part_item.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_filter_sheet.dart';

/// Main Inventory catalog screen with instant debounced DB search,
/// lazy pagination for 5,000+ parts, multi-criteria filters, and test seeder.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final filter = ref.watch(inventoryFilterProvider);
    final state = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.inventoryTab),
          ],
        ),
        actions: [
          // Filter button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: l10n.filter,
                onPressed: () => InventoryFilterSheet.show(context),
              ),
              if (filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          // Debug & Seeder Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
                    Icon(Icons.speed_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.seedParts),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_seed',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.clearTestParts),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_screen_fab',
        onPressed: () => context.push('/parts/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _onClearSearch,
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Quick Stock Status Chips & Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickStockChip(StockFilter.all, l10n.filterAll, filter.stockFilter),
                        const SizedBox(width: 6),
                        _buildQuickStockChip(StockFilter.inStock, l10n.filterInStock, filter.stockFilter),
                        const SizedBox(width: 6),
                        _buildQuickStockChip(StockFilter.lowStock, l10n.filterLowStock, filter.stockFilter),
                        const SizedBox(width: 6),
                        _buildQuickStockChip(StockFilter.outOfStock, l10n.filterOutOfStock, filter.stockFilter),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.totalPartsCount(state.totalCount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),

          // 3. Main Paginated List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(inventoryListProvider.notifier).refresh(),
              child: _buildListContent(context, state, filter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStockChip(
    StockFilter filterValue,
    String label,
    StockFilter activeFilter,
  ) {
    final isSelected = filterValue == activeFilter;
    final colorScheme = context.colorScheme;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        ref.read(inventoryFilterProvider.notifier).setStockFilter(filterValue);
      },
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? colorScheme.onPrimaryContainer : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    InventoryListState state,
    InventoryFilter filter,
  ) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(inventoryListProvider.notifier).refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      final isFiltered = filter.hasActiveFilters ||
          (_searchController.text.trim().isNotEmpty);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered ? l10n.noFilteredPartsTitle : l10n.noPartsFound,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered ? l10n.noFilteredPartsDesc : l10n.noPartsDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (isFiltered)
                OutlinedButton.icon(
                  onPressed: () {
                    _onClearSearch();
                    ref.read(inventoryFilterProvider.notifier).resetFilters();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.resetFilters),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.push('/parts/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.add),
                ),
            ],
          ),
        ),
      );
    }

    // High performance list with pagination indicator
    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

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
        return _PartCard(part: part);
      },
    );
  }
}

/// Performant part card component with photo thumbnail, stock badges, and pricing.
class _PartCard extends StatelessWidget {
  final PartItem part;

  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    final hasPhoto = part.photoLocalPath != null &&
        File(part.photoLocalPath!).existsSync();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 50,
            height: 50,
            color: colorScheme.surfaceContainerHighest,
            child: hasPhoto
                ? Image.file(
                    File(part.photoLocalPath!),
                    fit: BoxFit.cover,
                    cacheWidth: 100,
                  )
                : Icon(
                    Icons.build_circle_outlined,
                    color: colorScheme.primary,
                  ),
          ),
        ),
        title: Text(
          part.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              if (part.partNumber != null && part.partNumber!.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    '#${part.partNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (part.brandName != null && part.brandName!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    part.brandName!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (part.sellingPrice != null)
              Text(
                '${part.sellingPrice!.toStringAsFixed(0)} ብር',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(height: 4),
            _buildStockBadge(context, part, l10n, colorScheme),
          ],
        ),
        onTap: () async {
          final result = await context.push('/parts/${part.id}');
          if (result == true && context.mounted) {
            // Refresh list if part was updated or deleted
            final container = ProviderScope.containerOf(context);
            await container.read(inventoryListProvider.notifier).refresh();
          }
        },
      ),
    );
  }

  Widget _buildStockBadge(
    BuildContext context,
    PartItem part,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    final Color badgeBg;
    final Color badgeText;
    final String label;

    if (part.isOutOfStock) {
      badgeBg = colorScheme.error.withValues(alpha: 0.15);
      badgeText = colorScheme.error;
      label = l10n.outOfStock;
    } else if (part.isLowStock) {
      badgeBg = Colors.orange.withValues(alpha: 0.18);
      badgeText = Colors.orange.shade900;
      label = '${l10n.lowStock}: ${part.cachedQuantity.toStringAsFixed(0)}';
    } else {
      badgeBg = Colors.green.withValues(alpha: 0.15);
      badgeText = Colors.green.shade800;
      label = '${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}'.trim();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badgeText,
        ),
      ),
    );
  }
}
