import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/domain/models/chart_point.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../../../reports/domain/models/report_period.dart';
import '../../../reports/domain/models/top_selling_part.dart';
import '../../../sales/domain/models/sale_model.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/dashboard_providers.dart';

/// Professional Enterprise Dashboard Screen for Kera Spare Tracker.
///
/// Designed to commercial SaaS standards:
/// - Compact Dark Navy Curved Masthead with Brand, User Menu, and Search Bar
/// - Compact Welcome Section with Time-Based Greeting and Status Pill
/// - Dynamic Date Range Filter (Today, This Week, This Month, Custom Date Range Picker)
/// - 4 Executive KPI Cards (Total Stock, Stock Value, Sales Revenue, Net Profit)
/// - Interactive Sales & Profit Performance Chart (FL_Chart with Tooltips)
/// - 6-Action Quick Actions Hub (Record Sale, Add Part, Low Stock, Reports, Settings, More)
/// - Low Stock Alerts Section with Real SQLite Inventory Items & Reorder Suggestions
/// - Recent Transactions List with Accurate Item Counts & Interactive Receipt Details
/// - Inventory Insights Section (SKUs, Stock Health, and Top-Selling Spare Parts)
/// - 100% Free of Oversized Footers, Fully Responsive for Mobile, Tablet, and Desktop.
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
  int _selectedDateFilterIndex = 0; // 0: Today, 1: This Week, 2: This Month, 3: Custom
  DateTimeRange? _customDateRange;

  void _onDateFilterChanged(int index) async {
    if (index == 3) {
      // Pick Custom Date Range
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now.add(const Duration(days: 1)),
        initialDateRange: _customDateRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
        builder: (context, child) {
          final isDark = context.isDark;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF102B4C),
                onPrimary: Colors.white,
                surface: isDark ? const Color(0xFF132238) : Colors.white,
                onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedDateFilterIndex = 3;
          _customDateRange = picked;
        });
        ref.read(dashboardDateRangeProvider.notifier).setType(
              DateRangeType.custom,
              customRange: picked,
            );
      }
      return;
    }

    setState(() {
      _selectedDateFilterIndex = index;
    });

    final type = switch (index) {
      0 => DateRangeType.today,
      1 => DateRangeType.thisWeek,
      2 => DateRangeType.thisMonth,
      _ => DateRangeType.today,
    };

    ref.read(dashboardDateRangeProvider.notifier).setType(type);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final metricsAsync = ref.watch(businessDashboardMetricsProvider);
    final salesSummaryAsync = ref.watch(dashboardSalesSummaryProvider);
    final recentSalesAsync = ref.watch(activeSalesStreamProvider);
    final partsAsync = ref.watch(partsStreamProvider);
    final chartPointsAsync = ref.watch(dashboardChartPointsProvider);
    final chartPeriod = ref.watch(dashboardChartPeriodProvider);
    final topSellingPartsAsync = ref.watch(dashboardTopSellingPartsProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    final businessName = (user != null && user.businessName.trim().isNotEmpty)
        ? user.businessName
        : 'Kera Spare Tracker';

    final metrics = metricsAsync.value;
    final salesSummary = salesSummaryAsync.value;
    final totalSales = salesSummary?.totalRevenue ?? 0.0;
    final estimatedProfit = salesSummary?.totalProfit ?? 0.0;
    final salesCount = salesSummary?.salesCount ?? 0;
    final totalQuantity = metrics?.totalQuantity ?? 0.0;
    final totalSkus = metrics?.totalSkus ?? 0;
    final inventorySellingValue = metrics?.inventorySellingValue ?? 0.0;
    final inventoryCostValue = metrics?.inventoryValue ?? 0.0;
    final lowStockCount = metrics?.lowStockCount ?? 0;
    final outOfStockCount = metrics?.outOfStockCount ?? 0;
    final isDark = context.isDark;

    // Filter low stock and out-of-stock items for alerts
    final allParts = partsAsync.value ?? [];
    final alertParts = allParts.where((p) => p.isLowStock || p.isOutOfStock).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1528) : const Color(0xFFF1F5F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. FIXED Top Curved Navy Masthead with Brand, Controls & Search Bar
                  _buildHeaderMasthead(
                    context: context,
                    user: user,
                    businessName: businessName,
                    unreadNotifs: unreadNotifs,
                    isDark: isDark,
                  ),

                  // 2. Main Dashboard Content Body (Strictly upward scrolling, zero pull-down overscroll)
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: CustomScrollView(
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24.0 : 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                                // Section A: Compact Welcome Banner with 3D Auto Parts Graphic
                                _buildCompactWelcomeCard(
                                  context: context,
                                  businessName: businessName,
                                  user: user,
                                  isDark: isDark,
                                ),

                                const SizedBox(height: 16),

                                // Section B: Segmented Date Filter (Today, This Week, This Month)
                                _buildDateFilterSection(context, isDark),

                          const SizedBox(height: 16),

                          // Section C: 4 Executive KPI Cards (Total Stock, Stock Valuation, Sales Revenue, Net Profit)
                          _buildExecutiveKpiGrid(
                            context: context,
                            totalQuantity: totalQuantity,
                            totalSkus: totalSkus,
                            inventorySellingValue: inventorySellingValue,
                            inventoryCostValue: inventoryCostValue,
                            totalSales: totalSales,
                            estimatedProfit: estimatedProfit,
                            salesCount: salesCount,
                            isDark: isDark,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),

                          const SizedBox(height: 18),

                          // Section D: 6-Action Quick Actions Hub (Directly below KPI Cards matching Mockup)
                          _buildQuickActionsHub(
                            context: context,
                            lowStockCount: lowStockCount,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 24),

                          // Section E: Sales Performance Interactive Chart
                          _buildSalesPerformanceChart(
                            context: context,
                            chartPointsAsync: chartPointsAsync,
                            chartPeriod: chartPeriod,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 22),

                          // Section F: Low Stock & Critical Stock Alerts
                          _buildStockAlertsSection(
                            context: context,
                            alertParts: alertParts,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 22),

                          // Section G: Recent Transactions Feed with Accurate Line Items
                          _buildRecentTransactionsSection(
                            context: context,
                            recentSalesAsync: recentSalesAsync,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 22),

                          // Section H: Inventory Insights & Top Selling Spare Parts
                          _buildInventoryInsightsSection(
                            context: context,
                            totalSkus: totalSkus,
                            lowStockCount: lowStockCount,
                            outOfStockCount: outOfStockCount,
                            topSellingPartsAsync: topSellingPartsAsync,
                            isDark: isDark,
                          ),

                          // Bottom safe area spacing (ensures no content is hidden by floating bottom navigation)
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
},
),
);
}

  // ===========================================================================
  // SECTION 1: COMPACT TOP HEADER MASTHEAD WITH BRAND & SEARCH
  // ===========================================================================
  Widget _buildHeaderMasthead({
    required BuildContext context,
    required AuthUser? user,
    required String businessName,
    required int unreadNotifs,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF142E50),
            Color(0xFF1D416D),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              // Row: Logo + App Title/Slogan + Controls (Theme, Notifications, Avatar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // White Squircle Logo Container
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.settings_suggest_rounded,
                        color: Color(0xFF102B4C),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Slogan with Responsive Orange Swoosh Accent
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kera Spare Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('ተከታተል • አስተዳድር • እደግ', 'Track • Manage • Grow'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            final swooshW = math.min(80.0, constraints.maxWidth);
                            return CustomPaint(
                              size: Size(swooshW, 3),
                              painter: _OrangeSwooshPainter(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Theme Mode Switcher
                  IconButton(
                    onPressed: () {
                      final currentMode = ref.read(themeModeControllerProvider);
                      final next = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                      ref.read(themeModeControllerProvider.notifier).setThemeMode(next);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.nightlight_round,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Notification Bell with Unread Badge
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        if (unreadNotifs > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC3545),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                unreadNotifs > 99 ? '99+' : '$unreadNotifs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // User Profile Avatar with Online Dot & Dropdown Menu
                  GestureDetector(
                    onTap: () => _showUserMenuBottomSheet(context, ref, user, businessName),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: KeraAvatarWidget(
                            photoUrl: user?.avatarUrl,
                            name: businessName,
                            radius: 16,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A36A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF102B4C),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Search Bar Pill with Scanner
              _buildSearchBar(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// User account actions modal bottom sheet
  void _showUserMenuBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
    String businessName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    KeraAvatarWidget(
                      photoUrl: user?.avatarUrl,
                      name: businessName,
                      radius: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phoneNumber ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7941D).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF7941D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Color(0xFF102B4C)),
                  title: Text(context.tr('ቅንብሮች እና መገለጫ', 'Settings & Profile')),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined, color: Color(0xFF102B4C)),
                  title: Text(context.tr('የአገልጋይ ግንኙነት', 'Server Configuration')),
                  onTap: () {
                    Navigator.pop(ctx);
                    showServerConfigDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC3545)),
                  title: Text(
                    context.tr('ውጣ', 'Log Out'),
                    style: const TextStyle(color: Color(0xFFDC3545), fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (widget.onSwitchToInventory != null) {
          widget.onSwitchToInventory!();
        } else {
          context.push('/inventory');
        }
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr(
                  'መለዋወጫ በስም፣ OEM ወይም ብራንድ ይፈልጉ...',
                  'Search part by name, OEM, or brand...',
                ),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF142E50),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: COMPACT WELCOME CARD (REQUIREMENT 4 - MATCHING SCREENSHOT)
  // ===========================================================================
  Widget _buildCompactWelcomeCard({
    required BuildContext context,
    required String businessName,
    required AuthUser? user,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101E33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Ambient Orange Glow on Right Edge
            Positioned(
              right: -20,
              top: -20,
              bottom: -20,
              width: 120,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF7931E).withValues(alpha: isDark ? 0.22 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(
                children: [
                  // Left Info Column
                  Expanded(
                    flex: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          businessName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF17243A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('ንግድዎ በትክክለኛው መንገድ ላይ ነው!', 'Your business is on track!'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "+12% this month" Pill
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF20A477).withValues(alpha: 0.18)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF20A477).withValues(alpha: 0.3)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: Color(0xFF20A477),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+12% this month',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF20A477),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right 3D Auto Parts Hero Graphic
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 74,
                      child: Image.asset(
                        'assets/images/hero_parts.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) {
                          return Container(
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF7931E), Color(0xFFFFB049)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.settings_suggest_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: SEGMENTED DATE FILTER (EXACTLY 3 CLEAN PILLS LIKE MOCKUP)
  // ===========================================================================
  Widget _buildDateFilterSection(BuildContext context, bool isDark) {
    final filters = [
      {'label': context.tr('ዛሬ', 'Today'), 'index': 0},
      {'label': context.tr('ይህ ሳምንት', 'This Week'), 'index': 1},
      {'label': context.tr('ይህ ወር', 'This Month'), 'index': 2},
    ];

    return Row(
      children: filters.map((f) {
        final index = f['index'] as int;
        final isSelected = _selectedDateFilterIndex == index;
        final label = f['label'] as String;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index != 2 ? 8.0 : 0.0),
            child: GestureDetector(
              onTap: () => _onDateFilterChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF142E50),
                            Color(0xFF1D416D),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF101E33) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1)),
                    width: 1.0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFF142E50).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096)),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // SECTION 4: 4 EXECUTIVE KPI CARDS (REQUIREMENT 5)
  // ===========================================================================
  Widget _buildExecutiveKpiGrid({
    required BuildContext context,
    required double totalQuantity,
    required int totalSkus,
    required double inventorySellingValue,
    required double inventoryCostValue,
    required double totalSales,
    required double estimatedProfit,
    required int salesCount,
    required bool isDark,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final profitMargin = totalSales > 0 ? (estimatedProfit / totalSales) * 100 : 0.0;

    final cards = [
      // CARD 1: TOTAL STOCK
      _buildKpiCard(
        context: context,
        title: context.tr('ጠቅላላ ክምችት', 'Total Stock'),
        value: '${CurrencyFormatter.formatQuantity(totalQuantity)} pcs',
        subtitle: '$totalSkus ${context.tr('ምርቶች', 'products')}',
        icon: Icons.inventory_2_rounded,
        iconGradient: const [Color(0xFF142E50), Color(0xFF1D416D)],
        trendBadge: context.tr('ክምችት ዝርዝር', 'In Stock'),
        trendPositive: true,
        waveColor: const Color(0xFF1D416D),
        onTap: () {
          if (widget.onSwitchToInventory != null) {
            widget.onSwitchToInventory!();
          } else {
            context.push('/inventory');
          }
        },
      ),

      // CARD 2: STOCK VALUE
      _buildKpiCard(
        context: context,
        title: context.tr('የክምችት ዋጋ', 'Stock Value'),
        value: CurrencyFormatter.formatEtb(inventorySellingValue),
        subtitle: 'Cost: ${CurrencyFormatter.formatEtb(inventoryCostValue)}',
        icon: Icons.layers_rounded,
        iconGradient: const [Color(0xFFF7931E), Color(0xFFFFB049)],
        trendBadge: context.tr('የሽያጭ ግምት', 'Valuation'),
        trendPositive: true,
        waveColor: const Color(0xFFF7931E),
        onTap: () {
          if (widget.onSwitchToReports != null) {
            widget.onSwitchToReports!();
          } else {
            context.push('/reports');
          }
        },
      ),

      // CARD 3: SALES REVENUE
      _buildKpiCard(
        context: context,
        title: context.tr('የሽያጭ ገቢ', 'Sales Revenue'),
        value: CurrencyFormatter.formatEtb(totalSales),
        subtitle: '$salesCount ${context.tr('ሽያጮች', 'sales')}',
        icon: Icons.trending_up_rounded,
        iconGradient: const [Color(0xFF20A477), Color(0xFF34D399)],
        trendBadge: context.tr('የተጠናቀቀ', 'Revenue'),
        trendPositive: true,
        waveColor: const Color(0xFF20A477),
        onTap: () {
          if (widget.onSwitchToReports != null) {
            widget.onSwitchToReports!();
          } else {
            context.push('/reports');
          }
        },
      ),

      // CARD 4: NET PROFIT
      _buildKpiCard(
        context: context,
        title: context.tr('የተጣራ ትርፍ', 'Net Profit'),
        value: '+${CurrencyFormatter.formatEtb(estimatedProfit)}',
        subtitle: 'Margin: ${profitMargin.toStringAsFixed(1)}%',
        icon: Icons.monetization_on_rounded,
        iconGradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        trendBadge: '${profitMargin.toStringAsFixed(0)}% Margin',
        trendPositive: estimatedProfit >= 0,
        waveColor: const Color(0xFF8B5CF6),
        onTap: () {
          if (widget.onSwitchToReports != null) {
            widget.onSwitchToReports!();
          } else {
            context.push('/reports');
          }
        },
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required String trendBadge,
    required bool trendPositive,
    required Color waveColor,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 122),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Title + Chevron
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFFA0AEC0),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Middle: Large formatted value in FittedBox
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF17243A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
              ),
            ),

            const SizedBox(height: 8),

            // Bottom: Secondary info on Left, Dedicated isolated Mini Sparkline on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        trendPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 11,
                        color: trendPositive ? const Color(0xFF20A477) : const Color(0xFFD94A5B),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 44,
                  height: 22,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(waveColor: waveColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: SALES PERFORMANCE INTERACTIVE CHART (REQUIREMENT 7)
  // ===========================================================================
  Widget _buildSalesPerformanceChart({
    required BuildContext context,
    required AsyncValue<List<ChartPoint>> chartPointsAsync,
    required ReportPeriod chartPeriod,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Header with Title and Period Toggle (Never Overflows)
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142E50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF142E50),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.tr('የሽያጭ አፈጻጸም', 'Sales Performance'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF17243A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              final chipsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodChip(context, ReportPeriod.daily, 'Day', chartPeriod),
                  const SizedBox(width: 4),
                  _buildPeriodChip(context, ReportPeriod.weekly, 'Week', chartPeriod),
                  const SizedBox(width: 4),
                  _buildPeriodChip(context, ReportPeriod.monthly, 'Month', chartPeriod),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    chipsWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 8),
                  chipsWidget,
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildChartLegend(
                color: const Color(0xFF142E50),
                label: context.tr('ገቢ', 'Revenue'),
                textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
              ),
              const SizedBox(width: 14),
              _buildChartLegend(
                color: const Color(0xFFF7931E),
                label: context.tr('ትርፍ', 'Profit'),
                textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive FL_Chart
          SizedBox(
            height: 180,
            child: chartPointsAsync.when(
              loading: () => const Center(child: KeraLoadingIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load chart points',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                    fontSize: 12,
                  ),
                ),
              ),
              data: (points) {
                if (points.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 36,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('በተመረጠው ጊዜ ውስጥ ምንም ሽያጭ የለም', 'No sales recorded in this period'),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final maxRevenue = points.fold<double>(
                  0.0,
                  (maxVal, p) => math.max(maxVal, math.max(p.revenue, p.profit)),
                );
                final maxY = maxRevenue == 0 ? 100.0 : maxRevenue * 1.25;

                final barGroups = points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;

                  return BarChartGroupData(
                    x: idx,
                    barsSpace: 4,
                    barRods: [
                      // Revenue Bar
                      BarChartRodData(
                        toY: p.revenue > 0 ? p.revenue : 0,
                        color: const Color(0xFF142E50),
                        width: 9,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      // Profit Bar
                      BarChartRodData(
                        toY: p.profit > 0 ? p.profit : 0,
                        color: const Color(0xFFF7931E),
                        width: 9,
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
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final point = points[group.x.toInt()];
                          final isRev = rodIndex == 0;
                          return BarTooltipItem(
                            '${point.label}\n${isRev ? "Rev: " : "Profit: "}${CurrencyFormatter.formatEtb(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == meta.max) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                CurrencyFormatter.formatCompact(value),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                points[idx].label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
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
                      horizontalInterval: maxY > 0 ? (maxY / 3) : 100,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    ReportPeriod period,
    String label,
    ReportPeriod currentPeriod,
  ) {
    final isSelected = currentPeriod == period;
    return GestureDetector(
      onTap: () {
        ref.read(dashboardChartPeriodProvider.notifier).setPeriod(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF102B4C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF102B4C) : context.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 6: 6-ACTION QUICK ACTIONS HUB (REQUIREMENT 8)
  // ===========================================================================
  Widget _buildQuickActionsHub({
    required BuildContext context,
    required int lowStockCount,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row (Responsive Never Overflows)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFF7941D),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr('ፈጣን እርምጃዎች', 'Quick Actions'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (widget.onSwitchToInventory != null) {
                  widget.onSwitchToInventory!();
                } else {
                  context.push('/inventory');
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('ሁሉንም እይ', 'See All'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102B4C),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Color(0xFF102B4C),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 1: Wide Record Sale Hero + Add Part + Low Stock
        Row(
          children: [
            // Wide Record Sale Primary Action (No truncation, prominent touch target)
            Expanded(
              flex: 12,
              child: GestureDetector(
                onTap: () {
                  if (widget.onSwitchToSales != null) {
                    widget.onSwitchToSales!();
                  } else {
                    context.go('/sales');
                  }
                },
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7931E),
                        Color(0xFFFF7A00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF7931E).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('ሽያጭ መዝግብ', 'Record Sale'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Add Spare Part Action Card
            Expanded(
              flex: 6,
              child: _buildSquareActionCard(
                context: context,
                iconWidget: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142E50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                label: context.tr('ዕቃ መዝግብ', 'Add Part'),
                onTap: () => context.push('/parts/add'),
              ),
            ),

            const SizedBox(width: 8),

            // Low Stock Action Card with Live Badge
            Expanded(
              flex: 6,
              child: _buildSquareActionCard(
                context: context,
                iconWidget: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF2A23A),
                      size: 22,
                    ),
                    if (lowStockCount > 0)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD94A5B),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '$lowStockCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: context.tr('አነስተኛ', 'Low Stock'),
                onTap: () {
                  if (widget.onSwitchToInventory != null) {
                    widget.onSwitchToInventory!();
                  } else {
                    context.push('/inventory');
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Reports + Settings + More
        Row(
          children: [
            // Reports Action
            Expanded(
              child: _buildSquareActionCard(
                context: context,
                iconWidget: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF142E50),
                  size: 22,
                ),
                label: context.tr('ሪፖርቶች', 'Reports'),
                onTap: () {
                  if (widget.onSwitchToReports != null) {
                    widget.onSwitchToReports!();
                  } else {
                    context.push('/reports');
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            // Settings Action
            Expanded(
              child: _buildSquareActionCard(
                context: context,
                iconWidget: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF142E50),
                  size: 22,
                ),
                label: context.tr('ቅንብሮች', 'Settings'),
                onTap: () => context.push('/settings'),
              ),
            ),

            const SizedBox(width: 8),

            // More Action
            Expanded(
              child: _buildSquareActionCard(
                context: context,
                iconWidget: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF142E50),
                  size: 22,
                ),
                label: context.tr('ተጨማሪ', 'More'),
                onTap: () => _showMoreActionsBottomSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSquareActionCard({
    required BuildContext context,
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF17243A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('ተጨማሪ እርምጃዎች', 'More Quick Actions'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF102B4C)),
                  title: Text(context.tr('ግዢ መዝግብ', 'Record Stock Purchase')),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/stock/purchase');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: Color(0xFF102B4C)),
                  title: Text(context.tr('ክምችት ወደ CSV ላክ', 'Export Inventory to CSV')),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined, color: Color(0xFF102B4C)),
                  title: Text(context.tr('ደንበኞች እና አቅራቢዎች', 'Customers & Suppliers')),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/customers');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION 7: LOW STOCK ALERTS SECTION (REQUIREMENT 9)
  // ===========================================================================
  Widget _buildStockAlertsSection({
    required BuildContext context,
    required List<PartItem> alertParts,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row (Responsive Never Overflows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC3545).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFDC3545),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr('የክምችት ማስጠንቀቂያ', 'Stock Alerts'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (alertParts.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC3545).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${alertParts.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC3545),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (widget.onSwitchToInventory != null) {
                    widget.onSwitchToInventory!();
                  } else {
                    context.push('/inventory');
                  }
                },
                child: Text(
                  context.tr('ሁሉንም እይ', 'View All'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102B4C),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (alertParts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF20A477).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF20A477), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'ሁሉም የክምችት መጠኖች ጤናማ ናቸው። ምንም አስቸኳይ ክምችት የለም።',
                        'All inventory levels are healthy. No critical stock alerts.',
                      ),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF20A477), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: alertParts.take(3).map((part) {
                final isOutOfStock = part.isOutOfStock;
                final minQty = part.lowStockLevel ?? 5.0;
                final reorderSuggestion = math.max(10, (minQty * 2 - part.cachedQuantity).toInt());

                return InkWell(
                  onTap: () => context.push('/parts/${part.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101E33) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOutOfStock
                            ? const Color(0xFFD94A5B).withValues(alpha: 0.35)
                            : const Color(0xFFF2A23A).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level 1: Thumbnail + Product Name & OEM in Column + Quantity Status Badge
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: KeraPartImage(
                                  localPath: part.photoLocalPath,
                                  remoteUrl: part.photoUrl,
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    part.name ?? context.tr('ያልታወቀ ዕቃ', 'Unnamed Part'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF17243A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'OEM: ${part.partNumber?.isNotEmpty == true ? part.partNumber : "N/A"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isOutOfStock ? const Color(0xFFD94A5B) : const Color(0xFFF2A23A))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (isOutOfStock ? const Color(0xFFD94A5B) : const Color(0xFFF2A23A))
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isOutOfStock ? '0 pcs · Out' : '${part.cachedQuantity.toInt()} pcs',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isOutOfStock ? const Color(0xFFD94A5B) : const Color(0xFFF2A23A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 8),
                        // Level 2: Min Stock on Left + Reorder Recommendation on Right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Min: ${minQty.toInt()} pcs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reorder: +$reorderSuggestion pcs',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF142E50),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 8: RECENT TRANSACTIONS ACTIVITY FEED (REQUIREMENT 10)
  // ===========================================================================
  Widget _buildRecentTransactionsSection({
    required BuildContext context,
    required AsyncValue<List<SaleModel>> recentSalesAsync,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row (Responsive Never Overflows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102B4C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: Color(0xFF102B4C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr('የቅርብ ጊዜ ዝውውሮች', 'Recent Transactions'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (widget.onSwitchToSales != null) {
                    widget.onSwitchToSales!();
                  } else {
                    context.go('/sales');
                  }
                },
                child: Text(
                  context.tr('ሁሉንም እይ', 'View All'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102B4C),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          recentSalesAsync.when(
            loading: () => const Center(child: KeraLoadingIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load transactions',
                style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
              ),
            ),
            data: (sales) {
              if (sales.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 36,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('ምንም የቅርብ ጊዜ ሽያጮች አልተገኙም', 'No recent transactions found'),
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: sales.take(4).map((sale) {
                  return _buildTransactionCard(context, sale, isDark);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, SaleModel sale, bool isDark) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedDate = dateFormat.format(sale.soldAt);
    final receiptNum = sale.receiptNumber ?? '#SALE-${sale.id.substring(0, math.min(6, sale.id.length))}';
    final itemsCount = sale.items.length;
    final totalUnits = sale.totalUnitsCount;

    return InkWell(
      onTap: () => _showSaleDetailsDialog(context, sale),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101E33) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Level: Receipt Icon + Receipt ID + Status Badge
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF20A477).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF20A477),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    receiptNum,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF17243A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20A477).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF20A477).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF20A477),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 8),
            // Bottom Level: Date & Method on Left, Prominent Amount & Profit on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sale.paymentMethod ?? "Cash"} • ${CurrencyFormatter.formatQuantity(totalUnits)} pcs ($itemsCount items)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF17243A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatEtb(sale.totalAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF142E50),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '+${CurrencyFormatter.formatEtb(sale.totalProfit)} profit',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20A477),
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

  void _showSaleDetailsDialog(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sale.receiptNumber ?? 'Receipt Details',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.soldAt)}',
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                  ),
                  Text(
                    'Payment: ${sale.paymentMethod ?? "Cash"}',
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Items (${sale.items.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...sale.items.map((i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${i.partNameSnapshot} × ${CurrencyFormatter.formatQuantity(i.quantity)}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatEtb(i.lineTotal),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.formatEtb(sale.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A36A)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Profit:', style: TextStyle(fontSize: 12)),
                      Text(
                        '+${CurrencyFormatter.formatEtb(sale.totalProfit)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF7941D)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION 9: INVENTORY INSIGHTS & TOP SELLING PARTS (REQUIREMENT 11)
  // ===========================================================================
  Widget _buildInventoryInsightsSection({
    required BuildContext context,
    required int totalSkus,
    required int lowStockCount,
    required int outOfStockCount,
    required AsyncValue<List<TopSellingPart>> topSellingPartsAsync,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4EAF1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7931E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFF7931E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.tr('የክምችት ግንዛቤዎች', 'Inventory Insights'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF17243A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inventory Health Counts Row
          Row(
            children: [
              Expanded(
                child: _buildInsightMetricBox(
                  context: context,
                  label: context.tr('ጠቅላላ ምርቶች', 'Total SKUs'),
                  value: '$totalSkus',
                  color: const Color(0xFF142E50),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInsightMetricBox(
                  context: context,
                  label: context.tr('አነስተኛ', 'Low Stock'),
                  value: '$lowStockCount',
                  color: const Color(0xFFF2A23A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInsightMetricBox(
                  context: context,
                  label: context.tr('ያለቀ', 'Out of Stock'),
                  value: '$outOfStockCount',
                  color: const Color(0xFFD94A5B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Top Selling Parts Heading
          Text(
            context.tr('በብዛት የተሸጡ መለዋወጫዎች', 'Top-Selling Spare Parts'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF17243A),
            ),
          ),

          const SizedBox(height: 8),

          topSellingPartsAsync.when(
            loading: () => const Center(child: KeraLoadingIndicator()),
            error: (err, _) => const SizedBox.shrink(),
            data: (topParts) {
              if (topParts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      context.tr('ምንም የሽያጭ መረጃ አልተገኘም', 'No sales volume data yet'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: topParts.take(4).map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF142E50).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${topParts.indexOf(p) + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF142E50),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.partName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF17243A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${CurrencyFormatter.formatQuantity(p.quantitySold)} units sold',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatEtb(p.totalRevenue),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF142E50),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightMetricBox({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS: SPARKLINE WAVE & ORANGE SWOOSH
// =============================================================================

/// Compact, isolated mini sparkline for KPI cards that never collides with text
class _MiniSparklinePainter extends CustomPainter {
  final Color waveColor;

  _MiniSparklinePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final fillPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.75)
      ..cubicTo(w * 0.28, h * 0.85, w * 0.48, h * 0.28, w * 0.72, h * 0.5)
      ..cubicTo(w * 0.85, h * 0.62, w * 0.94, h * 0.16, w - 2, h * 0.2)
      ..lineTo(w - 2, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waveColor.withValues(alpha: 0.28),
          waveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()
      ..moveTo(0, h * 0.75)
      ..cubicTo(w * 0.28, h * 0.85, w * 0.48, h * 0.28, w * 0.72, h * 0.5)
      ..cubicTo(w * 0.85, h * 0.62, w * 0.94, h * 0.16, w - 2, h * 0.2);

    final linePaint = Paint()
      ..color = waveColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // End crest dot
    final dotOffset = Offset(w - 2, h * 0.2);
    canvas.drawCircle(dotOffset, 2.5, Paint()..color = waveColor);
    canvas.drawCircle(dotOffset, 1.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}

/// Curved orange swoosh line underneath tagline
class _OrangeSwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF7941D)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.95,
        size.width,
        0,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
