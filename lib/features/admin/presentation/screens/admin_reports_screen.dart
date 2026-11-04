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
import '../widgets/admin_header_bar.dart';

/// Screen 5: Admin Sales Reports backed entirely by real backend data.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  int _selectedPeriodIndex = 2; // 0: Daily, 1: Weekly, 2: Monthly

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

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsProvider(_periodKey));

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header with Period Segmented Selector
            _buildNavyHeader(context),

            // 2. Metrics & Charts Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: reportsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: KeraLoadingIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('ሪፖርቶችን መጫን አልተቻለም', 'Failed to load reports: $err'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AdminColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(adminReportsProvider(_periodKey)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.headerNavy,
                          ),
                          child: Text(context.tr('እንደገና ሞክር', 'Retry')),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4 Stat Tiles
                    _buildStatCards(summary),
                    const SizedBox(height: 18),

                    // Revenue and Profit Bar / Line Chart Card
                    _buildRevenueProfitChartCard(summary),
                    const SizedBox(height: 18),

                    // Top Selling Parts Leaderboard Card
                    _buildTopSellingPartsCard(summary),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // Top Bar: Back button + Title + Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AdminHeaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => context.pop(),
                  ),
                  Text(
                    context.tr('የስርዓቱ ሪፖርቶች', 'System Reports'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.settings_suggest_rounded,
                        color: AdminColors.headerNavy,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Period Control: ዕለታዊ, ሳምንታዊ, ወርሃዊ
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildPeriodTab(0, context.tr('ዕለታዊ', 'Daily')),
                    _buildPeriodTab(1, context.tr('ሳምንታዊ', 'Weekly')),
                    _buildPeriodTab(2, context.tr('ወርሃዊ', 'Monthly')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriodIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0C2340) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AdminColors.headerTextSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(AdminReportSummary summary) {
    final periodName = switch (_selectedPeriodIndex) {
      0 => context.tr('ዛሬ', 'Today'),
      1 => context.tr('ይህ ሳምንት', 'This Week'),
      _ => context.tr('ይህ ወር', 'This Month'),
    };

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Revenue
        _buildReportTile(
          icon: Icons.bar_chart_rounded,
          badge: 'ETB · $periodName',
          badgeColor: const Color(0xFF10B981),
          value: CurrencyFormatter.formatCompact(summary.totalRevenue),
          label: context.tr('ጠቅላላ ገቢ', 'Total Revenue'),
        ),

        // Profit
        _buildReportTile(
          icon: Icons.insert_chart_outlined_rounded,
          badge: 'ETB · $periodName',
          badgeColor: const Color(0xFF10B981),
          value: CurrencyFormatter.formatCompact(summary.totalProfit),
          label: context.tr('የተጣራ ትርፍ', 'Est. Profit'),
        ),

        // Transactions
        _buildReportTile(
          icon: Icons.receipt_long_rounded,
          badge: periodName,
          badgeColor: const Color(0xFF5E6D82),
          value: CurrencyFormatter.formatCount(summary.transactionsCount),
          label: context.tr('ግብይቶች', 'Transactions'),
        ),

        // Active Owners
        _buildReportTile(
          icon: Icons.store_rounded,
          badge: context.tr('መድረክ', 'Platform'),
          badgeColor: const Color(0xFF5E6D82),
          value: CurrencyFormatter.formatCount(summary.activeOwnersCount),
          label: context.tr('ንቁ ሱቆች', 'Active Owners'),
        ),
      ],
    );
  }

  Widget _buildReportTile({
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFD97706)),
              ),
              Flexible(
                child: Text(
                  badge,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5E6D82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Revenue and Profit Comparison Chart matching Sales reports.png
  Widget _buildRevenueProfitChartCard(AdminReportSummary summary) {
    final points = summary.points;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('ገቢ እና ትርፍ · Revenue & Profit', 'Revenue & Profit Trend'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C2340),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('ገቢ', 'Revenue'),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF5E6D82)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF58220),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('ትርፍ', 'Profit'),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF5E6D82)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Painted Bars + Overlay Trend Line
          SizedBox(
            height: 140,
            width: double.infinity,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      context.tr('ምንም የሽያጭ መረጃ የለም', 'No sales data for this period'),
                      style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
                    ),
                  )
                : CustomPaint(
                    painter: _DynamicBarTrendChartPainter(points: points),
                  ),
          ),
          const SizedBox(height: 10),
          // Labels row
          if (points.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points.map((p) {
                return Expanded(
                  child: Text(
                    p.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5E6D82),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Top Selling Parts Card matching Sales reports.png
  Widget _buildTopSellingPartsCard(AdminReportSummary summary) {
    final items = summary.topSellingItems;
    final maxUnits = items.fold<int>(0, (prev, curr) => max(prev, curr.units));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ምርጥ ተሸጠዋል · Top Selling Parts', 'Top Selling Parts'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  context.tr('ምንም የተሸጡ ዕቃዎች የሉም', 'No items sold in this period yet'),
                  style: const TextStyle(color: Color(0xFF5E6D82), fontSize: 13),
                ),
              ),
            )
          else
            ...items.map((item) {
              final progress = maxUnits > 0 ? (item.units / maxUnits).clamp(0.05, 1.0) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildPartProgressItem(
                  name: item.name,
                  units: '${item.units} ${context.tr("ተሽጧል", "units")}',
                  progress: progress,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPartProgressItem({
    required String name,
    required String units,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              units,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5E6D82),
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
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.keraOrange),
          ),
        ),
      ],
    );
  }
}

class _DynamicBarTrendChartPainter extends CustomPainter {
  final List<AdminReportPoint> points;

  _DynamicBarTrendChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.fold<double>(
      0.0,
      (prev, p) => max(prev, max(p.revenue, p.profit)),
    );
    final denom = maxVal == 0 ? 1.0 : maxVal * 1.25;

    final barPaint = Paint()
      ..color = const Color(0xFF0C2340)
      ..style = PaintingStyle.fill;

    final n = points.length;
    final barWidth = max(8.0, size.width / (n * 2.2));
    final gap = n > 1 ? (size.width - (n * barWidth)) / (n - 1) : 0.0;

    final linePoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final x = i * (barWidth + gap);
      final barH = (p.revenue / denom) * size.height;
      final y = size.height - max(4.0, barH);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, max(4.0, barH)),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      final profitH = (max(0.0, p.profit) / denom) * size.height;
      final profitY = size.height - profitH;
      linePoints.add(Offset(x + barWidth / 2, profitY));
    }

    // Draw profit trend line
    final linePaint = Paint()
      ..color = const Color(0xFFF58220)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    if (linePoints.isNotEmpty) {
      linePath.moveTo(linePoints[0].dx, linePoints[0].dy);
      for (int i = 1; i < linePoints.length; i++) {
        linePath.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Draw dot markers
      final dotPaint = Paint()
        ..color = const Color(0xFFF58220)
        ..style = PaintingStyle.fill;
      for (final pt in linePoints) {
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicBarTrendChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
