import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_metric_tile.dart';

/// Admin Dashboard matching the finalized Figma Design Specification.
///
/// Features:
/// - Executive Navy Header with KS Avatar, App Title, Unread Notifications Bell,
///   Global Search pill with scanner icon, Theme Mode toggle, and Language selector sub-bar.
/// - Registered Owners Navy Overview Card with live count and weekly growth badge.
/// - 4 Responsive Quick Action buttons (Add Owner, Approvals, Brands, Backup).
/// - Platform Overview 2x3 Grid with 6 High-Contrast Metric Cards.
/// - Administration Modules Hub (Sales Analytics & Reports, Sync Queue & Conflict Monitor).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Executive Navy Admin Header
          _buildAdminHeader(context, ref),

          // 2. Scrollable Body
          Expanded(
            child: dashboardAsync.when(
              loading: () => KeraLoadingView(
                message: context.tr(
                  'የአድሚን ዳሽቦርድ በመጫን ላይ...',
                  'Loading Admin Dashboard...',
                ),
              ),
              error: (err, _) => Center(
                child: ErrorState(
                  message: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.refresh(adminDashboardProvider),
                ),
              ),
              data: (stats) => RefreshIndicator(
                color: AdminColors.primary,
                onRefresh: () async =>
                    ref.refresh(adminDashboardProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Registered Owners Navy Card
                      _buildRegisteredOwnersCard(context, stats),
                      const SizedBox(height: 14),

                      // B. 4 Quick Actions Row (Add Owner, Approvals, Brands, Backup)
                      _buildQuickActionsRow(context),
                      const SizedBox(height: 20),

                      // C. Platform Overview (6 Metric Cards Grid)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'የፕላትፎርም አጠቃላይ እይታ',
                                'Platform overview',
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPlatformOverviewGrid(context, stats),
                            const SizedBox(height: 24),

                            // D. Administration Modules Section
                            Text(
                              context.tr(
                                'አስተዳደራዊ ሞጁሎች',
                                'Administration Modules',
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAdministrationModulesCard(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Executive Navy Admin Header matching Figma
  Widget _buildAdminHeader(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isAmharic = context.isAmharic;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF071322) : const Color(0xFF173655),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Title & Subtitle + Notification Bell
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with KS initials and orange border matching Figma
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF102D55),
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminColors.keraOrange, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'KS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
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
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'አድሚን ኮንሶል · Admin Console',
                        'Admin Console · Manager',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFA5B4CB),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Notification Bell with Unread Dot
              InkWell(
                onTap: () => context.push('/admin/notifications'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AdminColors.keraOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Second Row: Search Capsule + Theme Mode Toggle
          Row(
            children: [
              // Search Capsule with Scanner Icon
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/admin/owners'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF718096),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(
                              'ፈልግ · Search owners, phones...',
                              'Search owners, phones...',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AdminColors.keraOrange,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Theme Mode Toggle Button
              InkWell(
                onTap: () {
                  final isDarkNow = context.isDark;
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(isDarkNow ? ThemeMode.light : ThemeMode.dark);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sub-bar Row: "ADMIN DASHBOARD" + Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(localeControllerProvider.notifier).toggleLocale();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'AM' : 'EN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // A. Registered Owners Navy Card
  Widget _buildRegisteredOwnersCard(BuildContext context, dynamic stats) {
    final totalOwners = stats.totalOwners;
    final newThisWeek = stats.newOwnersThisWeek;
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102138) : const Color(0xFF173655),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E385C) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ጠቅላላ የተመዘገቡ ባለቤቶች', 'Total Registered Owners'),
            style: const TextStyle(
              color: Color(0xFFA5B4CB),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$totalOwners',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AdminColors.keraOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+$newThisWeek ${context.tr("በዚህ ሳምንት", "this week")}',
                      style: const TextStyle(
                        color: AdminColors.keraOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // B. 4 Quick Actions Row (Add Owner, Approvals, Brands, Backup)
  Widget _buildQuickActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildQuickActionItem(
              context,
              icon: Icons.person_add_alt_1_rounded,
              label: context.tr('ባለቤት ጨምር', 'Add Owner'),
              isPrimaryOrange: true,
              onTap: () => context.push('/admin/owners/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildQuickActionItem(
              context,
              icon: Icons.sync_rounded,
              label: context.tr('ማጽደቅ', 'Approvals'),
              onTap: () => context.push('/admin/owners?status=SUSPENDED'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildQuickActionItem(
              context,
              icon: Icons.sell_outlined,
              label: context.tr('ብራንድ', 'Brands'),
              onTap: () => context.push('/admin/catalog'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildQuickActionItem(
              context,
              icon: Icons.cloud_upload_outlined,
              label: context.tr('ምትኬ', 'Backup'),
              onTap: () => context.push('/admin/backup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimaryOrange = false,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: isPrimaryOrange
                  ? AdminColors.keraOrange
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: isPrimaryOrange
                  ? null
                  : Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: isPrimaryOrange
                      ? AdminColors.keraOrange.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isPrimaryOrange
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF173655)),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // C. Platform Overview (6 Metric Cards Grid)
  Widget _buildPlatformOverviewGrid(BuildContext context, dynamic stats) {
    final activeCount = stats.activeOwners;
    final totalCount = stats.totalOwners;
    final activePercent =
        totalCount > 0 ? (activeCount * 100 / totalCount).round() : 100;
    final partsCount = CurrencyFormatter.formatCount(stats.totalParts);
    final pendingCount = stats.suspendedOwners;
    final syncProblems = stats.ownersWithSyncProblems;
    final syncHealth = totalCount > 0
        ? (((totalCount - syncProblems) / totalCount) * 100).round()
        : 100;
    final revenue = CurrencyFormatter.formatCompact(stats.totalRevenue);
    final profit = CurrencyFormatter.formatCompact(stats.totalProfit);

    return Column(
      children: [
        // Row 1: Active Owners + Pending Approval
        Row(
          children: [
            Expanded(
              child: AdminMetricTile(
                icon: Icons.storefront_outlined,
                iconColor: const Color(0xFF159B55),
                iconBgColor: const Color(0xFFECFDF5),
                value: '$activeCount',
                label: context.tr('ንቁ · Active', 'Active Owners'),
                badgeText: '$activePercent%',
                badgeColor: const Color(0xFF159B55),
                badgeBgColor: const Color(0xFFECFDF5),
                onTap: () => context.push('/admin/owners?status=ACTIVE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminMetricTile(
                icon: Icons.access_time_rounded,
                iconColor: AdminColors.keraOrange,
                iconBgColor: const Color(0xFFFFF7ED),
                value: '$pendingCount',
                label: context.tr('በመጠባበቅ · Pending', 'Pending Approval'),
                badgeText: context.tr('ግምገማ', 'Review'),
                badgeColor: const Color(0xFFD97706),
                badgeBgColor: const Color(0xFFFFF7ED),
                onTap: () => context.push('/admin/owners?status=SUSPENDED'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Total Parts + Sync Health
        Row(
          children: [
            Expanded(
              child: AdminMetricTile(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF173655),
                iconBgColor: const Color(0xFFEFF6FF),
                value: partsCount,
                label: context.tr('ዕቃዎች · Parts', 'Total Parts'),
                badgeText: context.tr('ሁሉም', 'All Owners'),
                badgeColor: const Color(0xFF2563EB),
                badgeBgColor: const Color(0xFFEFF6FF),
                onTap: () => context.push('/admin/catalog'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminMetricTile(
                icon: Icons.sync_rounded,
                iconColor: AdminColors.keraOrange,
                iconBgColor: const Color(0xFFFFF7ED),
                value: '$syncHealth%',
                label: context.tr('የማመሳሰል ሁኔታ · Sync', 'Sync Health'),
                badgeText: '$syncProblems ${context.tr("ችግር", "issues")}',
                badgeColor: const Color(0xFFD97706),
                badgeBgColor: const Color(0xFFFFF7ED),
                onTap: () => context.push('/admin/sync'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Total Revenue + Estimated Profit
        Row(
          children: [
            Expanded(
              child: AdminMetricTile(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF173655),
                iconBgColor: const Color(0xFFF1F5F9),
                value: revenue,
                label: context.tr('ሽያጭ · Revenue', 'Total Revenue'),
                badgeText: 'ETB',
                badgeColor: const Color(0xFF64748B),
                badgeBgColor: const Color(0xFFF1F5F9),
                onTap: () => context.push('/admin/reports'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminMetricTile(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF173655),
                iconBgColor: const Color(0xFFF1F5F9),
                value: profit,
                label: context.tr('ትርፍ · Profit', 'Estimated Profit'),
                badgeText: 'ETB',
                badgeColor: const Color(0xFF64748B),
                badgeBgColor: const Color(0xFFF1F5F9),
                onTap: () => context.push('/admin/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // D. Administration Modules Section (Clean Material InkWell avoiding ListTile warnings)
  Widget _buildAdministrationModulesCard(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Module 1: Sales Analytics & Reports
            InkWell(
              onTap: () => context.push('/admin/reports'),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E385C)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'ሪፖርቶች · Sales Reports',
                              'Sales Analytics & Reports',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'የሽያጭና የትርፍ ትንተና',
                              'Revenue and profit analytics across stores',
                            ),
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),

            // Module 2: Sync Queue & Conflict Monitor
            InkWell(
              onTap: () => context.push('/admin/sync'),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2B1D14)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sync_problem_rounded,
                        color: AdminColors.keraOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'የማመሳሰል ሁኔታ · Sync Monitor',
                              'Sync Queue & Conflict Monitor',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'የመሣሪያ አለመግባባቶችና ከመስመር ውጭ ወረፋዎች',
                              'Resolve device conflicts & offline queues',
                            ),
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
