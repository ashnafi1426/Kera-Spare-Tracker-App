import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../providers/dashboard_providers.dart';

/// 2x3 statistics bento grid matching Stitch Screen 7.
///
/// High-density overview of SKUs, stock levels, daily revenue, and inventory warnings.
class DashboardMetricsGrid extends StatelessWidget {
  final BusinessDashboardMetrics metrics;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onOutOfStockTap;
  final VoidCallback? onInventoryTap;

  const DashboardMetricsGrid({
    super.key,
    required this.metrics,
    this.onLowStockTap,
    this.onOutOfStockTap,
    this.onInventoryTap,
  });

  String _formatNumber(num val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val is double && val % 1 != 0 ? val.toStringAsFixed(1) : val.toString();
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(2)}M';
    } else if (val >= 10000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'የንግድ ማጠቃለያ / Overview',
                style: KeraTypography.titleMedium().copyWith(
                  color: KeraColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: KeraSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KeraColors.actionBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'የቀጥታ መረጃ (Live)',
                  style: KeraTypography.labelSmall().copyWith(
                    color: KeraColors.actionBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: KeraSpacing.sm),

        // 2x3 Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: KeraSpacing.sm,
          mainAxisSpacing: KeraSpacing.sm,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Stat 1: Active SKUs
            _MetricCard(
              title: 'መለዋወጫ ዓይነቶች',
              subtitle: 'Active SKUs',
              value: _formatNumber(metrics.totalSkus),
              icon: Icons.inventory_2_outlined,
              iconColor: KeraColors.actionBlue,
              iconBgColor: KeraColors.actionBlue.withValues(alpha: 0.12),
              onTap: onInventoryTap,
            ),

            // Stat 2: Total Quantity
            _MetricCard(
              title: 'ጠቅላላ ክምችት',
              subtitle: 'Total Quantity (pcs)',
              value: _formatNumber(metrics.totalQuantity),
              icon: Icons.layers_outlined,
              iconColor: KeraColors.primaryNavy,
              iconBgColor: KeraColors.borderNeutral,
              onTap: onInventoryTap,
            ),

            // Stat 3: Today's Revenue
            _MetricCard(
              title: 'የዛሬ ገቢ',
              subtitle: 'Today Revenue',
              value: _formatCurrency(metrics.todayRevenue),
              unit: 'ብር',
              trend: 'የቀኑ ሽያጭ',
              icon: Icons.payments_outlined,
              iconColor: KeraColors.tealDark,
              iconBgColor: KeraColors.tealFixed.withValues(alpha: 0.6),
            ),

            // Stat 4: Estimated Profit
            _MetricCard(
              title: 'የተጣራ ትርፍ',
              subtitle: 'Margin ~${metrics.profitMargin.toStringAsFixed(0)}%',
              value: _formatCurrency(metrics.todayProfit),
              unit: 'ብር',
              icon: Icons.trending_up_rounded,
              iconColor: KeraColors.actionBlue,
              iconBgColor: KeraColors.borderNeutral,
            ),

            // Stat 5: Low-Stock Alerts
            _MetricCard(
              title: 'አነስተኛ ክምችት',
              subtitle: metrics.lowStockCount > 0 ? 'Reorder required' : 'Stock healthy',
              value: metrics.lowStockCount.toString(),
              unit: 'ዕቃዎች',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFB45309),
              iconBgColor: const Color(0xFFFEF3C7),
              valueColor: metrics.lowStockCount > 0
                  ? const Color(0xFFB45309)
                  : KeraColors.textSecondary,
              onTap: onLowStockTap,
            ),

            // Stat 6: Out-of-Stock
            _MetricCard(
              title: 'ያለቁ ዕቃዎች',
              subtitle: metrics.outOfStockCount > 0 ? 'Out of stock (0 pcs)' : 'All in stock',
              value: metrics.outOfStockCount.toString(),
              unit: 'ዕቃዎች',
              icon: Icons.error_outline_rounded,
              iconColor: KeraColors.errorRed,
              iconBgColor: KeraColors.errorRed.withValues(alpha: 0.12),
              valueColor: metrics.outOfStockCount > 0
                  ? KeraColors.errorRed
                  : KeraColors.textSecondary,
              onTap: onOutOfStockTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String? unit;
  final String? trend;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.value,
    this.unit,
    this.trend,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: const EdgeInsets.all(KeraSpacing.sm),
      decoration: BoxDecoration(
        color: KeraColors.surfaceCard,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(color: KeraColors.borderVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: KeraTypography.labelSmall().copyWith(
                    color: KeraColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(KeraRadii.xs),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: KeraTypography.numericStat().copyWith(
                      color: valueColor ?? KeraColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit!,
                      style: KeraTypography.labelSmall().copyWith(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: KeraTypography.labelSmall().copyWith(
                  color: valueColor ?? KeraColors.textSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
