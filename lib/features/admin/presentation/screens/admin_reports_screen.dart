import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 5: Admin Sales Reports matching Sales reports.png.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _selectedPeriod = 0; // 0: Daily, 1: Weekly, 2: Monthly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header with Period Segmented Selector (Sales reports.png)
            _buildNavyHeader(context),

            // 2. Metrics & Charts Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 Stat Tiles
                  _buildStatCards(),
                  const SizedBox(height: 18),

                  // Revenue and Profit Bar / Line Chart Card
                  _buildRevenueProfitChartCard(),
                  const SizedBox(height: 18),

                  // Top Selling Parts Leaderboard Card
                  _buildTopSellingPartsCard(),
                  const SizedBox(height: 32),
                ],
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
                  const Text(
                    'ሪፖርቶች · Reports',
                    style: TextStyle(
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
                      errorBuilder: (_, __, ___) => const Icon(
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
                    _buildPeriodTab(0, 'ዕለታዊ'),
                    _buildPeriodTab(1, 'ሳምንታዊ'),
                    _buildPeriodTab(2, 'ወርሃዊ'),
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
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = index),
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

  Widget _buildStatCards() {
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
          badge: 'ETB · +12%',
          badgeColor: const Color(0xFF10B981),
          value: '4.8M',
          label: 'Revenue',
        ),

        // Profit
        _buildReportTile(
          icon: Icons.bar_chart_rounded,
          badge: 'ETB · +8%',
          badgeColor: const Color(0xFF10B981),
          value: '1.1M',
          label: 'Est. profit',
        ),

        // Transactions
        _buildReportTile(
          icon: Icons.home_outlined,
          badge: 'this month',
          badgeColor: const Color(0xFF5E6D82),
          value: '3,204',
          label: 'Transactions',
        ),

        // Units Sold
        _buildReportTile(
          icon: Icons.sell_outlined,
          badge: 'all owners',
          badgeColor: const Color(0xFF5E6D82),
          value: '11,870',
          label: 'Units sold',
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
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
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
                  fontSize: 24,
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
  Widget _buildRevenueProfitChartCard() {
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
          const Text(
            'ገቢ እና ትርፍ · Revenue and profit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 20),

          // Custom Painted Bars + Overlay Trend Line
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarTrendChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Selling Parts Card matching Sales reports.png
  Widget _buildTopSellingPartsCard() {
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
          const Text(
            'ምርጥ ተሸጠዋል · Top selling parts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 16),

          // Leader 1
          _buildPartProgressItem(
            name: 'Fuel filter · IPD',
            units: '1,420 units',
            progress: 0.90,
          ),
          const SizedBox(height: 14),

          // Leader 2
          _buildPartProgressItem(
            name: 'Seal kit · CAT',
            units: '1,180 units',
            progress: 0.75,
          ),
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
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C2340),
              ),
            ),
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

class _BarTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFF0C2340)
      ..style = PaintingStyle.fill;

    // Heights of 7 representative bars
    final heights = [0.35, 0.55, 0.40, 0.65, 0.60, 0.75, 0.70, 0.90];
    final barWidth = size.width / (heights.length * 1.8);
    final gap = (size.width - (heights.length * barWidth)) / (heights.length - 1);

    final linePoints = <Offset>[];

    for (int i = 0; i < heights.length; i++) {
      final x = i * (barWidth + gap);
      final barH = size.height * heights[i];
      final y = size.height - barH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      // Trend line point roughly through the lower-middle portion
      linePoints.add(Offset(x + barWidth / 2, size.height - (barH * 0.45)));
    }

    // Draw baseline
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

