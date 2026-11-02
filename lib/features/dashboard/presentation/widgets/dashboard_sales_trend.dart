import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
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
                      'የሽያጭ ሂደት / Trends',
                      style: KeraTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: KeraColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Performance insights',
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
                      label: 'ዛሬ',
                      isSelected: selectedPeriod == ReportPeriod.daily,
                      onTap: () => onPeriodChanged(ReportPeriod.daily),
                    ),
                    _PeriodTab(
                      label: 'ሳምንት',
                      isSelected: selectedPeriod == ReportPeriod.weekly,
                      onTap: () => onPeriodChanged(ReportPeriod.weekly),
                    ),
                    _PeriodTab(
                      label: 'ወር',
                      isSelected: selectedPeriod == ReportPeriod.monthly,
                      onTap: () => onPeriodChanged(ReportPeriod.monthly),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: KeraSpacing.md),

          // Metric highlights strip
          Container(
            padding: const EdgeInsets.all(KeraSpacing.sm),
            decoration: BoxDecoration(
              color: KeraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(KeraRadii.xs),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ጠቅላላ ገቢ (Revenue)',
                        style: KeraTypography.labelSmall().copyWith(
                          color: KeraColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatCurrency(periodRevenue),
                            style: KeraTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.bold,
                              color: KeraColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ብር',
                            style: KeraTypography.labelSmall().copyWith(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: KeraColors.borderVariant,
                ),
                const SizedBox(width: KeraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'አማካይ ትርፍ (Margin)',
                        style: KeraTypography.labelSmall().copyWith(
                          color: KeraColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${profitMargin.toStringAsFixed(1)}%',
                            style: KeraTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.bold,
                              color: KeraColors.tealDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ጥቅል',
                            style: KeraTypography.labelSmall().copyWith(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KeraSpacing.md),

          // Custom tactile bar chart
          if (points.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'ምንም የሽያጭ መረጃ አልተገኘም (No data yet)',
                style: KeraTypography.bodySmall().copyWith(
                  color: KeraColors.textSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  final ratio = (p.revenue / effectiveMax).clamp(0.08, 1.0);
                  final isPeak = p.revenue == maxValue && maxValue > 0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(p.revenue),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  isPeak ? FontWeight.bold : FontWeight.normal,
                              color: isPeak
                                  ? KeraColors.actionBlue
                                  : KeraColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isPeak
                                        ? KeraColors.actionBlue
                                        : KeraColors.actionBlue
                                            .withValues(alpha: 0.35),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isPeak ? FontWeight.bold : FontWeight.w500,
                              color: isPeak
                                  ? KeraColors.actionBlue
                                  : KeraColors.textSecondary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(KeraRadii.xs),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
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
            color: isSelected ? KeraColors.actionBlue : KeraColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
