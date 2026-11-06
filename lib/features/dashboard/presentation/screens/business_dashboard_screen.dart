import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/widgets/dashboard_header_bar.dart';
import '../../../../core/design/widgets/kera_app_footer.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/domain/models/report_period.dart';
import '../../../reports/domain/models/sales_summary.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/dashboard_providers.dart';

/// Screen 1: Dashboard (1 Dashboard.png).
/// Supports dark mode, live bilingual (Amharic/English) translation, and professional loading indicators.
class BusinessDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToInventory;
  final VoidCallback? onSwitchToSales;
  final VoidCallback? onSwitchToReports;

  const BusinessDashboardScreen({
    super.key,
    this.onSwitchToInventory,
    this.onSwitchToSales,
    this.onSwitchToReports,
  });

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends ConsumerState<BusinessDashboardScreen> {
  int _selectedPeriod = 0; // 0: ዛሬ, 1: ይህ ሳምንት, 2: ይህ ወር

  String _getTimeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return context.tr('መልካም ጥዋት', 'Good Morning');
    } else if (hour >= 12 && hour < 17) {
      return context.tr('መልካም ከሰዓት', 'Good Afternoon');
    } else {
      return context.tr('መልካም ምሽት', 'Good Evening');
    }
  }

  void _onPeriodChanged(int index) {
    setState(() => _selectedPeriod = index);
    final period = switch (index) {
      0 => ReportPeriod.daily,
      1 => ReportPeriod.weekly,
      2 => ReportPeriod.monthly,
      _ => ReportPeriod.daily,
    };
    ref.read(selectedReportPeriodProvider.notifier).setPeriod(period);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final metricsAsync = ref.watch(businessDashboardMetricsProvider);
    final recentSalesAsync = ref.watch(activeSalesStreamProvider);
    final salesSummary = ref.watch(salesSummaryProvider).value ?? SalesSummary.zero;

    final businessName = (user != null && user.businessName.trim().isNotEmpty)
        ? user.businessName
        : context.tr('የእኔ መለዋወጫ መደብር', 'My Spare Parts Store');
    final metrics = metricsAsync.value;
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;
    final totalSales = salesSummary.totalRevenue;
    final estimatedProfit = salesSummary.totalProfit;
    final salesCount = salesSummary.salesCount;
    final costAmount = (totalSales - estimatedProfit).clamp(0.0, double.infinity);

    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Deep Navy Shared Fixed Header (1 Dashboard.png)
          DashboardHeaderBar(
            title: businessName,
            subtitle: context.tr('የባለቤት መቆጣጠሪያ • ዳሽቦርድ', 'Owner Dashboard'),
            searchHint: context.tr('ዕቃ በስም ወይም በቁጥር ይፈልጉ', 'Search part by name or number'),
            onSearchTap: () => widget.onSwitchToInventory?.call(),
          ),

          // 2. Scrollable Dashboard Body
          Expanded(
            child: RefreshIndicator(
              color: AdminColors.keraOrange,
              onRefresh: () async {
                ref.invalidate(partsStreamProvider);
                ref.invalidate(salesSummaryProvider);
                ref.invalidate(activeSalesStreamProvider);
                ref.invalidate(pendingSyncCountProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              // 2. Post-Login Welcome Card (Issue 8)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102138) : AdminColors.headerNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E385C) : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    KeraAvatarWidget(
                      photoUrl: user?.avatarUrl,
                      name: user?.businessName ?? 'Owner',
                      radius: 24,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    // Greeting & Business Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getTimeGreeting(context)} 👋',
                            style: const TextStyle(
                              color: Color(0xFFA5B4CB),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            businessName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Live Sync Indicator Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pendingSync == 0
                            ? (isDark ? const Color(0xFF102138) : KeraColors.navy100)
                            : KeraColors.orange100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pendingSync == 0
                              ? (isDark ? const Color(0xFF1E385C) : KeraColors.border)
                              : KeraColors.orange500,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pendingSync == 0
                                ? Icons.check_circle_rounded
                                : Icons.access_time_rounded,
                            size: 13,
                            color: pendingSync == 0
                                ? (isDark ? Colors.white : KeraColors.navy800)
                                : KeraColors.orange700,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            pendingSync == 0
                                ? context.tr('ተመሳስሏል', 'Synced')
                                : '$pendingSync ${context.tr("በመጠባበቅ", "Pending")}',
                            style: TextStyle(
                              color: pendingSync == 0
                                  ? (isDark ? Colors.white : KeraColors.navy800)
                                  : KeraColors.orange700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Time selector tabs: ዛሬ, ይህ ሳምንት, ይህ ወር
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    _buildTimeTab(0, context.tr('ዛሬ', 'Today')),
                    const SizedBox(width: 24),
                    _buildTimeTab(1, context.tr('ይህ ሳምንት', 'This Week')),
                    const SizedBox(width: 24),
                    _buildTimeTab(2, context.tr('ይህ ወር', 'This Month')),
                  ],
                ),
              ),
              Divider(height: 16, color: context.borderColor),

              // 4. Sales & Profit Highlights Row (1 Dashboard.png)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Sales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('ጠቅላላ ሽያጭ', 'Total Sales'),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatNumber(totalSales),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ETB',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              '$salesCount ሽያጮች · የግዢ ወጪ ${_formatNumber(costAmount)} ETB',
                              '$salesCount sales · Cost ${_formatNumber(costAmount)} ETB',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estimated Profit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('የሚገመት ትርፍ', 'Estimated Profit'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '+${_formatNumber(estimatedProfit)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.brandOrange,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const TextSpan(
                                text: ' ETB',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.brandOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. 6 Action Buttons Grid (1 Dashboard.png)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Button 1: Primary Orange "ሽያጭ መመዝገብ"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.receipt_long_rounded,
                            label: context.tr('ሽያጭ መመዝገብ', 'Record Sale'),
                            isPrimary: true,
                            onTap: () => context.push('/sales/new'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 2: "ዕቃዎች"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.inventory_2_outlined,
                            label: context.tr('ዕቃዎች', 'Inventory'),
                            isPrimary: false,
                            onTap: () => widget.onSwitchToInventory?.call(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 3: "ዕቃ መጨመር"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.add_rounded,
                            label: context.tr('ዕቃ መጨመር', 'Add Part'),
                            isPrimary: false,
                            onTap: () => context.push('/parts/add'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Button 4: "ክምችት ማስተካከል"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.swap_vert_rounded,
                            label: context.tr('ክምችት ማስተካከል', 'Stock Levels'),
                            isPrimary: false,
                            onTap: () => context.push('/stock/low'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 5: "የሽያጭ ታሪክ"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.history_rounded,
                            label: context.tr('የሽያጭ ታሪክ', 'Sales History'),
                            isPrimary: false,
                            onTap: () => widget.onSwitchToSales?.call(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 6: "ሪፖርት"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.bar_chart_rounded,
                            label: context.tr('ሪፖርት', 'Reports'),
                            isPrimary: false,
                            onTap: () {
                              if (widget.onSwitchToReports != null) {
                                widget.onSwitchToReports!();
                              } else {
                                context.push('/reports');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Low Stock Alert Banner Card (1 Dashboard.png)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => context.push('/stock/low'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF102138) : KeraColors.orange100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? KeraColors.orange700 : KeraColors.brandOrange,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                '${metrics?.lowStockCount ?? 0} ዕቃዎች ሊያልቅ ነው',
                                '${metrics?.lowStockCount ?? 0} items running low',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : KeraColors.navy900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                '${metrics?.outOfStockCount ?? 0} ዕቃዎች አልቀዋል',
                                '${metrics?.outOfStockCount ?? 0} items out of stock',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: KeraColors.orange700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: KeraColors.orange700,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Recent Sales List Card (1 Dashboard.png)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060C2340),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('የቅርብ ሽያጮች', 'Recent Sales'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onSwitchToSales?.call(),
                            child: Text(
                              context.tr('ሁሉንም አሳይ', 'View All'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.keraOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      recentSalesAsync.when(
                        data: (sales) {
                          if (sales.isEmpty) {
                            return _buildEmptySalesList(context);
                          }
                          final recent = sales.take(3).toList();
                          return Column(
                            children: [
                              for (int i = 0; i < recent.length; i++) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        recent[i].items.isNotEmpty
                                            ? recent[i].items.first.partNameSnapshot
                                            : context.tr('ሽያጭ', 'Sale'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${_formatNumber(recent[i].totalAmount)} ETB',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (i != recent.length - 1)
                                  Divider(height: 18, color: context.borderColor),
                              ],
                            ],
                          );
                        },
                        loading: () => Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: KeraLoadingIndicator(
                              message: context.tr('ሽያጮችን በመጫን ላይ...', 'Loading sales...'),
                            ),
                          ),
                        ),
                        error: (err, stack) => _buildEmptySalesList(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const KeraAppFooter(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ],
),
);
}

  Widget _buildTimeTab(int index, String label) {
    final isSelected = _selectedPeriod == index;
    final isDark = context.isDark;
    return InkWell(
      onTap: () => _onPeriodChanged(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0C2340))
                  : context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 28,
            decoration: BoxDecoration(
              color: isSelected ? AdminColors.keraOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    final nonPrimaryBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final nonPrimaryText = isDark ? Colors.white : const Color(0xFF0C2340);
    final nonPrimaryBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5EBF2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AdminColors.keraOrange : nonPrimaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AdminColors.keraOrange : nonPrimaryBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AdminColors.keraOrange.withValues(alpha: 0.25)
                  : const Color(0x060C2340),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary ? KeraColors.navy900 : nonPrimaryText,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? KeraColors.navy900 : nonPrimaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySalesList(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 36, color: context.textSecondaryColor),
            const SizedBox(height: 8),
            Text(
              context.tr('እስካሁን ምንም ሽያጭ አልተመዘገበም', 'No sales recorded yet'),
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => context.push('/sales/new'),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(context.tr('የመጀመሪያ ሽያጭ መዝግብ', 'Record First Sale')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.keraOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(num value) {
    final s = value.round().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
