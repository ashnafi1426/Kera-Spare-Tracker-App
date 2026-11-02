import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../providers/reports_providers.dart';

/// Modal bottom sheet for inventory valuation, stock health, and category distribution.
///
/// Follows Google Stitch Screen 4 (Inventory Reports — የመጋዘን ክምችት ሪፖርት).
class InventoryReportsSheet extends ConsumerWidget {
  const InventoryReportsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InventoryReportsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final valuationAsync = ref.watch(inventoryValuationProvider);
    final partsAsync = ref.watch(partsStreamProvider);

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
                          const Icon(Icons.inventory_2_rounded,
                              size: 20, color: KeraColors.primaryNavy),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'የመጋዘን ክምችት ሪፖርት / Inventory Health',
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Stock Capital, Health Status & Reorder Alerts',
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
                // 1. Valuation & Capital Locked Cards
                partsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(err.toString()),
                  data: (parts) {
                    double totalCostCapital = 0.0;
                    double totalRetailValue = 0.0;
                    double totalUnits = 0.0;
                    int healthyCount = 0;
                    int lowStockCount = 0;
                    int outOfStockCount = 0;

                    for (final p in parts) {
                      final qty = p.cachedQuantity;
                      totalUnits += qty;
                      final cost = p.purchasePrice ?? (p.sellingPrice != null ? p.sellingPrice! * 0.75 : 0.0);
                      totalCostCapital += qty * cost;
                      totalRetailValue += qty * (p.sellingPrice ?? 0.0);

                      if (qty <= 0) {
                        outOfStockCount++;
                      } else if (qty <= (p.lowStockLevel)) {
                        lowStockCount++;
                      } else {
                        healthyCount++;
                      }
                    }

                    final unrealizedProfit = totalRetailValue - totalCostCapital;
                    final marginPct = totalRetailValue > 0
                        ? (unrealizedProfit / totalRetailValue * 100)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Units & SKUs Strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: KeraColors.outlineBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ጠቅላላ ብዛት / Total Units',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${totalUnits.toStringAsFixed(0)} pcs',
                                    style: KeraTypography.titleMedium(
                                      color: KeraColors.primaryNavy,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                height: 32,
                                width: 1,
                                color: KeraColors.outlineBorder,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'የመለዋወጫ አይነቶች / SKUs',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${parts.length} SKUs',
                                    style: KeraTypography.titleMedium(
                                      color: KeraColors.primaryNavy,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Valuation Hero Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: KeraColors.primaryNavyDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'የክምችት ግምት / VALUATION AT RETAIL',
                                style: KeraTypography.labelSmall(
                                  color: Colors.white70,
                                ).copyWith(letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatter.formatEtb(totalRetailValue),
                                  style: KeraTypography.headlineMedium(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.w900),
                                ),
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
                                          'በግዢ ዋጋ (Cost Capital)',
                                          style: KeraTypography.labelSmall(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            CurrencyFormatter.formatEtb(
                                                totalCostCapital),
                                            style: KeraTypography.labelLarge(
                                              color: Colors.white,
                                            ).copyWith(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'የሚጠበቅ ትርፍ (Unrealized)',
                                          style: KeraTypography.labelSmall(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '+${CurrencyFormatter.formatEtb(unrealizedProfit)} (~${marginPct.toStringAsFixed(1)}%)',
                                            style: KeraTypography.labelLarge(
                                              color: KeraColors.tealAccent,
                                            ).copyWith(
                                                fontWeight: FontWeight.bold),
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

                        // Stock Health Breakdown
                        Text(
                          'የክምችት ጤንነት / Stock Health',
                          style: KeraTypography.titleSmall()
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildHealthBadge(
                                color: KeraColors.stockInBg,
                                textColor: KeraColors.stockInText,
                                icon: Icons.check_circle_rounded,
                                label: 'ደህና ክምችት',
                                count: '$healthyCount SKUs',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildHealthBadge(
                                color: KeraColors.stockLowBg,
                                textColor: KeraColors.stockLowText,
                                icon: Icons.warning_amber_rounded,
                                label: 'አነስተኛ (≤5)',
                                count: '$lowStockCount SKUs',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildHealthBadge(
                                color: KeraColors.stockOutBg,
                                textColor: KeraColors.stockOutText,
                                icon: Icons.cancel_rounded,
                                label: 'ያለቀባቸው (0)',
                                count: '$outOfStockCount SKUs',
                              ),
                            ),
                          ],
                        ),

                        if (lowStockCount > 0 || outOfStockCount > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: KeraColors.stockLowBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: KeraColors.warningAmberBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notification_important_rounded,
                                    color: KeraColors.warningAmber),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'አስቸኳይ ትእዛዝ የሚያስፈልጋቸው መለዋወጫዎች',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.warningAmber,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '$lowStockCount አነስተኛ እና $outOfStockCount ያለቀባቸው ክፍሎች አሉ',
                                        style: KeraTypography.bodySmall(
                                          color: Colors.brown.shade800,
                                        ).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push('/stock/low-stock');
                                  },
                                  child: Text(
                                    'እይ →',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.primaryNavy,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildHealthBadge({
    required Color color,
    required Color textColor,
    required IconData icon,
    required String label,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: KeraTypography.labelSmall(color: textColor).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            count,
            style: KeraTypography.labelLarge(color: textColor).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
