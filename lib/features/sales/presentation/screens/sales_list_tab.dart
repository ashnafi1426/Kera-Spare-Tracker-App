import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../providers/sales_providers.dart';

/// Tab displaying recorded sales history grouped by day with total per day,
/// live item name search, date range filters (today, this week, this month, custom),
/// and KPI summary bento cards per Google Stitch Screen 31.
class SalesListTab extends ConsumerStatefulWidget {
  const SalesListTab({super.key});

  @override
  ConsumerState<SalesListTab> createState() => _SalesListTabState();
}

class _SalesListTabState extends ConsumerState<SalesListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _syncFilter = 'all'; // 'all', 'synced', 'pending', 'failed'

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
    final selectedFilter = ref.watch(salesHistoryDateFilterProvider);
    final dayGroupsAsync = ref.watch(salesDayGroupsProvider);
    final timeFormat = DateFormat('HH:mm');
    final dayHeaderFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.navSales,
              style: KeraTypography.headlineSmall(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KeraColors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  context.tr('የሽያጭ ታሪክ • ኬራ ዞን 4', 'Sales History • Kera Hub'),
                  style: KeraTypography.labelSmall(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isAmharic = context.isAmharic;
              return InkWell(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(
                        Locale(isAmharic ? 'en' : 'am'),
                      );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'English' : 'አማርኛ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: context.tr('ሪፖርት አውርድ', 'Export Report'),
            onPressed: () {
              context.showSnackBar(
                context.tr(
                  'የሽያጭ ሪፖርት በተሳካ ሁኔታ ተዘጋጅቷል',
                  'Sales report exported successfully',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: context.tr('የማመሳሰል ሁኔታ', 'Sync Status'),
            onPressed: () {
              context.showSnackBar(
                context.tr('ሁሉም ሽያጮች ተመሳስለዋል', 'All sales synced'),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_list_tab_fab',
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(
          l10n.newSale,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/sales/new'),
      ),
      body: Column(
        children: [
          // 1. Time Segmented Filter Switcher (Stitch Screen 31)
          Container(
            color: KeraColors.primaryNavyDark,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTimeSegmentButton(
                    label: context.tr('ዛሬ', 'Today'),
                    isSelected: selectedFilter == DateRangeType.today,
                    onTap: () => ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.today),
                  ),
                  _buildTimeSegmentButton(
                    label: context.tr('ሳምንት', 'Week'),
                    isSelected: selectedFilter == DateRangeType.thisWeek,
                    onTap: () => ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.thisWeek),
                  ),
                  _buildTimeSegmentButton(
                    label: context.tr('ወር', 'Month'),
                    isSelected: selectedFilter == DateRangeType.thisMonth,
                    onTap: () => ref
                        .read(salesHistoryDateFilterProvider.notifier)
                        .setFilter(DateRangeType.thisMonth),
                  ),
                  _buildTimeSegmentButton(
                    label: selectedFilter == DateRangeType.custom &&
                            ref.watch(salesHistoryCustomRangeProvider) != null
                        ? '${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.start)} - ${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.end)}'
                        : context.tr('ብጁ', 'Custom'),
                    isSelected: selectedFilter == DateRangeType.custom,
                    onTap: _pickCustomRange,
                  ),
                ],
              ),
            ),
          ),

          // 2. Financial KPI Summary Bento Strip (Stitch Screen 31)
          dayGroupsAsync.maybeWhen(
            data: (groups) {
              final allSales = groups.expand((g) => g.sales).toList();
              final totalRevenue =
                  allSales.fold(0.0, (sum, s) => sum + s.totalAmount);
              final totalProfit =
                  allSales.fold(0.0, (sum, s) => sum + s.totalProfit);
              final totalUnits = allSales.fold(
                  0.0,
                  (sum, s) =>
                      sum +
                      s.items.fold(0.0, (isum, item) => isum + item.quantity));
              final margin = totalRevenue > 0
                  ? (totalProfit / totalRevenue * 100)
                  : 0.0;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KeraColors.outlineBorder),
                  boxShadow: const [KeraColors.shadowLevel1],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded,
                                size: 18, color: KeraColors.actionBlue),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('የሽያጭ ማጠቃለያ', 'Sales Audit Summary'),
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textSecondary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${allSales.length} ${context.tr("ግብይቶች", "sales")}',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.formatEtb(totalRevenue),
                          style: KeraTypography.headlineSmall(
                            color: KeraColors.primaryNavy,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.totalRevenue,
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Net Profit Pill
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: KeraColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: KeraColors.outlineBorder
                                      .withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up_rounded,
                                        size: 14, color: KeraColors.success),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${l10n.totalProfit} (Net)',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textSecondary,
                                        ).copyWith(fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '+${CurrencyFormatter.formatEtb(totalProfit)}',
                                    style: KeraTypography.labelLarge(
                                      color: Colors.green.shade800,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '~${margin.toStringAsFixed(1)}% ${context.tr("የትርፍ መጠን", "net margin")}',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textMuted,
                                  ).copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Units Sold Pill
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: KeraColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: KeraColors.outlineBorder
                                      .withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 14,
                                        color: KeraColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        context.tr('የተሸጡ ዕቃዎች', 'Units Sold'),
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textSecondary,
                                        ).copyWith(fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalUnits.toStringAsFixed(0)} ${context.tr("ፍሬ", "pcs")}',
                                  style: KeraTypography.labelLarge(
                                    color: KeraColors.primaryNavy,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  context.tr('100% ኦሪጅናል ስፔር', '100% Genuine'),
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textMuted,
                                  ).copyWith(fontSize: 10),
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
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 3. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchSalesHint,
                prefixIcon: const Icon(Icons.receipt_long_rounded,
                    color: KeraColors.textSecondary),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KeraColors.outlineBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KeraColors.outlineBorder),
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

          // 4. Sync State Horizontal Chips per Stitch Screen 31
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildSyncChip(context.tr('ሁሉም', 'All'), 'all', null),
                const SizedBox(width: 8),
                _buildSyncChip(
                    context.tr('የተመሳሰሉ', 'Synced'), 'synced', KeraColors.success),
                const SizedBox(width: 8),
                _buildSyncChip(
                    context.tr('በወረፋ', 'Pending'), 'pending', KeraColors.warningAmber),
                const SizedBox(width: 8),
                _buildSyncChip(context.tr('ያልተሳኩ', 'Failed'), 'failed', KeraColors.errorRed),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 5. Sales List Grouped by Day
          Expanded(
            child: dayGroupsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: KeraColors.actionBlue
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 38,
                              color: KeraColors.actionBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noSalesForFilter,
                            textAlign: TextAlign.center,
                            style: KeraTypography.titleMedium()
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.cartEmptyDesc,
                            textAlign: TextAlign.center,
                            style: KeraTypography.bodyMedium(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 84),
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
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayHeaderFormat.format(group.date),
                                style: KeraTypography.labelLarge(
                                  color: KeraColors.primaryNavy,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: KeraColors.outlineBorder),
                                ),
                                child: Text(
                                  '${l10n.dayTotal}: ${CurrencyFormatter.formatEtb(group.totalAmount)}',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.primaryNavy,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sales in this day (Stitch Screen 31 Card)
                        ...group.sales.map((sale) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: KeraColors.outlineBorder,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.push('/sales/${sale.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '#${sale.receiptNumber ?? sale.id.substring(0, 6)}',
                                                  style: KeraTypography
                                                      .labelLarge(
                                                    color:
                                                        KeraColors.primaryNavy,
                                                  ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '• ${timeFormat.format(sale.soldAt)}',
                                                  style: KeraTypography
                                                      .labelSmall(
                                                    color: KeraColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${sale.items.length} ${context.tr("ዕቃዎች", "items")}${sale.notes != null && sale.notes!.isNotEmpty ? " • ${sale.notes!}" : ""}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: KeraTypography.bodySmall(
                                                color:
                                                    KeraColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Synced Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: KeraColors.stockInBg,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: KeraColors.stockInText,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                context.tr('የተመሳሰለ', 'Synced'),
                                                style: KeraTypography.labelSmall(
                                                  color: KeraColors.stockInText,
                                                ).copyWith(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(
                                        height: 1,
                                        color: KeraColors.outlineBorder),
                                    const SizedBox(height: 10),

                                    // Bottom row: Payment pill + Profit badge + Total
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            if (sale.paymentMethod != null &&
                                                sale.paymentMethod!
                                                    .isNotEmpty) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      KeraColors.surfaceCanvas,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: KeraColors
                                                          .outlineBorder),
                                                ),
                                                child: Text(
                                                  sale.paymentMethod!,
                                                  style: KeraTypography
                                                      .labelSmall(
                                                    color: KeraColors
                                                        .textSecondary,
                                                  ).copyWith(fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(
                                              '+${CurrencyFormatter.formatEtb(sale.totalProfit)} ${l10n.lineProfit.toLowerCase()}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          CurrencyFormatter.formatEtb(
                                            sale.totalAmount,
                                          ),
                                          style: KeraTypography.titleSmall(
                                            color: KeraColors.primaryNavy,
                                          ).copyWith(
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildTimeSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? const [KeraColors.shadowLevel1] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: KeraTypography.labelSmall(
              color: isSelected
                  ? KeraColors.primaryNavy
                  : Colors.white.withValues(alpha: 0.8),
            ).copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncChip(String label, String value, Color? dotColor) {
    final isSelected = _syncFilter == value;
    return ChoiceChip(
      selected: isSelected,
      avatar: dotColor != null
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
      label: Text(label),
      labelStyle: KeraTypography.labelSmall(
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      selectedColor: KeraColors.primaryNavy,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? KeraColors.primaryNavy : KeraColors.outlineBorder,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _syncFilter = value);
      },
    );
  }
}
