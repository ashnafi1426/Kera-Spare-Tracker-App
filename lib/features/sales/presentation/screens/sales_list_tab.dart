import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../providers/sales_providers.dart';

/// Tab displaying recorded sales history grouped by day with total per day,
/// live item name search, and date range filters (today, this week, this month, custom).
class SalesListTab extends ConsumerStatefulWidget {
  const SalesListTab({super.key});

  @override
  ConsumerState<SalesListTab> createState() => _SalesListTabState();
}

class _SalesListTabState extends ConsumerState<SalesListTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final currentCustom = ref.read(salesHistoryCustomRangeProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentCustom ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: context.l10n.selectDateRange,
    );

    if (picked != null) {
      ref.read(salesHistoryCustomRangeProvider.notifier).setRange(picked);
      ref.read(salesHistoryDateFilterProvider.notifier).setFilter(
            DateRangeType.custom,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final selectedFilter = ref.watch(salesHistoryDateFilterProvider);
    final dayGroupsAsync = ref.watch(salesDayGroupsProvider);
    final timeFormat = DateFormat('HH:mm');
    final dayHeaderFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSales),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_list_tab_fab',
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(l10n.newSale),
        onPressed: () => context.push('/sales/new'),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchSalesHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(salesHistorySearchQueryProvider.notifier)
                              .setQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref
                    .read(salesHistorySearchQueryProvider.notifier)
                    .setQuery(val);
                setState(() {});
              },
            ),
          ),

          // 2. Date Range Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.filterToday,
                  isSelected: selectedFilter == DateRangeType.today,
                  onSelected: () {
                    ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.today);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.filterThisWeek,
                  isSelected: selectedFilter == DateRangeType.thisWeek,
                  onSelected: () {
                    ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.thisWeek);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.filterThisMonth,
                  isSelected: selectedFilter == DateRangeType.thisMonth,
                  onSelected: () {
                    ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.thisMonth);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: selectedFilter == DateRangeType.custom &&
                          ref.watch(salesHistoryCustomRangeProvider) != null
                      ? '${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.start)} - ${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.end)}'
                      : l10n.filterCustom,
                  isSelected: selectedFilter == DateRangeType.custom,
                  icon: Icons.date_range_rounded,
                  onSelected: _pickCustomRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 3. Sales List Grouped by Day
          Expanded(
            child: dayGroupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 36,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noSalesForFilter,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.cartEmptyDesc,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 84),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groups[groupIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Header with Date & Day Total
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayHeaderFormat.format(group.date),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${l10n.dayTotal}: ${CurrencyFormatter.formatEtb(group.totalAmount)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sales in this day
                        ...group.sales.map((sale) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.receipt_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                '#${sale.receiptNumber ?? sale.id.substring(0, 6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeFormat.format(sale.soldAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (sale.notes != null &&
                                      sale.notes!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sale.notes!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatEtb(
                                      sale.totalAmount,
                                    ),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '+${CurrencyFormatter.formatEtb(sale.totalProfit)} ${l10n.lineProfit.toLowerCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/sales/${sale.id}'),
                            ),
                          );
                        }),
                      ],
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
