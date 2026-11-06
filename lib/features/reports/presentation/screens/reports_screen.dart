import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../domain/models/chart_point.dart';
import '../../domain/models/report_period.dart';
import '../providers/reports_providers.dart';
import '../widgets/export_reports_sheet.dart';

/// Screen 3 Fix: Rebuilt Reports Screen with predictable layout,
/// full dark mode stability, theme-aware fl_chart visuals, top-selling parts,
/// and brand breakdown.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isAmharic = context.isAmharic;
    final isDark = context.isDark;

    final selectedPeriod = ref.watch(selectedReportPeriodProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final chartPointsAsync = ref.watch(chartPointsProvider);
    final topPartsAsync = ref.watch(topSellingPartsProvider);
    final brandBreakdownAsync = ref.watch(brandBreakdownProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF071322) : KeraColors.primaryNavy,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const KeraLogoWidget(size: 36, borderRadius: 8),
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
          // Language Toggle Pill
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
              color: isDark ? const Color(0xFF102138) : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 11,
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
              ref.invalidate(brandBreakdownProvider);
              ref.invalidate(inventoryValuationProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: KeraColors.brandOrange,
        onRefresh: () async {
          ref.invalidate(salesSummaryProvider);
          ref.invalidate(chartPointsProvider);
          ref.invalidate(topSellingPartsProvider);
          ref.invalidate(brandBreakdownProvider);
          ref.invalidate(inventoryValuationProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sub-header Breadcrumb & Executive Export Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('የሪፖርቶች ማጠቃለያ', 'Reports Overview'),
                            style: KeraTypography.titleSmall(
                              color: context.textPrimaryColor,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr('የፋይናንስ እና ንግድ ጤንነት', 'Financial Health & Metrics'),
                            style: KeraTypography.labelSmall(
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimaryColor,
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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

              // 2. Primary Executive Hero Valuation Card (predictable fixed height)
              summaryAsync.when(
                loading: () => _buildSummaryCardSkeleton(context),
                error: (err, _) => Container(
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    err.toString(),
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
                data: (summary) {
                  final margin = summary.totalRevenue > 0
                      ? (summary.totalProfit / summary.totalRevenue * 100)
                      : 0.0;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF0F2647), Color(0xFF09182E)]
                            : const [KeraColors.primaryNavyDark, KeraColors.primaryNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E385C) : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
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
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      l10n.totalRevenue,
                                      style: KeraTypography.labelSmall(
                                        color: Colors.white70,
                                      ).copyWith(
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      context.tr('ወቅታዊ', 'Current'),
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.brandOrange,
                                      ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: KeraColors.brandOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: KeraColors.brandOrange.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    size: 14,
                                    color: KeraColors.brandOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${margin >= 0 ? "+" : ""}${margin.toStringAsFixed(1)}%',
                                    style: KeraTypography.labelSmall(
                                      color: Colors.white,
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
                                      CurrencyFormatter.formatEtb(summary.totalProfit),
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
                                        color: KeraColors.brandOrange,
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
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: Colors.white60,
                            ),
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

              // 3. 4-Tile Bento Grid (Fixed Height Placeholder when loading)
              summaryAsync.when(
                loading: () => _buildBentoSkeleton(context),
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
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: l10n.salesCount,
                              value: CurrencyFormatter.formatCount(summary.salesCount),
                              subtitle: context.tr('የተጠናቀቁ ደረሰኞች', 'Completed receipts'),
                              icon: Icons.receipt_long_rounded,
                              iconColor: isDark ? KeraColors.brandOrange : KeraColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('አማካይ ደረሰኝ', 'Average Ticket'),
                              value: atv > 0
                                  ? '${atv.toStringAsFixed(0)} $currencyUnit'
                                  : '0 $currencyUnit',
                              subtitle: context.tr('በአንድ ደረሰኝ ሽያጭ', 'Average per receipt'),
                              icon: Icons.calculate_outlined,
                              iconColor: isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('የተሸጡ ዕቃዎች', 'Units Sold'),
                              value: summary.salesCount > 0
                                  ? '${summary.salesCount} ${context.tr("ሽያጮች", "sales")}'
                                  : '0',
                              subtitle: context.tr('የተመዘገቡ ግብይቶች', 'Recorded checkouts'),
                              icon: Icons.shopping_bag_outlined,
                              iconColor: KeraColors.brandOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
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

              // 4. Sales Trend Bar Chart (Theme-Aware FL_Chart)
              chartPointsAsync.when(
                loading: () => _buildChartSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (points) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
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
                                style: KeraTypography.titleMedium(
                                  color: context.textPrimaryColor,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendIndicator(
                                    color: isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
                                    label: l10n.totalRevenue,
                                    textColor: context.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildLegendIndicator(
                                    color: KeraColors.brandOrange,
                                    label: l10n.lineProfit,
                                    textColor: context.textSecondaryColor,
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
                          Divider(height: 1, color: context.borderColor),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'የቀናት የሽያጭ እና ትርፍ ንፅፅር',
                                    'Daily revenue vs profit',
                                  ),
                                  style: KeraTypography.labelSmall(
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                selectedPeriod.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.brandOrange,
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
              const SizedBox(height: 18),

              // 5. Top 5 Selling Parts
              topPartsAsync.when(
                loading: () => _buildTopPartsSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (topParts) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.topSellingParts,
                                style: KeraTypography.titleMedium(
                                  color: context.textPrimaryColor,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Top 5',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.brandOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (topParts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                      color: context.textSecondaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr(
                                        'በዚህ ወቅት የተሸጡ ዕቃዎች የሉም',
                                        'No parts sold in this period',
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < topParts.length; i++) ...[
                              _buildTopPartRow(context, index: i, part: topParts[i]),
                              if (i < topParts.length - 1)
                                Divider(height: 14, color: context.borderColor),
                            ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // 6. Brand Breakdown (New requirement)
              brandBreakdownAsync.when(
                loading: () => _buildBrandBreakdownSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (brands) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('የብራንዶች ክፍፍል', 'Brand Breakdown'),
                                style: KeraTypography.titleMedium(
                                  color: context.textPrimaryColor,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 18,
                                color: context.textSecondaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (final b in brands) ...[
                            _buildBrandItemRow(context, item: b),
                            if (b != brands.last) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // 7. Inventory Valuation & Low Stock Alert
              valuationAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (valuation) {
                  return Column(
                    children: [
                      // Stock Value
                      Card(
                        elevation: 0,
                        color: context.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: context.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isDark ? Colors.white : KeraColors.primaryNavy,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.totalStockValue,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${valuation.totalActiveParts} ${context.tr("የተመዘገቡ ዕቃዎች", "active parts")}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatEtb(valuation.totalStockValue),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Low Stock Alert
                      Card(
                        elevation: 0,
                        color: valuation.lowStockCount > 0
                            ? (isDark ? const Color(0xFF102138) : KeraColors.orange100)
                            : context.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: valuation.lowStockCount > 0
                                ? KeraColors.brandOrange
                                : context.borderColor,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: valuation.lowStockCount > 0
                                      ? (isDark ? KeraColors.navy800 : KeraColors.orange100)
                                      : (isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: valuation.lowStockCount > 0
                                      ? KeraColors.orange700
                                      : context.textSecondaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('አነስተኛ ክምችት ማስጠንቀቂያ', 'Low Stock Alert'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: valuation.lowStockCount > 0
                                            ? KeraColors.orange700
                                            : context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      valuation.lowStockCount > 0
                                          ? '${valuation.lowStockCount} ${context.tr("ዕቃዎች ሊያልቁ ነው (አስቸኳይ ማዘዝ)", "items at or below reorder level")}'
                                          : context.tr('ክምችት በጥሩ ሁኔታ ላይ ነው', 'All parts sufficiently stocked'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: valuation.lowStockCount > 0
                                            ? KeraColors.orange700
                                            : context.textSecondaryColor,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: KeraColors.brandOrange,
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

  Widget _buildTopPartRow(
    BuildContext context, {
    required int index,
    required dynamic part,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: index == 0
                ? KeraColors.brandOrange
                : (context.isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '#${index + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: index == 0 ? Colors.white : context.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.partName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${part.quantitySold} ${context.tr("ተሽጧል", "units sold")}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.formatEtb(part.totalRevenue),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandItemRow(
    BuildContext context, {
    required BrandBreakdownItem item,
  }) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: KeraColors.brandOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.brandName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${item.count} ${context.tr("ዕቃዎች", "parts")})',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
            Text(
              '${item.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (item.percentage / 100).clamp(0.02, 1.0),
            minHeight: 6,
            backgroundColor: isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              item.percentage > 30
                  ? KeraColors.brandOrange
                  : (isDark ? KeraColors.navyTint : KeraColors.primaryNavy),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: context.textMutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, List<ChartPoint> points) {
    final isDark = context.isDark;

    if (points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 36, color: context.textSecondaryColor),
            const SizedBox(height: 8),
            Text(
              context.l10n.noSalesInPeriod,
              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
            ),
          ],
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
            color: isDark ? KeraColors.navyTint : KeraColors.primaryNavy,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: max(0.0, point.profit),
            color: KeraColors.brandOrange,
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
            getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: context.textSecondaryColor,
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
            color: context.borderColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // Predictable skeletons preventing layout jump
  Widget _buildSummaryCardSkeleton(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator.small(label: '...'),
      ),
    );
  }

  Widget _buildBentoSkeleton(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator.small(),
      ),
    );
  }

  Widget _buildChartSkeleton(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator(),
      ),
    );
  }

  Widget _buildTopPartsSkeleton(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator.small(),
      ),
    );
  }

  Widget _buildBrandBreakdownSkeleton(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator.small(),
      ),
    );
  }
}
