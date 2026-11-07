import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/widgets/dashboard_header_bar.dart';
import '../../../../core/design/widgets/kera_app_footer.dart';
import '../../../../core/design/widgets/kera_status_badge.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/domain/models/report_period.dart';
import '../../../reports/domain/models/sales_summary.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../sales/domain/models/sale_model.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/dashboard_providers.dart';

/// Executive Business Dashboard Screen for Kera Spare Tracker.
///
/// Complete modern mobile redesign:
/// - Deep Navy Masthead with Store Identity, Live Sync, Notification Bell, Language & Theme toggles
/// - Executive KPI Bento Grid (Stock Count, Inventory Value, Sales Revenue, Net Profit)
/// - Segmented Time Filter (Today, This Week, This Month)
/// - High-Touch Quick Action Hub (Record Sale, Add Part, Stock/Purchases, Low Stock, Sales History, Reports)
/// - Inventory Health & Critical Stock Alert Banner
/// - Recent Activity / Transaction Feed with live sync status indicators
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

class _BusinessDashboardScreenState
    extends ConsumerState<BusinessDashboardScreen> {
  int _selectedPeriod = 0; // 0: Today, 1: This Week, 2: This Month

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
    final salesSummary =
        ref.watch(salesSummaryProvider).value ?? SalesSummary.zero;
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    final businessName = (user != null && user.businessName.trim().isNotEmpty)
        ? user.businessName
        : context.tr('የእኔ መለዋወጫ መደብር', 'My Spare Parts Store');
    final ownerPhone = (user != null && user.phoneNumber.trim().isNotEmpty)
        ? user.phoneNumber
        : context.tr('ባለቤት', 'Owner');

    final metrics = metricsAsync.value;
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;
    final totalSales = salesSummary.totalRevenue;
    final estimatedProfit = salesSummary.totalProfit;
    final salesCount = salesSummary.salesCount;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Executive Deep Navy Header Bar
          DashboardHeaderBar(
            title: businessName,
            subtitle: context.tr('የባለቤት መቆጣጠሪያ • ዳሽቦርድ', 'Owner Executive Dashboard'),
            searchHint: context.tr(
              'ዕቃ በስም፣ በቁጥር ወይም በብራንድ ይፈልጉ...',
              'Search part by name, OEM, or brand...',
            ),
            onSearchTap: () => widget.onSwitchToInventory?.call(),
            trailingAction: _buildNotificationButton(context, unreadNotifs),
          ),

          // 2. Scrollable Dashboard Body
          Expanded(
            child: RefreshIndicator(
              color: KeraColors.orange500,
              backgroundColor: context.cardBg,
              onRefresh: () async {
                ref.invalidate(partsStreamProvider);
                ref.invalidate(salesSummaryProvider);
                ref.invalidate(activeSalesStreamProvider);
                ref.invalidate(pendingSyncCountProvider);
                ref.invalidate(businessDashboardMetricsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile & Live Synchronization Hero Banner
                    _buildIdentityBanner(
                      context: context,
                      businessName: businessName,
                      ownerPhone: ownerPhone,
                      avatarUrl: user?.avatarUrl,
                      pendingSync: pendingSync,
                      isDark: isDark,
                    ),

                    // Segmented Time Filter Bar (Today / This Week / This Month)
                    _buildTimeFilterBar(context),

                    const SizedBox(height: 14),

                    // Executive KPI Bento Grid (4 Key Business Metrics)
                    _buildKpiBentoGrid(
                      context: context,
                      metrics: metrics,
                      totalSales: totalSales,
                      estimatedProfit: estimatedProfit,
                      salesCount: salesCount,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // High-Touch Quick Actions Hub (6 Key Operational Tasks)
                    _buildQuickActionHub(context, metrics),

                    const SizedBox(height: 16),

                    // Critical Inventory & Stock Health Alert Card
                    _buildStockAlertBanner(context, metrics, isDark),

                    const SizedBox(height: 18),

                    // Recent Activity & Transactions Feed
                    _buildRecentTransactionsSection(
                      context: context,
                      recentSalesAsync: recentSalesAsync,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Application Branding Footer
                    const KeraAppFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Notification Button ---
  Widget _buildNotificationButton(BuildContext context, int unreadCount) {
    return InkWell(
      onTap: () => context.push('/notifications'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: KeraColors.orange500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Profile & Live Sync Identity Card ---
  Widget _buildIdentityBanner({
    required BuildContext context,
    required String businessName,
    required String ownerPhone,
    required String? avatarUrl,
    required int pendingSync,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: const [KeraColors.shadowLevel1],
      ),
      child: Row(
        children: [
          // Owner Avatar with Accent Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: KeraColors.orange500, width: 2),
            ),
            child: KeraAvatarWidget(
              photoUrl: avatarUrl,
              name: businessName,
              radius: 22,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),

          // Greeting & Store Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimeGreeting(context),
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  businessName,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Live Synchronization Status Pill
          InkWell(
            onTap: () => context.push('/sync'),
            borderRadius: BorderRadius.circular(16),
            child: pendingSync == 0
                ? KeraStatusBadge.synced(label: context.tr('ተመሳስሏል', 'Synced'))
                : KeraStatusBadge.syncPending(
                    count: pendingSync,
                    defaultLabel: context.tr('በመጠባበቅ', 'Pending'),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Time Filter Bar ---
  Widget _buildTimeFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF102138) : const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTimePill(0, context.tr('ዛሬ', 'Today')),
            _buildTimePill(1, context.tr('ይህ ሳምንት', 'This Week')),
            _buildTimePill(2, context.tr('ይህ ወር', 'This Month')),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePill(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onPeriodChanged(index),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? KeraColors.navy800 : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- Executive KPI Bento Grid (4 Cards) ---
  Widget _buildKpiBentoGrid({
    required BuildContext context,
    required BusinessDashboardMetrics? metrics,
    required double totalSales,
    required double estimatedProfit,
    required int salesCount,
    required bool isDark,
  }) {
    final totalSkus = metrics?.totalSkus ?? 0;
    final totalQty = metrics?.totalQuantity ?? 0.0;
    final inventoryCost = metrics?.inventoryValue ?? 0.0;
    final inventoryRetail = metrics?.inventorySellingValue ?? 0.0;
    final profitMargin = metrics?.profitMargin ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Metric 1: Total Stock & SKUs
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  title: context.tr('ጠቅላላ ክምችት', 'Total Stock'),
                  primaryValue: '${totalQty.toStringAsFixed(totalQty % 1 == 0 ? 0 : 1)} ${context.tr("ፍሬ", "pcs")}',
                  secondaryValue: '$totalSkus ${context.tr("የተለያዩ ዕቃዎች", "SKUs")}',
                  icon: Icons.inventory_2_rounded,
                  iconBg: isDark ? const Color(0xFF1E385C) : const Color(0xFFE8EEF8),
                  iconColor: isDark ? Colors.white : KeraColors.navy800,
                  onTap: () => widget.onSwitchToInventory?.call(),
                ),
              ),
              const SizedBox(width: 12),

              // Metric 2: Inventory Valuation (Cost & Potential Retail)
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  title: context.tr('የክምችት ዋጋ', 'Stock Valuation'),
                  primaryValue: '${_formatNumber(inventoryCost)} ETB',
                  secondaryValue: '${context.tr("የሽያጭ", "Retail")}: ${_formatNumber(inventoryRetail)} ETB',
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: isDark ? const Color(0xFF332314) : KeraColors.orange100,
                  iconColor: KeraColors.orange500,
                  onTap: () => widget.onSwitchToReports?.call(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Metric 3: Sales Revenue in Period
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  title: context.tr('የሽያጭ ገቢ', 'Sales Revenue'),
                  primaryValue: '${_formatNumber(totalSales)} ETB',
                  secondaryValue: '$salesCount ${context.tr("ሽያጮች ተከናውነዋል", "Transactions")}',
                  icon: Icons.trending_up_rounded,
                  iconBg: isDark ? const Color(0xFF064E3B) : KeraColors.green50,
                  iconColor: KeraColors.green600,
                  onTap: () => widget.onSwitchToSales?.call(),
                ),
              ),
              const SizedBox(width: 12),

              // Metric 4: Net Profit & Margin in Period
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  title: context.tr('የተጣራ ትርፍ', 'Net Profit'),
                  primaryValue: '+${_formatNumber(estimatedProfit)} ETB',
                  secondaryValue: '${profitMargin.toStringAsFixed(1)}% ${context.tr("የትርፍ ህዳግ", "Margin")}',
                  icon: Icons.monetization_on_rounded,
                  iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  iconColor: KeraColors.green700,
                  onTap: () => widget.onSwitchToReports?.call(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: const [KeraColors.shadowLevel1],
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              primaryValue,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              secondaryValue,
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- High-Touch Quick Actions Hub (6 Items) ---
  Widget _buildQuickActionHub(
    BuildContext context,
    BusinessDashboardMetrics? metrics,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ፈጣን ተግባራት', 'Quick Actions'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Action 1: Record Sale (Primary Vibrant Orange Hero Card)
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('ሽያጭ መመዝገብ', 'Record Sale'),
                  icon: Icons.point_of_sale_rounded,
                  isHeroPrimary: true,
                  onTap: () => context.push('/sales/new'),
                ),
              ),
              const SizedBox(width: 10),
              // Action 2: Add New Part
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('ዕቃ መጨመር', 'Add Part'),
                  icon: Icons.add_box_rounded,
                  isHeroPrimary: false,
                  onTap: () => context.push('/parts/add'),
                ),
              ),
              const SizedBox(width: 10),
              // Action 3: Low Stock Management
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('አነስተኛ ክምችት', 'Low Stock'),
                  icon: Icons.warning_amber_rounded,
                  isHeroPrimary: false,
                  badgeCount: metrics?.lowStockCount,
                  onTap: () => context.push('/stock/low'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Action 4: Parts Catalog
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('የዕቃዎች ዝርዝር', 'Inventory'),
                  icon: Icons.inventory_2_outlined,
                  isHeroPrimary: false,
                  onTap: () => widget.onSwitchToInventory?.call(),
                ),
              ),
              const SizedBox(width: 10),
              // Action 5: Sales History
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('የሽያጭ ታሪክ', 'Sales Log'),
                  icon: Icons.receipt_long_rounded,
                  isHeroPrimary: false,
                  onTap: () => widget.onSwitchToSales?.call(),
                ),
              ),
              const SizedBox(width: 10),
              // Action 6: Financial Reports
              Expanded(
                child: _buildActionTile(
                  context: context,
                  label: context.tr('ሪፖርቶች', 'Reports'),
                  icon: Icons.bar_chart_rounded,
                  isHeroPrimary: false,
                  onTap: () => widget.onSwitchToReports?.call(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isHeroPrimary,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isHeroPrimary
              ? KeraColors.orange500
              : context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHeroPrimary ? KeraColors.orange500 : context.borderColor,
          ),
          boxShadow: [
            if (isHeroPrimary)
              BoxShadow(
                color: KeraColors.orange500.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            else
              KeraColors.shadowLevel1,
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isHeroPrimary
                      ? Colors.white
                      : (isDark ? Colors.white : KeraColors.navy800),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHeroPrimary
                        ? Colors.white
                        : context.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: 0,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: KeraColors.red600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Critical Inventory Health Alert Banner ---
  Widget _buildStockAlertBanner(
    BuildContext context,
    BusinessDashboardMetrics? metrics,
    bool isDark,
  ) {
    final lowStock = metrics?.lowStockCount ?? 0;
    final outOfStock = metrics?.outOfStockCount ?? 0;

    if (lowStock == 0 && outOfStock == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : KeraColors.green50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: KeraColors.green600,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(
                    'ክምችት በጥሩ ሁኔታ ላይ ነው · ሁሉም ዕቃዎች በበቂ ሁኔታ አሉ',
                    'Stock is healthy · All items are adequately stocked',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF6EE7B7) : KeraColors.green700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => context.push('/stock/low'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: outOfStock > 0 ? KeraColors.red500 : KeraColors.amber500,
            ),
            boxShadow: const [KeraColors.shadowLevel1],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: outOfStock > 0
                      ? (isDark ? const Color(0xFF450A0A) : KeraColors.red50)
                      : (isDark ? const Color(0xFF451A03) : KeraColors.amber50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  outOfStock > 0
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: outOfStock > 0 ? KeraColors.red600 : KeraColors.amber600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'የክምችት ማስጠንቀቂያ ($lowStock ሊያልቅ ነው • $outOfStock ያለቀ)',
                        'Stock Alert: $lowStock low • $outOfStock out of stock',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'ክምችት ለማስተካከል ወይም ተጨማሪ ለማዘዝ እዚህ ይጫኑ',
                        'Tap here to replenish stock or adjust thresholds',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KeraColors.orange500,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Recent Activity / Transactions Section ---
  Widget _buildRecentTransactionsSection({
    required BuildContext context,
    required AsyncValue<List<SaleModel>> recentSalesAsync,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
          boxShadow: const [KeraColors.shadowLevel1],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 19,
                      color: KeraColors.orange500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('የቅርብ ሽያጮች እና ግብይቶች', 'Recent Transactions'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => widget.onSwitchToSales?.call(),
                  child: Text(
                    context.tr('ሁሉንም አሳይ', 'View All'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: KeraColors.orange500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            recentSalesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return _buildEmptyTransactionsView(context);
                }
                final recent = sales.take(4).toList();

                return Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      _buildTransactionRow(context, recent[i]),
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
                    message: context.tr(
                      'ሽያጮችን በመጫን ላይ...',
                      'Loading transactions...',
                    ),
                  ),
                ),
              ),
              error: (err, stack) => _buildEmptyTransactionsView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, SaleModel sale) {
    final total = sale.totalAmount;
    final profit = sale.totalProfit;
    final receipt = sale.receiptNumber ?? 'KS-SALE';
    final itemsCount = sale.items.length;
    final firstItem = sale.items.isNotEmpty
        ? sale.items.first.partNameSnapshot
        : context.tr('የተለያዩ ዕቃዎች', 'Spare Parts');

    return InkWell(
      onTap: () => context.push('/sales/${sale.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            // Receipt Icon Bubble
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1E385C) : const Color(0xFFE8EEF8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_rounded,
                size: 19,
                color: KeraColors.navy800,
              ),
            ),
            const SizedBox(width: 12),

            // Item Name & Quantity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstItem,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#$receipt · $itemsCount ${context.tr("ዕቃዎች", "items")}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price & Profit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatNumber(total)} ETB',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      profit >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: profit >= 0
                          ? KeraColors.green600
                          : KeraColors.red600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${profit >= 0 ? "+" : ""}${_formatNumber(profit)} ETB',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: profit >= 0
                            ? KeraColors.green600
                            : KeraColors.red600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: context.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'እስካሁን የተመዘገበ ሽያጭ የለም',
                'No transactions recorded yet',
              ),
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => context.push('/sales/new'),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                context.tr('የመጀመሪያ ሽያጭ መዝግብ', 'Record First Sale'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KeraColors.orange500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
