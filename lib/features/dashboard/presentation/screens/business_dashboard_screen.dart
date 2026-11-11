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
    final alertPartsCount = allParts.where((p) => p.isLowStock || p.isOutOfStock).length;
    final alertCount = lowStockCount > 0 ? lowStockCount : alertPartsCount;

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

                          // Section D: Quick Actions Hub (Record Sale, Add Product, Low Stock - Matching Figma)
                          _buildQuickActionsHub(
                            context: context,
                            lowStockCount: alertCount,
                            isDark: isDark,
                          ),

                          // Section E: Restocking Alert Banner (Matching Figma)
                          _buildRestockingAlertBanner(
                            context: context,
                            alertCount: alertCount,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 18),

                          // Section F: Recent Sales Activity Feed (Matching Figma)
                          _buildRecentTransactionsSection(
                            context: context,
                            recentSalesAsync: recentSalesAsync,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),

                          // Section G: Sales Performance Interactive Chart
                          _buildSalesPerformanceChart(
                            context: context,
                            chartPointsAsync: chartPointsAsync,
                            chartPeriod: chartPeriod,
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
    final initials = (businessName.trim().isNotEmpty)
        ? (businessName.trim().length >= 2
            ? businessName.trim().substring(0, 2).toUpperCase()
            : businessName.trim().toUpperCase())
        : 'HK';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF173655),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Row: Logo + App Title/Slogan + Controls (Theme, Notifications, Avatar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // White Squircle Logo Container
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.settings_suggest_rounded,
                        color: Color(0xFF173655),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Slogan matching Figma
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kera Spare Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track · Manage · Grow',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Theme Mode Switcher
                  GestureDetector(
                    onTap: () {
                      final currentMode = ref.read(themeModeControllerProvider);
                      final next = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                      ref.read(themeModeControllerProvider.notifier).setThemeMode(next);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell with Unread Badge
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadNotifs > 0 ? (unreadNotifs > 9 ? '9+' : '$unreadNotifs') : '1',
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
                  const SizedBox(width: 8),

                  // User Avatar Circle (Initials "HK" or profile image)
                  GestureDetector(
                    onTap: () => _showUserMenuBottomSheet(context, ref, user, businessName),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: KeraAvatarWidget(
                        photoUrl: user?.avatarUrl,
                        name: initials.isNotEmpty ? initials : 'HK',
                        radius: 17,
                        isDark: true,
                        backgroundColor: const Color(0xFF1E3A5F),
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr(
                  'መለዋወጫዎችን፣ OEM ወይም ብራንድ ይፈልጉ',
                  'Search parts, OEM or brand',
                ),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF173655),
              size: 22,
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
    final titleText = (businessName.trim().isNotEmpty && businessName != 'Kera Spare Tracker')
        ? businessName
        : context.tr('የባለቤት ዳሽቦርድ', 'Owner dashboard');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            // Left Info Column matching Figma
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('እንኳን ደህና መጡ', 'Welcome back · እንኳን ደህና መጡ'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 3),
                      Text(
                        '12% this month',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right 3D Auto Parts Graphic
            SizedBox(
              width: 86,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/hero_parts.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.settings_suggest_rounded,
                    color: Color(0xFFF7941D),
                    size: 36,
                  ),
                ),
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
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF173655)
                      : (isDark ? const Color(0xFF132238) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    width: 1.0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFF173655).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    final currencyFormatter = NumberFormat('#,##0.00');

    final cards = [
      // CARD 1: TOTAL STOCK
      _buildFigmaKpiCard(
        context: context,
        title: context.tr('ጠቅላላ ክምችት', 'Total stock'),
        value: '${totalQuantity.toInt()} pcs',
        subtitle: context.tr('$totalSkus ምርቶች', '$totalSkus products'),
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF1E3A8A),
        iconBgColor: const Color(0xFFEFF6FF),
        subtitleColor: const Color(0xFF10B981),
        isDark: isDark,
        onTap: () {
          if (widget.onSwitchToInventory != null) {
            widget.onSwitchToInventory!();
          } else {
            context.push('/inventory');
          }
        },
      ),

      // CARD 2: STOCK VALUE
      _buildFigmaKpiCard(
        context: context,
        title: context.tr('የክምችት ዋጋ', 'Stock value'),
        value: 'ETB ${currencyFormatter.format(inventorySellingValue)}',
        subtitle: context.tr('የሽያጭ ዋጋ ግምት', 'Inventory selling value'),
        icon: Icons.layers_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        subtitleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: isDark,
        onTap: () {
          if (widget.onSwitchToReports != null) {
            widget.onSwitchToReports!();
          } else {
            context.push('/reports');
          }
        },
      ),

      // CARD 3: SALES REVENUE
      _buildFigmaKpiCard(
        context: context,
        title: context.tr('የሽያጭ ገቢ', 'Sales revenue'),
        value: 'ETB ${currencyFormatter.format(totalSales)}',
        subtitle: context.tr('$salesCount ዛሬ የተሸጡ', '$salesCount sales today'),
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF059669),
        iconBgColor: const Color(0xFFECFDF5),
        subtitleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: isDark,
        onTap: () {
          if (widget.onSwitchToReports != null) {
            widget.onSwitchToReports!();
          } else {
            context.push('/reports');
          }
        },
      ),

      // CARD 4: NET PROFIT
      _buildFigmaKpiCard(
        context: context,
        title: context.tr('የተጣራ ትርፍ', 'Net profit'),
        value: 'ETB ${currencyFormatter.format(estimatedProfit)}',
        subtitle: 'Margin: ${profitMargin.toStringAsFixed(1)}%',
        icon: Icons.calculate_rounded,
        iconColor: const Color(0xFF059669),
        iconBgColor: const Color(0xFFECFDF5),
        subtitleColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        isDark: isDark,
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
        children: cards
            .map((c) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c)))
            .toList(),
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

  Widget _buildFigmaKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color subtitleColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 114),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132238) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
            width: 1.0,
          ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Tinted Squircle Icon + Label
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withValues(alpha: 0.2) : iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle / Trend
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        // Section Header Row: "Quick actions" + "See All"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('ፈጣን እርምጃዎች', 'Quick actions'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: () => _showMoreActionsBottomSheet(context),
              child: Text(
                context.tr('ሁሉንም እይ', 'See All'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3 Action Buttons in a Single Row matching Figma
        Row(
          children: [
            // 1. Record Sale (Solid Orange CTA)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onSwitchToSales != null) {
                    widget.onSwitchToSales!();
                  } else {
                    context.go('/sales');
                  }
                },
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7941D),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF7941D).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('ሽያጭ መዝግብ', 'Record Sale'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 2. Add Product (White Card)
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/parts/add'),
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132238) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('ምርት አክል', 'Add Product'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 3. Low Stock (White Card)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onSwitchToInventory != null) {
                    widget.onSwitchToInventory!();
                  } else {
                    context.push('/inventory?filter=low_stock');
                  }
                },
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132238) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('አነስተኛ ክምችት', 'Low Stock'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 7: RESTOCKING ALERT BANNER (MATCHING FIGMA)
  // ===========================================================================
  Widget _buildRestockingAlertBanner({
    required BuildContext context,
    required int alertCount,
    required bool isDark,
  }) {
    if (alertCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: () {
          if (widget.onSwitchToInventory != null) {
            widget.onSwitchToInventory!();
          } else {
            context.push('/inventory?filter=low_stock');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1E12) : const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF7C3E12) : const Color(0xFFFED7AA),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF9A3412),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(
                        '$alertCount ምርቶች መሟላት አለባቸው',
                        '$alertCount products need restocking',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('ዝቅተኛ ክምችት · ዝርዝሩን እይ', 'ዝቅተኛ ክምችት · View low stock'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9A3412),
                size: 20,
              ),
            ],
          ),
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
  // SECTION 8: RECENT TRANSACTIONS ACTIVITY FEED (REQUIREMENT 10)
  // ===========================================================================
  Widget _buildRecentTransactionsSection({
    required BuildContext context,
    required AsyncValue<List<SaleModel>> recentSalesAsync,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title Row matching Figma: "Recent sales" + "የቅርብ ሽያጮች"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('የቅርብ ሽያጮች', 'Recent sales'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              'የቅርብ ሽያጮች',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
              // Figma Empty State Card: "No sales recorded today / ገና ሽያጭ አልተመዘገበም"
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132238) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('ዛሬ የተመዘገበ ሽያጭ የለም', 'No sales recorded today'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ገና ሽያጭ አልተመዘገበም',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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


