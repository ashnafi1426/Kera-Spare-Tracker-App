import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../reports/domain/models/chart_point.dart';
import '../../../reports/domain/models/report_period.dart';

/// Sales trend analytics and daily revenue bar chart matching Stitch Screen 7.
class DashboardSalesTrend extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final List<ChartPoint> points;
  final double periodRevenue;
  final double profitMargin;

  const DashboardSalesTrend({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.points,
    required this.periodRevenue,
    required this.profitMargin,
  });

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(2)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final currencyUnit = context.tr('ብር', 'ETB');

    // Determine max value for relative bar heights
    final maxValue = points.isEmpty
        ? 1.0
        : points.map((p) => p.revenue).fold<double>(0.0, math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.surfaceCard,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(color: KeraColors.borderVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with Period Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('የሽያጭ ሂደት', 'Sales Trend'),
                      style: KeraTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: KeraColors.textPrimary,
                      ),
                    ),
                    Text(
                      context.tr('የገቢ እና ትርፍ ሁኔታ', 'Revenue & performance insights'),
                      style: KeraTypography.labelSmall().copyWith(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Period Switcher
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: KeraColors.borderNeutral,
                  borderRadius: BorderRadius.circular(KeraRadii.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodTab(
                      label: context.tr('ዛሬ', 'Today'),
                      isSelected: selectedPeriod == ReportPeriod.daily,
                      onTap: () => onPeriodChanged(ReportPeriod.daily),
                    ),
                    _PeriodTab(
                      label: context.tr('ሳምንት', 'Week'),
                      isSelected: selectedPeriod == ReportPeriod.weekly,
                      onTap: () => onPeriodChanged(ReportPeriod.weekly),
                    ),
                    _PeriodTab(
                      label: context.tr('ወር', 'Month'),
                      isSelected: selectedPeriod == ReportPeriod.monthly,
                      onTap: () => onPeriodChanged(ReportPeriod.monthly),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: KeraSpacing.md),

          // Period revenue summary strip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KeraSpacing.sm,
              vertical: KeraSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: KeraColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(KeraRadii.xs),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${context.tr("ጠቅላላ ገቢ", "Period Revenue")}: ',
                      style: KeraTypography.labelSmall().copyWith(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(periodRevenue)} $currencyUnit',
                      style: KeraTypography.labelSmall().copyWith(
                        color: KeraColors.tealDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${context.tr("የትርፍ ህዳግ", "Profit Margin")}: ~${profitMargin.toStringAsFixed(0)}%',
                  style: KeraTypography.labelSmall().copyWith(
                    color: KeraColors.actionBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KeraSpacing.lg),

          // Bar Chart Canvas (custom responsive bar representation)
          if (points.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 36,
                    color: KeraColors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'በዚህ ወቅት የተመዘገበ ሽያጭ የለም',
                      'No sales data recorded for this period',
                    ),
                    style: KeraTypography.bodySmall().copyWith(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  final fraction = (p.revenue / effectiveMax).clamp(0.08, 1.0);
                  final isToday = p == points.last;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (p.revenue > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatCurrency(p.revenue),
                                style: KeraTypography.labelSmall().copyWith(
                                  fontSize: 8,
                                  color: isToday
                                      ? KeraColors.actionBlue
                                      : KeraColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: fraction,
                                widthFactor: 0.65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? KeraColors.actionBlue
                                        : KeraColors.actionBlue.withValues(alpha: 0.35),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.label,
                            style: KeraTypography.labelSmall().copyWith(
                              fontSize: 9,
                              color: isToday
                                  ? KeraColors.textPrimary
                                  : KeraColors.textSecondary,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(KeraRadii.xs),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: KeraTypography.labelSmall().copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? KeraColors.primaryNavy
                : KeraColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
