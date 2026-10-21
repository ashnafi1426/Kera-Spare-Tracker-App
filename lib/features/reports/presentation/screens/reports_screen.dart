import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/chart_point.dart';
import '../../domain/models/report_period.dart';
import '../providers/reports_providers.dart';

/// Reports and analytics dashboard displaying sales performance metrics,
/// fl_chart visualizations, top selling parts, and inventory valuation.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final chartPointsAsync = ref.watch(chartPointsProvider);
    final topPartsAsync = ref.watch(topSellingPartsProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesSummaryProvider);
          ref.invalidate(chartPointsProvider);
          ref.invalidate(topSellingPartsProvider);
          ref.invalidate(inventoryValuationProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Period Selector (Daily, Weekly, Monthly)
              SegmentedButton<ReportPeriod>(
                segments: [
                  ButtonSegment<ReportPeriod>(
                    value: ReportPeriod.daily,
                    label: Text(l10n.reportDaily),
                    icon: const Icon(Icons.today_rounded, size: 18),
                  ),
                  ButtonSegment<ReportPeriod>(
                    value: ReportPeriod.weekly,
                    label: Text(l10n.reportWeekly),
                    icon: const Icon(Icons.view_week_rounded, size: 18),
                  ),
                  ButtonSegment<ReportPeriod>(
                    value: ReportPeriod.monthly,
                    label: Text(l10n.reportMonthly),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  ),
                ],
                selected: {selectedPeriod},
                onSelectionChanged: (newSelection) {
                  ref.read(selectedReportPeriodProvider.notifier).setPeriod(
                        newSelection.first,
                      );
                },
              ),
              const SizedBox(height: 16),

              // 2. Overview Metric Cards
              summaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text(err.toString()),
                data: (summary) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: l10n.salesCount,
                              value: CurrencyFormatter.formatCount(
                                summary.salesCount,
                              ),
                              icon: Icons.receipt_long_rounded,
                              iconColor: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: l10n.totalRevenue,
                              value: CurrencyFormatter.formatEtb(
                                summary.totalRevenue,
                              ),
                              icon: Icons.payments_rounded,
                              iconColor: colorScheme.secondary,
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        context,
                        title: l10n.estimatedProfit,
                        value: CurrencyFormatter.formatEtb(
                          summary.totalProfit,
                        ),
                        icon: Icons.trending_up_rounded,
                        iconColor: Colors.green.shade700,
                        valueColor: Colors.green.shade700,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Bar Chart (fl_chart)
              chartPointsAsync.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (points) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                l10n.salesTrend,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendIndicator(
                                    color: colorScheme.primary,
                                    label: l10n.totalRevenue,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildLegendIndicator(
                                    color: Colors.green.shade600,
                                    label: l10n.lineProfit,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: _buildBarChart(context, points),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 4. Extra Cards: Top 5 Selling Parts
              topPartsAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (parts) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.topSellingParts,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (parts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  l10n.noSalesInPeriod,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: parts.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final p = parts[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.partName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              l10n.unitsSold(
                                                CurrencyFormatter.formatQuantity(
                                                  p.quantitySold,
                                                ),
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatEtb(
                                          p.totalRevenue,
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 5. Total Stock Value & Low Stock Count Cards
              valuationAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (valuation) {
                  return Column(
                    children: [
                      // Total Stock Value
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.totalStockValue,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${valuation.totalActiveParts} ${l10n.inventoryTab.toLowerCase()}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.formatEtb(
                                  valuation.totalStockValue,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Low Stock Alert Card
                      Card(
                        elevation: 0,
                        color: valuation.lowStockCount > 0
                            ? Colors.amber.shade50
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: valuation.lowStockCount > 0
                                ? Colors.amber.shade300
                                : colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: valuation.lowStockCount > 0
                                    ? Colors.amber.shade200
                                    : colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: valuation.lowStockCount > 0
                                      ? Colors.amber.shade900
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.lowStockCount,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: valuation.lowStockCount > 0
                                            ? Colors.amber.shade900
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      valuation.lowStockCount > 0
                                          ? '${valuation.lowStockCount} items at or below reorder limit'
                                          : l10n.noLowStockItems,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (valuation.lowStockCount > 0) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    foregroundColor: Colors.amber.shade900,
                                    side: BorderSide(
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                  onPressed: () =>
                                      context.push('/stock/low-stock'),
                                  child: Text(l10n.viewLowStock),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    bool isPrimary = false,
  }) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    return Card(
      elevation: 0,
      color: isPrimary
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<ChartPoint> points) {
    final colorScheme = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noSalesInPeriod,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final maxRevenue = points.fold<double>(
      0.0,
      (maxVal, p) => max(maxVal, max(p.revenue, p.profit)),
    );
    final maxY = maxRevenue == 0 ? 100.0 : maxRevenue * 1.25;

    final barGroups = points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: point.revenue,
            color: colorScheme.primary,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: max(0.0, point.profit),
            color: Colors.green.shade600,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x];
              final isRev = rodIndex == 0;
              return BarTooltipItem(
                '${point.label}\n${isRev ? "Rev: " : "Profit: "}${CurrencyFormatter.formatEtb(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    points[index].label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
