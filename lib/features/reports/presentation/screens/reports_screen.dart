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

/// Reports Screen matching the approved Figma Redesign Specification.
///
/// Features:
/// - Clean executive white header with brand logo, business name, language toggle, and live sync indicator
/// - Overview action bar with Reports title and direct Export modal button
/// - Tactile 3-way segmented period selector (Daily, Weekly, Monthly) with active orange accent
/// - High-contrast Executive Navy Financial Card with COGS footnote, +34.7% growth indicator, and dual revenue/profit split
/// - 2x2 Bento Metric Grid (Number of Sales, Average Ticket, Units Sold with pcs label, Profitability)
/// - Sales Trend Dual-Series Chart (Revenue & Profit) with proportional progress bars
/// - Top 5 Selling Parts with ranking badges
/// - Brand Breakdown & Inventory Stock Valuation with Low Stock Count
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
        backgroundColor: context.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: context.borderColor,
            height: 1,
          ),
        ),
        title: Row(
          children: [
            const KeraLogoWidget(size: 34, borderRadius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kera Spare Tracker',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.tr('ተስፋዬ አውቶ ስፔርስ', 'Tesfaye Auto Spares'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.textSecondaryColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: KeraColors.success,
                        ),
                      ),
                    ],
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    isAmharic ? 'AM' : 'EN',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.textSecondaryColor,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Live Synced Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF159B55),
                  size: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('የተገናኘ', 'Synced'),
                  style: const TextStyle(
                    color: Color(0xFF159B55),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Refresh trigger button
          IconButton(
            icon: Icon(Icons.sync_rounded, color: context.textPrimaryColor, size: 20),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overview Breadcrumb & Direct Export Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ሪፖርቶች', 'Reports'),
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimaryColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('የፋይናንስ እና ንግድ ጤንነት', 'Financial health at a glance'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimaryColor,
                      backgroundColor: context.cardBg,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(
                      context.tr('አውርድ', 'Export'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => ExportReportsSheet.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Tactile 3-Way Segmented Period Selector (Daily, Weekly, Monthly)
              _buildSegmentedControl(context, ref, selectedPeriod, l10n),
              const SizedBox(height: 14),

              // 3. Hero Executive Financial Card (Navy Gradient with COGS Footnote)
              summaryAsync.when(
                loading: () => _buildSummaryCardSkeleton(context),
                error: (err, _) => Container(
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
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
                            : const [Color(0xFF173655), Color(0xFF0D2237)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E385C) : const Color(0xFF224B75).withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF173655).withValues(alpha: isDark ? 0.35 : 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Meta Row: Label, Current Period Badge, Growth Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.totalRevenue.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF224B75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getPeriodLabel(context, selectedPeriod),
                                    style: const TextStyle(
                                      color: Color(0xFF93C5FD),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: KeraColors.brandOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: KeraColors.brandOrange.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    size: 13,
                                    color: KeraColors.brandOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${margin.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: KeraColors.brandOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Hero Revenue Value
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatEtb(summary.totalRevenue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),

                        // Split Row: Estimated Profit & Profit Margin
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.estimatedProfit,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    context.tr('የትርፍ ህዳግ', 'Profit Margin'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    alignment: Alignment.centerRight,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${margin.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: KeraColors.brandOrange,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // COGS Footnote Note
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: KeraColors.brandOrange,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'ትክክለኛ ትርፍ በግዢ ዋጋ (COGS) መዝገብ ላይ የተመሠረተ ነው',
                                    'Profit is calculated based on Cost of Goods Sold (COGS)',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 4. 2x2 Bento Metric Grid
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
                              iconColor: isDark ? KeraColors.brandOrange : const Color(0xFF173655),
                              iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildBentoTile(
                              context,
                              title: context.tr('አማካይ ደረሰኝ', 'Average Ticket'),
                              value: atv > 0
                                  ? '$currencyUnit ${atv.toStringAsFixed(0)}'
                                  : '$currencyUnit 0',
                              subtitle: context.tr('በአንድ ደረሰኝ ሽያጭ', 'Average per receipt'),
                              icon: Icons.calculate_outlined,
                              iconColor: isDark ? KeraColors.navyTint : const Color(0xFF173655),
                              iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                                  ? '${summary.salesCount} pcs'
                                  : '0 pcs',
                              subtitle: context.tr('የተመዘገቡ ግብይቶች', 'Recorded checkouts'),
                              icon: Icons.shopping_bag_outlined,
                              iconColor: KeraColors.brandOrange,
                              iconBg: isDark ? const Color(0xFF2B1D14) : const Color(0xFFFFF7ED),
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
                              subtitle: context.tr('አማካይ የትርፍ መጠን', 'Net margin • rounded'),
                              icon: Icons.trending_up_rounded,
                              iconColor: const Color(0xFF159B55),
                              iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // 5. Sales Trend Chart Component (Theme-Aware Dual-Series & Breakdown Bars)
              chartPointsAsync.when(
                loading: () => _buildChartSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (points) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.salesTrend,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${context.tr("ወቅታዊ", "Current period")} • ${_getPeriodLabel(context, selectedPeriod)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendIndicator(
                                    color: isDark ? KeraColors.navyTint : const Color(0xFF173655),
                                    label: l10n.totalRevenue,
                                    textColor: context.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildLegendIndicator(
                                    color: KeraColors.brandOrange,
                                    label: l10n.lineProfit,
                                    textColor: context.textSecondaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: _buildBarChart(context, points),
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: context.borderColor),
                          const SizedBox(height: 10),

                          // Proportional Breakdown Progress Bars
                          summaryAsync.maybeWhen(
                            data: (summary) {
                              final profitRatio = summary.totalRevenue > 0
                                  ? (summary.totalProfit / summary.totalRevenue).clamp(0.0, 1.0)
                                  : 0.0;
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('የሽያጭ ድርሻ', 'Revenue Share'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '100%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: 1.0,
                                      minHeight: 6,
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark ? KeraColors.navyTint : const Color(0xFF173655),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('የትርፍ ድርሻ', 'Profit Share'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: KeraColors.brandOrange,
                                        ),
                                      ),
                                      Text(
                                        '${(profitRatio * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: KeraColors.brandOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: profitRatio,
                                      minHeight: 6,
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        KeraColors.brandOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 6. Top 5 Selling Parts
              topPartsAsync.when(
                loading: () => _buildTopPartsSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (topParts) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFED7AA)),
                                ),
                                child: const Text(
                                  'Top 5',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: KeraColors.brandOrange,
                                  ),
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
              const SizedBox(height: 16),

              // 7. Brand Breakdown
              brandBreakdownAsync.when(
                loading: () => _buildBrandBreakdownSkeleton(context),
                error: (err, _) => const SizedBox.shrink(),
                data: (brands) {
                  return Card(
                    elevation: 0,
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimaryColor,
                                ),
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
              const SizedBox(height: 16),

              // 8. Inventory Valuation & Low Stock Count Alert
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
                          borderRadius: BorderRadius.circular(18),
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
                                  color: isDark ? const Color(0xFF1E385C) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isDark ? Colors.white : const Color(0xFF173655),
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
                                  color: isDark ? KeraColors.navyTint : const Color(0xFF173655),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Low Stock Count Alert
                      Card(
                        elevation: 0,
                        color: valuation.lowStockCount > 0
                            ? (isDark ? const Color(0xFF2B1D14) : const Color(0xFFFFF7ED))
                            : context.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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
                                      ? (isDark ? const Color(0xFF3F2716) : const Color(0xFFFED7AA))
                                      : (isDark ? const Color(0xFF1E385C) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: valuation.lowStockCount > 0
                                      ? KeraColors.brandOrange
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
                                      'Low Stock Count',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: valuation.lowStockCount > 0
                                            ? KeraColors.brandOrange
                                            : context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      valuation.lowStockCount > 0
                                          ? '${valuation.lowStockCount} items at or below reorder limit'
                                          : context.tr('ክምችት በጥሩ ሁኔታ ላይ ነው', 'All parts sufficiently stocked'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: valuation.lowStockCount > 0
                                            ? (isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C))
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

  // Segmented 3-Way Control (Daily, Weekly, Monthly)
  Widget _buildSegmentedControl(
    BuildContext context,
    WidgetRef ref,
    ReportPeriod selectedPeriod,
    dynamic l10n,
  ) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            context,
            ref,
            period: ReportPeriod.daily,
            label: l10n.reportDaily,
            icon: Icons.today_rounded,
            isSelected: selectedPeriod == ReportPeriod.daily,
          ),
          _buildSegmentButton(
            context,
            ref,
            period: ReportPeriod.weekly,
            label: l10n.reportWeekly,
            icon: Icons.view_week_rounded,
            isSelected: selectedPeriod == ReportPeriod.weekly,
          ),
          _buildSegmentButton(
            context,
            ref,
            period: ReportPeriod.monthly,
            label: l10n.reportMonthly,
            icon: Icons.calendar_month_rounded,
            isSelected: selectedPeriod == ReportPeriod.monthly,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    WidgetRef ref, {
    required ReportPeriod period,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = context.isDark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedReportPeriodProvider.notifier).setPeriod(period);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? KeraColors.brandOrange : context.textSecondaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? context.textPrimaryColor : context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(BuildContext context, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return context.tr('ዛሬ', 'Today');
      case ReportPeriod.weekly:
        return context.tr('ይህ ሳምንት', 'This Week');
      case ReportPeriod.monthly:
        return context.tr('ይህ ወር', 'This Month');
    }
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
            color: context.isDark ? KeraColors.navyTint : const Color(0xFF173655),
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
                color: isDark ? KeraColors.navyTint : const Color(0xFF173655),
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
                  : (isDark ? KeraColors.navyTint : const Color(0xFF173655)),
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
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.textPrimaryColor,
                letterSpacing: -0.3,
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
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
            color: isDark ? KeraColors.navyTint : const Color(0xFF173655),
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
                      fontSize: 10,
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
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: const Center(
        child: KeraLoadingIndicator.small(),
      ),
    );
  }
}
