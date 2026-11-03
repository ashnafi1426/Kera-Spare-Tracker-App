import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/chart_point.dart';
import '../../domain/models/report_period.dart';
import '../providers/reports_providers.dart';
import '../widgets/best_sellers_sheet.dart';
import '../widgets/export_reports_sheet.dart';
import '../widgets/inventory_reports_sheet.dart';
import '../widgets/profit_reports_sheet.dart';
import '../widgets/sales_analytics_sheet.dart';

/// Reports and analytics dashboard displaying sales performance metrics,
/// fl_chart visualizations, top selling parts, and inventory valuation.
///
/// Follows Google Stitch Screen 1 (Reports Overview — የሪፖርቶች ማጠቃለያ).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final isAmharic = context.isAmharic;

    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final chartPointsAsync = ref.watch(chartPointsProvider);
    final topPartsAsync = ref.watch(topSellingPartsProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('የፋይናንስ ሪፖርቶች', 'Financial Reports'),
                    style: KeraTypography.titleMedium(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    context.tr('ኬራ ስፔር • የሂሳብ እና ንግድ ሁኔታ', 'Kera Spare • Business Performance'),
                    style: KeraTypography.labelSmall(
                      color: Colors.white.withValues(alpha: 0.7),
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // One-tap Language Toggle Pill
          InkWell(
            onTap: () {
              ref.read(localeControllerProvider.notifier).toggleLocale();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isAmharic ? 'English' : 'አማርኛ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Live Synced Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00322D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KeraColors.tealAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KeraColors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  context.tr('የተገናኘ', 'Synced'),
                  style: KeraTypography.labelSmall(color: Colors.white)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: context.tr('አድስ', 'Refresh'),
            onPressed: () {
              ref.invalidate(salesSummaryProvider);
              ref.invalidate(chartPointsProvider);
              ref.invalidate(topSellingPartsProvider);
              ref.invalidate(inventoryValuationProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sub-header Breadcrumb & Executive Export Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: KeraColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KeraColors.outlineBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('የሪፖርቶች ማጠቃለያ', 'Reports Overview'),
                            style: KeraTypography.titleSmall()
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr('የፋይናንስ እና ንግድ ጤንነት', 'Financial Health & Metrics'),
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KeraColors.primaryNavy,
                        side: const BorderSide(color: KeraColors.outlineBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: Text(
                        context.tr('አውርድ', 'Export'),
                        style: KeraTypography.labelSmall()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => ExportReportsSheet.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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

              // 2. Primary Executive Hero Valuation Card (Stitch Screen 1)
              summaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text(err.toString()),
                data: (summary) {
                  final margin = summary.totalRevenue > 0
                      ? (summary.totalProfit / summary.totalRevenue * 100)
                      : 0.0;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          KeraColors.primaryNavyDark,
                          KeraColors.primaryNavy,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.totalRevenue,
                                  style: KeraTypography.labelSmall(
                                    color: Colors.white70,
                                  ).copyWith(
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    context.tr('ወቅታዊ', 'Current Period'),
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.tealAccent,
                                    ).copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00322D),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: KeraColors.tealAccent
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.trending_up_rounded,
                                      size: 14, color: KeraColors.tealAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${margin >= 0 ? "+" : ""}${margin.toStringAsFixed(1)}%',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.tealAccent,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatEtb(summary.totalRevenue),
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
                                    l10n.estimatedProfit,
                                    style: KeraTypography.labelSmall(
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      CurrencyFormatter.formatEtb(
                                          summary.totalProfit),
                                      style: KeraTypography.labelLarge(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
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
                                    context.tr('የትርፍ ህዳግ', 'Profit Margin'),
                                    style: KeraTypography.labelSmall(
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${margin.toStringAsFixed(1)}%',
                                      style: KeraTypography.labelLarge(
                                        color: KeraColors.tealAccent,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 13, color: Colors.white60),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                context.tr(
                                  'ትክክለኛ ትርፍ በግዢ ዋጋ (COGS) መዝገብ ላይ የተመሠረተ ነው',
                                  'Profit is calculated based on Cost of Goods Sold (COGS)',
                                ),
                                style: KeraTypography.labelSmall(
                                  color: Colors.white60,
                                ).copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 3. 4-Tile Executive KPI Bento Grid (Stitch Screen 1)
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (summary) {
                  final atv = summary.salesCount > 0
                      ? summary.totalRevenue / summary.salesCount
                      : 0.0;
                  final currencyUnit = context.tr('ብር', 'ETB');

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Tile 1: Number of Sales
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: l10n.salesCount,
                              value: CurrencyFormatter.formatCount(
                                summary.salesCount,
                              ),
                              subtitle: context.tr('የተጠናቀቁ ደረሰኞች', 'Completed receipts'),
                              icon: Icons.receipt_long_rounded,
                              iconColor: KeraColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Tile 2: Average Ticket Value (ATV)
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('አማካይ ደረሰኝ', 'Average Ticket'),
                              value: atv > 0
                                  ? '${atv.toStringAsFixed(0)} $currencyUnit'
                                  : '0 $currencyUnit',
                              subtitle: context.tr('በአንድ ደረሰኝ ሽያጭ', 'Average per receipt'),
                              icon: Icons.calculate_outlined,
                              iconColor: KeraColors.actionBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Tile 3: Units Sold
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('የተሸጡ ዕቃዎች', 'Units Sold'),
                              value: summary.salesCount > 0
                                  ? '${summary.salesCount} ${context.tr("ሽያጮች", "sales")}'
                                  : '0',
                              subtitle: context.tr('የተመዘገቡ ግብይቶች', 'Recorded checkouts'),
                              icon: Icons.shopping_bag_outlined,
                              iconColor: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Tile 4: Velocity Trajectory
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('የትርፍ ሁኔታ', 'Profitability'),
                              value: summary.totalRevenue > 0
                                  ? '${((summary.totalProfit / summary.totalRevenue) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              subtitle: context.tr('አማካይ የትርፍ መጠን', 'Net margin ratio'),
                              icon: Icons.trending_up_rounded,
                              iconColor: KeraColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // 4. Bar Chart (fl_chart) - 7-Day Revenue vs Profit Sparkline
              chartPointsAsync.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (points) {
                  return Card(
                    elevation: 0,
                    color: KeraColors.surfacePure,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: KeraColors.outlineBorder,
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
                                style: KeraTypography.titleMedium()
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendIndicator(
                                    color: KeraColors.primaryNavy,
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
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr(
                                  'የቀናት የሽያጭ እና ትርፍ ንፅፅር',
                                  'Daily revenue vs profit comparison',
                                ),
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                              InkWell(
                                onTap: () => SalesAnalyticsSheet.show(context),
                                child: Text(
                                  context.tr('ዝርዝር እይ →', 'View Details →'),
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.actionBlue,
                                  ).copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 20),

              // 5. Deep-Dive Analytic Module Cards (Stitch Screens 2, 3, 4, 5)
              Text(
                context.tr('ዝርዝር ሪፖርቶች', 'Analytic Modules'),
                style: KeraTypography.titleSmall()
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildModuleCard(
                icon: Icons.query_stats_rounded,
                iconColor: KeraColors.primaryNavy,
                iconBg: KeraColors.surfaceContainer,
                title: context.tr('የሽያጭ ሪፖርት', 'Sales Analytics'),
                subtitle: context.tr('የገቢ ሂደት እና የክፍያ ዓይነቶች', 'Revenue Velocity & Payment Breakdown'),
                onTap: () => SalesAnalyticsSheet.show(context),
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                icon: Icons.payments_rounded,
                iconColor: Colors.green.shade800,
                iconBg: Colors.green.shade50,
                title: context.tr('የትርፍ እና ወጪ ሪፖርት', 'Profit & Margins'),
                subtitle: context.tr('የትርፍ ህዳግ እና የግዢ ወጪ ትንተና', 'P&L Waterfall & Direct COGS Analysis'),
                onTap: () => ProfitReportsSheet.show(context),
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                icon: Icons.inventory_2_rounded,
                iconColor: Colors.teal.shade800,
                iconBg: Colors.teal.shade50,
                title: context.tr('የመጋዘን ክምችት ሪፖርት', 'Inventory Health'),
                subtitle: context.tr('የጠቅላላ ክምችት ካፒታል እና ሁኔታ', 'Total Capital Locked & Health Breakdown'),
                onTap: () => InventoryReportsSheet.show(context),
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                icon: Icons.leaderboard_rounded,
                iconColor: Colors.amber.shade900,
                iconBg: Colors.amber.shade50,
                title: context.tr('ከፍተኛ ተፈላጊ ዕቃዎች', 'Best Sellers'),
                subtitle: context.tr('በሽያጭ ቀዳሚ የሆኑ 10 ዕቃዎች', 'Top 10 Moving Products Leaderboard'),
                onTap: () => BestSellersSheet.show(context),
              ),
              const SizedBox(height: 20),

              // 6. Top 5 Selling Parts
              topPartsAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (parts) {
                  return Card(
                    elevation: 0,
                    color: KeraColors.surfacePure,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: KeraColors.outlineBorder,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.star_rounded,
                                          color: Colors.amber.shade800,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        context.tr('በሽያጭ ቀዳሚ የሆኑ ዕቃዎች', 'Top Selling Auto Parts'),
                                        style: KeraTypography.titleSmall()
                                            .copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => BestSellersSheet.show(context),
                                child: Text(
                                  context.tr('ሁሉንም እይ', 'View All'),
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.actionBlue,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          if (parts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  context.tr('ምንም የተሸጠ እቃ የለም', 'No sales recorded yet'),
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
                              itemCount: min(parts.length, 5),
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final p = parts[index];
                                final rankColors = [
                                  Colors.amber.shade700,
                                  Colors.grey.shade600,
                                  Colors.brown.shade600,
                                ];
                                final badgeColor = index < 3
                                    ? rankColors[index]
                                    : colorScheme.outline;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.partName,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${p.quantitySold} ${context.tr("ተሽጧል", "units sold")}',
                                              style:
                                                  theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
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

              // 7. Total Stock Value & Low Stock Alert Cards
              valuationAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (valuation) {
                  return Column(
                    children: [
                      // Total Stock Value
                      Card(
                        elevation: 0,
                        color: KeraColors.surfaceCanvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: KeraColors.outlineBorder,
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
                                      '${valuation.totalActiveParts} ${context.tr("የተመዘገቡ ዕቃዎች", "active parts")}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatter.formatEtb(
                                    valuation.totalStockValue,
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
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
                            : KeraColors.surfaceCanvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: valuation.lowStockCount > 0
                                ? Colors.amber.shade300
                                : KeraColors.outlineBorder,
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
                                    ? Colors.amber.shade100
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
                                      context.tr('አነስተኛ ክምችት ማስጠንቀቂያ', 'Low Stock Alerts'),
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: valuation.lowStockCount > 0
                                            ? Colors.amber.shade900
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      valuation.lowStockCount > 0
                                          ? '${valuation.lowStockCount} ${context.tr("ዕቃዎች ሊያልቁ ነው (አስቸኳይ ማዘዝ)", "parts low in stock (reorder required)")}'
                                          : context.tr('ክምችት በጥሩ ሁኔታ ላይ ነው', 'All parts sufficiently stocked'),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: valuation.lowStockCount > 0
                                            ? Colors.amber.shade900
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (valuation.lowStockCount > 0)
                                TextButton(
                                  onPressed: () => context.push('/stock/low'),
                                  child: Text(
                                    context.tr('እይ', 'View'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
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

  Widget _buildBentoTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? KeraColors.warningAmberBg : KeraColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? KeraColors.warningAmberBorder
              : KeraColors.outlineBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: KeraTypography.labelSmall(
                    color: isWarning
                        ? KeraColors.warningAmber
                        : KeraColors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: KeraTypography.headlineSmall(
                color: isWarning
                    ? KeraColors.warningAmber
                    : KeraColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: KeraTypography.labelSmall(
              color: isWarning
                  ? Colors.brown.shade800
                  : KeraColors.textMuted,
            ).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KeraColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KeraColors.outlineBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KeraTypography.labelMedium()
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: KeraTypography.bodySmall(
                      color: KeraColors.textSecondary,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: KeraColors.textSecondary),
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
            color: KeraColors.primaryNavy,
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
