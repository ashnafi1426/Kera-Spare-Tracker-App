import 'package:flutter/material.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/domain/models/top_selling_part.dart';

/// Top 3 best-selling parts preview matching Stitch Screen 7.
class DashboardBestSellers extends StatelessWidget {
  final List<TopSellingPart> items;
  final VoidCallback? onViewAll;
  final ValueChanged<TopSellingPart>? onItemTap;

  const DashboardBestSellers({
    super.key,
    required this.items,
    this.onViewAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final top3 = items.take(3).toList();
    final soldUnit = context.tr('ፍሬ ተሽጧል', 'pcs sold');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('ተፈላጊ መለዋወጫዎች', 'Top Selling Parts'),
                    style: KeraTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: KeraColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.tr('በሽያጭ ብዛት ቀዳሚ የሆኑ', 'Highest volume moving parts'),
                    style: KeraTypography.labelSmall().copyWith(
                      color: KeraColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: KeraColors.actionBlue,
                ),
                child: Text(
                  context.tr('ሁሉንም እይ', 'View All'),
                  style: KeraTypography.labelSmall().copyWith(
                    fontWeight: FontWeight.bold,
                    color: KeraColors.actionBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: KeraSpacing.sm),
        Column(
          children: top3.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: KeraSpacing.xs),
              child: Material(
                color: KeraColors.surfaceCard,
                borderRadius: BorderRadius.circular(KeraRadii.md),
                child: InkWell(
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  borderRadius: BorderRadius.circular(KeraRadii.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeraSpacing.md,
                      vertical: KeraSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(KeraRadii.md),
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Row(
                      children: [
                        // Rank Badge (#1, #2, #3)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? const Color(0xFFFEF3C7)
                                : KeraColors.surfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${index + 1}',
                            style: KeraTypography.labelSmall().copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: index == 0
                                  ? const Color(0xFFB45309)
                                  : KeraColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: KeraSpacing.sm),

                        // Part details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.partName,
                                style: KeraTypography.bodyMedium().copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.partNumber.isNotEmpty)
                                Text(
                                  item.partNumber,
                                  style: KeraTypography.labelSmall().copyWith(
                                    color: KeraColors.textSecondary,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Quantity & Revenue
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.quantitySold} $soldUnit',
                              style: KeraTypography.labelSmall().copyWith(
                                fontWeight: FontWeight.bold,
                                color: KeraColors.textPrimary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatEtb(item.totalRevenue),
                              style: KeraTypography.labelSmall().copyWith(
                                color: KeraColors.tealDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
