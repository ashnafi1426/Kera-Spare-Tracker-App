import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
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
                    'ተፈላጊ መለዋወጫዎች / Best Sellers',
                    style: KeraTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: KeraColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Top-moving parts by sales volume',
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
                  foregroundColor: KeraColors.actionBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'ሁሉንም እይ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: KeraSpacing.sm),

        // List of items
        ListView.separated(
          itemCount: top3.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, _) => const SizedBox(height: KeraSpacing.sm),
          itemBuilder: (context, index) {
            final part = top3[index];
            final rank = index + 1;

            return InkWell(
              onTap: onItemTap != null ? () => onItemTap!(part) : null,
              borderRadius: BorderRadius.circular(KeraRadii.md),
              child: Container(
                padding: const EdgeInsets.all(KeraSpacing.sm),
                decoration: BoxDecoration(
                  color: KeraColors.surfaceCard,
                  borderRadius: BorderRadius.circular(KeraRadii.md),
                  border: Border.all(color: KeraColors.borderVariant),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? KeraColors.actionBlue.withValues(alpha: 0.15)
                            : KeraColors.borderNeutral,
                        borderRadius: BorderRadius.circular(KeraRadii.xs),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: rank == 1
                              ? KeraColors.actionBlue
                              : KeraColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: KeraSpacing.md),

                    // Part details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part.partName,
                            style: KeraTypography.bodySmall().copyWith(
                              fontWeight: FontWeight.bold,
                              color: KeraColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${part.quantitySold.toInt()} ተሽጧል • sold',
                            style: KeraTypography.labelSmall().copyWith(
                              color: KeraColors.actionBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              part.totalRevenue.toStringAsFixed(0),
                              style: KeraTypography.titleMedium().copyWith(
                                fontWeight: FontWeight.bold,
                                color: KeraColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'ብር',
                              style: TextStyle(
                                fontSize: 10,
                                color: KeraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5), // emerald-50
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'በክምችት አለ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
