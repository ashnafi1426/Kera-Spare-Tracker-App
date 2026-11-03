import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../providers/reports_providers.dart';

/// Modal bottom sheet for P&L waterfall breakdown and profit margin analysis.
///
/// Follows Google Stitch Screen 3 (Profit Reports — የትርፍ እና ወጪ ሪፖርት).
class ProfitReportsSheet extends ConsumerWidget {
  const ProfitReportsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfitReportsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final partsAsync = ref.watch(partsStreamProvider);
    final topPartsAsync = ref.watch(topSellingPartsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KeraColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_rounded,
                              size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('ትርፍ እና ወጪ ሪፖርት', 'Profit & Margins'),
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        context.tr(
                          'የትርፍ ህዳግ፣ የቀጥታ ዕቃዎች ወጪ እና ትርፍ ትንተና',
                          'P&L Waterfall, Direct COGS & Net Margins',
                        ),
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Waterfall P&L Breakdown Card
                summaryAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(err.toString()),
                  data: (summary) {
                    final revenue = summary.totalRevenue;
                    final profit = summary.totalProfit;
                    final cogs = (revenue - profit).clamp(0.0, double.infinity);
                    final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;
                    final cogsPct = revenue > 0 ? (cogs / revenue * 100) : 0.0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KeraColors.outlineBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('የፋይናንስ ማጠቃለያ', 'Waterfall Summary'),
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textSecondary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Step 1: Gross Revenue
                          _buildWaterfallRow(
                            stepNumber: '1',
                            title: context.tr('ጠቅላላ የሽያጭ ገቢ', 'Gross Revenue'),
                            subtitle:
                                '${summary.salesCount} ${context.tr("የሽያጭ ደረሰኞች", "sales receipts")} • 100%',
                            amount: CurrencyFormatter.formatEtb(revenue),
                            amountColor: KeraColors.primaryNavy,
                            isPositive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),

                          // Step 2: COGS
                          _buildWaterfallRow(
                            stepNumber: '2',
                            title: context.tr(
                                'የተሸጡ ዕቃዎች የወጣባቸው ዋጋ (COGS)',
                                'Cost of Goods Sold (COGS)'),
                            subtitle:
                                '${context.tr("የቀጥታ ክምችት ወጪ", "Direct Inventory Cost")} • ${cogsPct.toStringAsFixed(1)}%',
                            amount: '- ${CurrencyFormatter.formatEtb(cogs)}',
                            amountColor: KeraColors.errorRed,
                            isPositive: false,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),

                          // Step 3: Net Profit
                          _buildWaterfallRow(
                            stepNumber: '3',
                            title: context.tr('የተጣራ ትርፍ', 'Gross Profit'),
                            subtitle:
                                '${context.tr("የትርፍ መጠን", "Margin")}: ${margin.toStringAsFixed(1)}% (${context.tr("ግብ", "Target")}: 25%)',
                            amount: '+ ${CurrencyFormatter.formatEtb(profit)}',
                            amountColor: Colors.green.shade800,
                            isPositive: true,
                            isBold: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 2. Missing Cost Price Safeguard Notice (Stitch Screen 3 Requirement)
                partsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (parts) {
                    final missingCostParts = parts
                        .where((p) =>
                            p.purchasePrice == null || p.purchasePrice! <= 0)
                        .toList();

                    if (missingCostParts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KeraColors.warningAmberBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KeraColors.warningAmberBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: KeraColors.warningAmber, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    '${missingCostParts.length} የተመዘገቡ ዕቃዎች የግዢ ዋጋ የላቸውም!',
                                    '${missingCostParts.length} recorded items are missing cost price!',
                                  ),
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.warningAmber,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr(
                                    'ማስታወቂያ፡ ለእነዚህ ዕቃዎች ትክክለኛ ትርፍ አልተሰላም። ትክክለኛ ትርፍ ለማወቅ እባክዎ በዕቃዎች ዝርዝር ላይ የግዢ ዋጋ ያስገቡ።',
                                    'Notice: Accurate profit cannot be computed for these items. Please update their purchase cost in Inventory.',
                                  ),
                                  style: KeraTypography.bodySmall(
                                    color: Colors.brown.shade900,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 3. Top Profit Drivers
                Text(
                  context.tr('ዕቃዎች በትርፍ አስተዋጽኦ', 'Top Profit Drivers'),
                  style: KeraTypography.titleSmall()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                topPartsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(err.toString()),
                  data: (parts) {
                    if (parts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            context.tr('በዚህ የጊዜ ገደብ የተሸጡ ዕቃዎች የሉም',
                                'No items sold in this period'),
                            style: KeraTypography.bodyMedium(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: parts.map((part) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: KeraColors.outlineBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.trending_up_rounded,
                                    size: 20, color: Colors.green.shade800),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      part.partName,
                                      style: KeraTypography.labelMedium()
                                          .copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.formatQuantity(part.quantitySold)} ${context.tr("ፍሬ ተሽጧል", "units sold")}',
                                      style: KeraTypography.bodySmall(
                                        color: KeraColors.textSecondary,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatEtb(part.totalRevenue),
                                style: KeraTypography.labelMedium(
                                  color: KeraColors.primaryNavy,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallRow({
    required String stepNumber,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    required bool isPositive,
    bool isBold = false,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isBold
              ? Colors.green.shade100
              : KeraColors.surfaceContainerHigh,
          child: Text(
            stepNumber,
            style: KeraTypography.labelSmall(
              color: isBold ? Colors.green.shade900 : KeraColors.textPrimary,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KeraTypography.labelMedium().copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: KeraTypography.bodySmall(color: KeraColors.textSecondary)
                    .copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: KeraTypography.labelLarge(color: amountColor).copyWith(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
