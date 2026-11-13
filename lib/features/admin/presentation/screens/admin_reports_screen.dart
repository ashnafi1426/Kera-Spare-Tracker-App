import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

/// Screen 5: System Reports & Financial Analytics backed by real backend data.
/// Faithfully reproduces the finalized Figma design (media_1794778732566_84f95155.png):
/// - Executive Navy System Reports Header with Back Navigation & Kera Logo
/// - Period Selector: Daily / Weekly / Monthly
/// - Navy Financial Overview Card (Total Revenue & Est. Profit in ETB)
/// - 2-Column KPI Cards (Transactions & Active Owners)
/// - Revenue & Profit Trend Chart Card with Legend & Empty State
/// - Preserved Top Selling Parts Leaderboard
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  // 0: Daily, 1: Weekly, 2: Monthly (default Daily matching Figma design)
  int _selectedPeriodIndex = 0;

  String get _periodKey {
    switch (_selectedPeriodIndex) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      case 2:
      default:
        return 'monthly';
    }
  }

  String _getPeriodLabel(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.tr('ዛሬ', 'Today');
      case 1:
        return context.tr('ይህ ሳምንት', 'This Week');
      case 2:
      default:
        return context.tr('ይህ ወር', 'This Month');
    }
  }

  String _getPeriodSubtitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.tr('ዛሬ', 'today');
      case 1:
        return context.tr('በዚህ ሳምንት', 'this week');
      case 2:
      default:
        return context.tr('በዚህ ወር', 'this month');
    }
  }

  String _formatCurrencyValue(double val) {
    if (val == 0) return '0';
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 100000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    } else {
      return CurrencyFormatter.formatQuantity(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final backgroundColor = AdminColors.backgroundOf(isDark);
    final reportsAsync = ref.watch(adminReportsProvider(_periodKey));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Navy System Reports Header
            _buildSystemReportsHeader(context),

            // 2. Segmented Period Selector (Daily / Weekly / Monthly)
            _buildPeriodSelector(context, isDark),

            // 3. Reports Content Body (Financial Overview, KPI Cards, Chart, Leaderboard)
            reportsAsync.when(
              loading: () => _buildLoadingSkeleton(context, isDark),
              error: (err, _) => _buildErrorState(context, isDark, err),
              data: (summary) => _buildPopulatedReports(context, isDark, summary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. SYSTEM REPORTS HEADER
  // ===========================================================================
  Widget _buildSystemReportsHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Row(
            children: [
              // Back Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/admin');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  context.tr('የስርዓቱ ሪፖርቶች', 'System Reports'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Kera Logo Plate
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.settings_suggest_rounded,
                    color: AdminColors.headerNavy,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. REPORT PERIOD SELECTOR (Daily / Weekly / Monthly)
  // ===========================================================================
  Widget _buildPeriodSelector(BuildContext context, bool isDark) {
    final containerBg = isDark ? const Color(0xFF13253E) : const Color(0xFFEAEFF5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildPeriodTab(0, context.tr('ዕለታዊ', 'Daily'), isDark),
            _buildPeriodTab(1, context.tr('ሳምንታዊ', 'Weekly'), isDark),
            _buildPeriodTab(2, context.tr('ወርሃዊ', 'Monthly'), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(int index, String label, bool isDark) {
    final isSelected = _selectedPeriodIndex == index;

    final selectedBg = isDark ? AdminColors.primary : AdminColors.navy;
    const selectedText = Colors.white;
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_selectedPeriodIndex != index) {
              setState(() => _selectedPeriodIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: isSelected ? selectedText : unselectedText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. POPULATED REPORTS BODY
  // ===========================================================================
  Widget _buildPopulatedReports(
    BuildContext context,
    bool isDark,
    AdminReportSummary summary,
  ) {
    final periodLabel = _getPeriodLabel(context, _selectedPeriodIndex);
    final periodSubtitle = _getPeriodSubtitle(context, _selectedPeriodIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3.1 Financial Overview Card (Navy Banner Card)
          _buildFinancialOverviewCard(context, isDark, summary, periodLabel),
          const SizedBox(height: 12),

          // 3.2 Secondary 2-Column KPI Cards (Transactions & Active Owners)
          _buildSecondaryKpiRow(context, isDark, summary, periodLabel),
          const SizedBox(height: 14),

          // 3.3 Revenue & Profit Trend Chart Card
          _buildRevenueProfitChartCard(context, isDark, summary, periodLabel, periodSubtitle),
          const SizedBox(height: 16),

          // 3.4 Top Selling Parts Card (Preserved Business Intelligence)
          _buildTopSellingPartsCard(context, isDark, summary),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3.1 FINANCIAL OVERVIEW CARD
  // ===========================================================================
  Widget _buildFinancialOverviewCard(
    BuildContext context,
    bool isDark,
    AdminReportSummary summary,
    String periodLabel,
  ) {
    final revenueFormatted = _formatCurrencyValue(summary.totalRevenue);
    final profitFormatted = _formatCurrencyValue(summary.totalProfit);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: "Financial overview" + Period pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('የፋይናንስ አጠቃላይ እይታ', 'Financial overview'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  periodLabel,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Two Columns with Vertical Divider
          Row(
            children: [
              // Total Revenue Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ጠቅላላ ገቢ', 'Total revenue'),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'ETB ',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              revenueFormatted,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical Divider Line
              Container(
                height: 44,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.white.withValues(alpha: 0.15),
              ),

              // Est. Profit Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('የተጣራ ትርፍ', 'Est. profit'),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'ETB ',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              profitFormatted,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3.2 SECONDARY 2-COLUMN KPI CARDS (Transactions & Active Owners)
  // ===========================================================================
  Widget _buildSecondaryKpiRow(
    BuildContext context,
    bool isDark,
    AdminReportSummary summary,
    String periodLabel,
  ) {
    final cardBg = AdminColors.surfaceOf(isDark);
    final borderColor = AdminColors.borderOf(isDark);
    final textPrimary = AdminColors.textPrimaryOf(isDark);
    final textSecondary = AdminColors.textSecondaryOf(isDark);

    return Row(
      children: [
        // Left Card: Transactions
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatCount(summary.transactionsCount),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('ግብይቶች', 'Transactions'),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Card: Active Owners
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('መድረክ አቀፍ', 'Platform-wide'),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatCount(summary.activeOwnersCount),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('ንቁ ባለቤቶች', 'Active owners'),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3.3 REVENUE & PROFIT TREND CHART CARD
  // ===========================================================================
  Widget _buildRevenueProfitChartCard(
    BuildContext context,
    bool isDark,
    AdminReportSummary summary,
    String periodLabel,
    String periodSubtitle,
  ) {
    final cardBg = AdminColors.surfaceOf(isDark);
    final borderColor = AdminColors.borderOf(isDark);
    final textPrimary = AdminColors.textPrimaryOf(isDark);
    final textSecondary = AdminColors.textSecondaryOf(isDark);
    final innerBg = isDark ? const Color(0xFF13253E) : const Color(0xFFF8FAFC);

    final points = summary.points;
    final hasFinancialActivity = (summary.totalRevenue > 0 || summary.totalProfit > 0) &&
        points.any((p) => p.revenue > 0 || p.profit > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Subtitle
          Text(
            context.tr('የገቢ እና ትርፍ አዝማሚያ', 'Revenue & Profit Trend'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$periodLabel · ETB',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),

          // Legend: Revenue (solid navy) & Profit (dotted orange)
          Row(
            children: [
              Container(
                width: 16,
                height: 3.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF173655),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('ገቢ', 'Revenue'),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 3.5,
                decoration: BoxDecoration(
                  color: AdminColors.keraOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('ትርፍ', 'Profit'),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inner Chart Container (Empty State vs Populated State)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            child: hasFinancialActivity
                ? _buildActiveTrendChart(context, isDark, points)
                : _buildEmptyStateChart(context, isDark, periodLabel, periodSubtitle),
          ),
        ],
      ),
    );
  }

  // Empty state matching Figma design
  Widget _buildEmptyStateChart(
    BuildContext context,
    bool isDark,
    String periodLabel,
    String periodSubtitle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Text(
          context.tr('ምንም የፋይናንስ እንቅስቃሴ የለም', 'No financial activity yet'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'ገቢ እና ትርፍ ሁለቱም በዚህ ጊዜ ETB 0 ናቸው።',
            'Revenue and profit are both ETB 0 $periodSubtitle.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 28),

        // 0 Baseline Line with Navy & Orange Indicators
        Row(
          children: [
            const Text(
              '0',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 12,
                child: CustomPaint(
                  painter: _BaselineEmptyPainter(isDark: isDark),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            periodLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Populated trend chart
  Widget _buildActiveTrendChart(
    BuildContext context,
    bool isDark,
    List<AdminReportPoint> points,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _DynamicTrendChartPainter(
              points: points,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // X-Axis Date / Period Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: points.map((p) {
            return Expanded(
              child: Text(
                p.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3.4 TOP SELLING PARTS CARD (Preserved Business Intelligence)
  // ===========================================================================
  Widget _buildTopSellingPartsCard(
    BuildContext context,
    bool isDark,
    AdminReportSummary summary,
  ) {
    final cardBg = AdminColors.surfaceOf(isDark);
    final borderColor = AdminColors.borderOf(isDark);
    final textPrimary = AdminColors.textPrimaryOf(isDark);
    final textSecondary = AdminColors.textSecondaryOf(isDark);

    final items = summary.topSellingItems;
    final maxUnits = items.fold<int>(0, (prev, curr) => max(prev, curr.units));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ምርጥ ተሸጠዋል · Top Selling Parts', 'Top Selling Parts'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  context.tr('ምንም የተሸጡ ዕቃዎች የሉም', 'No items sold in this period yet'),
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...items.map((item) {
              final progress = maxUnits > 0 ? (item.units / maxUnits).clamp(0.05, 1.0) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.units} ${context.tr("ተሽጧል", "units")}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF1E385C) : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.keraOrange),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADING SKELETON STATE
  // ===========================================================================
  Widget _buildLoadingSkeleton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navy Financial Overview Skeleton
          Container(
            height: 130,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AdminColors.headerNavy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 130,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2-Column KPI Skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceOf(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.borderOf(isDark)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceOf(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.borderOf(isDark)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chart Card Skeleton
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AdminColors.surfaceOf(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminColors.borderOf(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================
  Widget _buildErrorState(BuildContext context, bool isDark, Object err) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminColors.surfaceOf(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminColors.borderOf(isDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AdminColors.danger, size: 44),
            const SizedBox(height: 12),
            Text(
              context.tr('ሪፖርቶችን መጫን አልተቻለም', 'Failed to load reports'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimaryOf(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdminColors.textSecondaryOf(isDark),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminReportsProvider(_periodKey)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: AdminColors.navyDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                context.tr('እንደገና ሞክር', 'Retry'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

/// Empty state baseline painter with dashed / alternating navy and orange baseline
class _BaselineEmptyPainter extends CustomPainter {
  final bool isDark;

  _BaselineEmptyPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    final navyPaint = Paint()
      ..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF173655)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final orangePaint = Paint()
      ..color = const Color(0xFFF28C18)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const segmentLength = 6.0;
    const gap = 3.0;

    double startX = 0;
    bool isNavy = true;

    while (startX < size.width) {
      final endX = min(startX + segmentLength, size.width);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        isNavy ? navyPaint : orangePaint,
      );
      startX += segmentLength + gap;
      isNavy = !isNavy;
    }
  }

  @override
  bool shouldRepaint(covariant _BaselineEmptyPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Dynamic populated trend chart painter comparing Revenue (Navy) & Profit (Orange)
class _DynamicTrendChartPainter extends CustomPainter {
  final List<AdminReportPoint> points;
  final bool isDark;

  _DynamicTrendChartPainter({
    required this.points,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.fold<double>(
      0.0,
      (prev, p) => max(prev, max(p.revenue, p.profit)),
    );
    final denom = maxVal == 0 ? 1.0 : maxVal * 1.25;

    final n = points.length;

    // Draw horizontal dotted gridlines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final ratio in [0.25, 0.5, 0.75]) {
      final y = size.height * ratio;
      _drawDashedHorizontalLine(canvas, y, size.width, gridPaint);
    }

    // Calculate Coordinates
    final revenueCoords = <Offset>[];
    final profitCoords = <Offset>[];

    final stepX = n > 1 ? size.width / (n - 1) : size.width;

    for (int i = 0; i < n; i++) {
      final x = n > 1 ? i * stepX : size.width / 2;
      final p = points[i];

      final revH = (p.revenue / denom) * size.height;
      final revY = size.height - revH.clamp(4.0, size.height);
      revenueCoords.add(Offset(x, revY));

      final profH = (max(0.0, p.profit) / denom) * size.height;
      final profY = size.height - profH.clamp(4.0, size.height);
      profitCoords.add(Offset(x, profY));
    }

    // 1. Draw Revenue Gradient Fill & Line (Navy)
    final revenueColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF173655);

    if (revenueCoords.length > 1) {
      final fillPath = Path()
        ..moveTo(revenueCoords[0].dx, size.height)
        ..lineTo(revenueCoords[0].dx, revenueCoords[0].dy);

      for (int i = 1; i < revenueCoords.length; i++) {
        fillPath.lineTo(revenueCoords[i].dx, revenueCoords[i].dy);
      }
      fillPath.lineTo(revenueCoords.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            revenueColor.withValues(alpha: 0.18),
            revenueColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final revenueLinePaint = Paint()
      ..color = revenueColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final revenuePath = Path()..moveTo(revenueCoords[0].dx, revenueCoords[0].dy);
    for (int i = 1; i < revenueCoords.length; i++) {
      revenuePath.lineTo(revenueCoords[i].dx, revenueCoords[i].dy);
    }
    canvas.drawPath(revenuePath, revenueLinePaint);

    // 2. Draw Profit Line (Orange)
    final profitPaint = Paint()
      ..color = AdminColors.keraOrange
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final profitPath = Path()..moveTo(profitCoords[0].dx, profitCoords[0].dy);
    for (int i = 1; i < profitCoords.length; i++) {
      profitPath.lineTo(profitCoords[i].dx, profitCoords[i].dy);
    }
    canvas.drawPath(profitPath, profitPaint);

    // 3. Draw Dots for Points
    final dotBg = Paint()
      ..color = isDark ? const Color(0xFF102138) : Colors.white
      ..style = PaintingStyle.fill;

    final revDotPaint = Paint()
      ..color = revenueColor
      ..style = PaintingStyle.fill;

    final profDotPaint = Paint()
      ..color = AdminColors.keraOrange
      ..style = PaintingStyle.fill;

    for (final pt in revenueCoords) {
      canvas.drawCircle(pt, 4.0, dotBg);
      canvas.drawCircle(pt, 2.5, revDotPaint);
    }

    for (final pt in profitCoords) {
      canvas.drawCircle(pt, 4.0, dotBg);
      canvas.drawCircle(pt, 2.5, profDotPaint);
    }
  }

  void _drawDashedHorizontalLine(Canvas canvas, double y, double width, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(min(startX + dashWidth, width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicTrendChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.isDark != isDark;
}
