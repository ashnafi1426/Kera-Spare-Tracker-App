import 'package:flutter/material.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/dashboard_providers.dart';



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
    final currencyUnit = context.tr('ብር', 'ETB');
    final pcsUnit = context.tr('ፍሬ', 'pcs');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('የንግድ ማጠቃለያ', 'Business Overview'),
                style: KeraTypography.titleMedium().copyWith(
                  color: context.textPrimaryColor,
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
                  context.tr('የቀጥታ መረጃ', 'Live Data'),
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
              title: context.tr('የመለዋወጫ ዓይነቶች', 'Active SKUs'),
              subtitle: context.tr('የተመዘገቡ ዕቃዎች', 'Catalog Parts'),
              value: _formatNumber(metrics.totalSkus),
              icon: Icons.inventory_2_outlined,
              iconColor: KeraColors.actionBlue,
              iconBgColor: KeraColors.actionBlue.withValues(alpha: 0.12),
              onTap: onInventoryTap,
            ),

            // Stat 2: Total Quantity
            _MetricCard(
              title: context.tr('ጠቅላላ ክምችት', 'Total Inventory'),
              subtitle: context.tr('በመጋዘን ውስጥ ያለው', 'Units in Stock'),
              value: _formatNumber(metrics.totalQuantity),
              unit: pcsUnit,
              icon: Icons.layers_outlined,
              iconColor: KeraColors.primaryNavy,
              iconBgColor: KeraColors.borderNeutral,
              onTap: onInventoryTap,
            ),

            // Stat 3: Today's Revenue
            _MetricCard(
              title: context.tr('የዛሬ ገቢ', "Today's Revenue"),
              subtitle: context.tr('የቀኑ ሽያጭ', 'Gross Sales'),
              value: _formatCurrency(metrics.todayRevenue),
              unit: currencyUnit,
              icon: Icons.payments_outlined,
              iconColor: KeraColors.tealDark,
              iconBgColor: KeraColors.tealFixed.withValues(alpha: 0.6),
            ),

            // Stat 4: Estimated Profit
            _MetricCard(
              title: context.tr('የተጣራ ትርፍ', 'Estimated Profit'),
              subtitle: context.tr('ህዳግ ~${metrics.profitMargin.toStringAsFixed(0)}%', 'Margin ~${metrics.profitMargin.toStringAsFixed(0)}%'),
              value: _formatCurrency(metrics.todayProfit),
              unit: currencyUnit,
              trend: metrics.profitMargin > 0 ? '+${metrics.profitMargin.toStringAsFixed(0)}%' : null,
              icon: Icons.trending_up_rounded,
              iconColor: KeraColors.actionBlue,
              iconBgColor: KeraColors.borderNeutral,
            ),

            // Stat 5: Low-Stock Alerts
            _MetricCard(
              title: context.tr('አነስተኛ ክምችት', 'Low Stock Alert'),
              subtitle: metrics.lowStockCount > 0
                  ? context.tr('ማዘዝ ያስፈልጋል', 'Reorder Required')
                  : context.tr('ክምችት በቂ ነው', 'Healthy Stock'),
              value: metrics.lowStockCount.toString(),
              unit: pcsUnit,
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
              title: context.tr('ያለቁ ዕቃዎች', 'Out of Stock'),
              subtitle: metrics.outOfStockCount > 0
                  ? context.tr('ያለቁ (0 ፍሬ)', '0 pcs available')
                  : context.tr('ሁሉም ይገኛሉ', 'All in Stock'),
              value: metrics.outOfStockCount.toString(),
              unit: pcsUnit,
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
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(KeraRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        child: Container(
          padding: const EdgeInsets.all(KeraSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: context.isDark ? Colors.black26 : const Color(0x06000000),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Icon + Trend or Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KeraColors.tealFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(KeraRadii.xs),
                      ),
                      child: Text(
                        trend!,
                        style: KeraTypography.labelSmall().copyWith(
                          fontSize: 9,
                          color: KeraColors.tealDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Value row
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: KeraTypography.headlineMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? context.textPrimaryColor,
                        fontSize: 22,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: KeraTypography.labelSmall().copyWith(
                          color: context.textSecondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Title and Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KeraTypography.labelSmall().copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: KeraTypography.labelSmall().copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
