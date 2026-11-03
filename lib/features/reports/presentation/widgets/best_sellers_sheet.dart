import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/reports_providers.dart';

/// Modal bottom sheet displaying ranked best-selling products leaderboard.
///
/// Follows Google Stitch Screen 5 (Best-Selling Products — ከፍተኛ ተፈላጊ ዕቃዎች).
class BestSellersSheet extends ConsumerStatefulWidget {
  const BestSellersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BestSellersSheet(),
    );
  }

  @override
  ConsumerState<BestSellersSheet> createState() => _BestSellersSheetState();
}

class _BestSellersSheetState extends ConsumerState<BestSellersSheet> {
  int _sortType = 0; // 0: By Units Sold, 1: By Revenue

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                          const Icon(Icons.leaderboard_rounded,
                              size: 20, color: KeraColors.actionBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('ከፍተኛ ተፈላጊ ዕቃዎች', 'Best Sellers'),
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
                          'የሽያጭ ፍጥነት እና ደረጃ ዝርዝር',
                          'Sales Velocity & Turnover Ranking',
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
            child: topPartsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (parts) {
                if (parts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              size: 48, color: KeraColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('በዚህ የጊዜ ገደብ የተሸጡ ዕቃዎች የሉም', 'No items sold in this period'),
                            style: KeraTypography.bodyLarge(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort based on toggle
                final sorted = List.of(parts);
                if (_sortType == 0) {
                  sorted.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
                } else {
                  sorted.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
                }

                final topPart = sorted.first;
                final runnerUps = sorted.skip(1).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sort Chips
                    Row(
                      children: [
                        Text(
                          context.tr('ደረጃ ማውጫ:', 'Rank by:'),
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selected: _sortType == 0,
                          label: Text(context.tr('በብዛት', 'By Units')),
                          labelStyle: KeraTypography.labelSmall(
                            color: _sortType == 0
                                ? Colors.white
                                : KeraColors.textPrimary,
                          ),
                          selectedColor: KeraColors.actionBlue,
                          onSelected: (val) => setState(() => _sortType = 0),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          selected: _sortType == 1,
                          label: Text(context.tr('በገቢ', 'By Revenue')),
                          labelStyle: KeraTypography.labelSmall(
                            color: _sortType == 1
                                ? Colors.white
                                : KeraColors.textPrimary,
                          ),
                          selectedColor: KeraColors.actionBlue,
                          onSelected: (val) => setState(() => _sortType = 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // #1 Trophy Hero Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            KeraColors.primaryNavyDark,
                            KeraColors.primaryNavyLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: KeraColors.primaryNavy.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded,
                                        size: 16, color: Colors.black87),
                                    const SizedBox(width: 4),
                                    Text(
                                      '#1 ${context.tr("ቀዳሚ ተፈላጊ", "TOP SELLER")}',
                                      style: KeraTypography.labelSmall(
                                        color: Colors.black87,
                                      ).copyWith(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr('ከፍተኛ ተፈላጊ', 'Top Velocity'),
                                  style: KeraTypography.labelSmall(
                                    color: Colors.white,
                                  ).copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            topPart.partName,
                            style: KeraTypography.titleMedium(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('የተሸጠ ብዛት', 'Units Sold'),
                                      style: KeraTypography.labelSmall(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.formatQuantity(topPart.quantitySold)} ${context.tr("ፍሬ", "pcs")}',
                                      style: KeraTypography.titleMedium(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('ጠቅላላ ገቢ', 'Total Revenue'),
                                      style: KeraTypography.labelSmall(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        CurrencyFormatter.formatEtb(
                                            topPart.totalRevenue),
                                        style: KeraTypography.titleMedium(
                                          color: KeraColors.tealAccent,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Ranks #2 through #10
                    if (runnerUps.isNotEmpty) ...[
                      Text(
                        context.tr(
                          'ተከታይ ተፈላጊ ክፍሎች (#2 - #${sorted.length})',
                          'Runner-up Parts (#2 - #${sorted.length})',
                        ),
                        style: KeraTypography.titleSmall()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...runnerUps.asMap().entries.map((entry) {
                        final rank = entry.key + 2;
                        final part = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.cardCanvasColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    context.isDark ? const Color(0xFF1E3A5F) : KeraColors.surfaceContainerHighest,
                                child: Text(
                                  '#$rank',
                                  style: KeraTypography.labelSmall(
                                    color: context.textPrimaryColor,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      part.partName,
                                      style: KeraTypography.labelMedium(
                                        color: context.textPrimaryColor,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.formatQuantity(part.quantitySold)} ${context.tr("ተሽጧል", "units sold")}',
                                      style: KeraTypography.bodySmall(
                                        color: context.textSecondaryColor,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatEtb(part.totalRevenue),
                                style: KeraTypography.labelMedium(
                                  color: context.isDark ? KeraColors.tealAccent : KeraColors.primaryNavy,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 14),

                    // Merchant Insight Tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: KeraColors.actionBlue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded,
                              color: KeraColors.actionBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('የንግድ ግንዛቤ', 'Merchant Insight'),
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.actionBlue,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr(
                                    'ከፍተኛ ተፈላጊ ዕቃዎች ክምችት እንዳያልቅ ቀድመው ከጅምላ አቅራቢዎች ጋር ይዘዙ።',
                                    'Order high-velocity items early from suppliers to prevent stockouts.',
                                  ),
                                  style: KeraTypography.bodySmall(
                                    color: KeraColors.textPrimary,
                                  ).copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
