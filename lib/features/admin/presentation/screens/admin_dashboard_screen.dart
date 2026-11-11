import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/widgets/dashboard_header_bar.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';
import '../widgets/admin_metric_tile.dart';

/// Screen 1: Admin Dashboard faithfully matching Dashboard.png.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Fixed, Non-shifting Shared Header Bar (Issue 4)
          DashboardHeaderBar(
            title: 'Kera Spare Tracker',
            subtitle: context.tr('አድሚን ኮንሶል · Admin Console', 'Admin Console · Manager'),
            searchHint: context.tr('ፈልግ · Search owners, phones', 'Search owners, phones...'),
            onSearchTap: () => context.push('/admin/owners'),
            trailingAction: AdminHeaderIconButton(
              icon: Icons.notifications_outlined,
              hasBadge: true,
              tooltip: 'Notifications',
              onTap: () => context.push('/admin/notifications'),
            ),
          ),

          // Scrollable Body
          Expanded(
            child: dashboardAsync.when(
              loading: () => KeraLoadingView(
                message: context.tr('የአድሚን ዳሽቦርድ በመጫን ላይ...', 'Loading Admin Dashboard...'),
              ),
              error: (err, _) => Center(
                child: ErrorState(
                  message: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.refresh(adminDashboardProvider),
                ),
              ),
              data: (stats) => RefreshIndicator(
                color: AdminColors.primary,
                onRefresh: () async => ref.refresh(adminDashboardProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Registered Owners Hero + Quick Actions (Dashboard.png)
                      _buildRegisteredOwnersHero(context, ref, stats),

                      // 2. Main Metrics Grid & Activity (Dashboard.png)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetricsGrid(context, stats),
                            const SizedBox(height: 24),

                            // Navigation Quick Cards (Reports, Sync Monitor, Audit)
                            _buildQuickFeatureStrip(context, ref, stats),
                            const SizedBox(height: 32),
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

  /// Registered Owners Hero & Quick Actions Card
  Widget _buildRegisteredOwnersHero(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
  ) {
    final totalOwners = stats.totalOwners;
    final newThisWeek = stats.newOwnersThisWeek;
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Registered Owners Hero + Orange Sparkline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ጠቅላላ ባለቤቶች · Registered owners', 'Total Registered Owners'),
                      style: const TextStyle(
                        color: AdminColors.headerTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$totalOwners',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.keraOrange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '+$newThisWeek ${context.tr("በዚህ ሳምንት", "this week")}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sparkline upward trend wave
                const SizedBox(
                  width: 100,
                  height: 48,
                  child: CustomPaint(
                    painter: SparklinePainter(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: isDark ? const Color(0xFF1E385C) : Colors.white24),
            const SizedBox(height: 16),

            // 4 Quick Actions Row: ባለቤት ጨምር, ማጽደቅ, ብራንድ, ምትኬ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionCircle(
                  icon: Icons.person_add_alt_1_rounded,
                  label: context.tr('ባለቤት ጨምር', 'Add Owner'),
                  onTap: () => context.push('/admin/owners/add'),
                ),
                _buildQuickActionCircle(
                  icon: Icons.refresh_rounded,
                  label: context.tr('ማጽደቅ', 'Approvals'),
                  onTap: () => context.push('/admin/owners?status=SUSPENDED'),
                ),
                _buildQuickActionCircle(
                  icon: Icons.sell_outlined,
                  label: context.tr('ብራንድ', 'Brands'),
                  onTap: () => context.push('/admin/catalog'),
                ),
                _buildQuickActionCircle(
                  icon: Icons.wb_sunny_outlined,
                  label: context.tr('ምትኬ', 'Backup'),
                  onTap: () => context.push('/admin/backup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCircle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AdminColors.headerButtonBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AdminColors.keraOrange, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 6 Core Metric Cards in 2x3 Grid matching Dashboard.png
  Widget _buildMetricsGrid(BuildContext context, dynamic stats) {
    final activeCount = stats.activeOwners;
    final totalCount = stats.totalOwners;
    final activePercent = totalCount > 0 ? (activeCount * 100 / totalCount).round() : 100;
    final partsCount = CurrencyFormatter.formatCount(stats.totalParts);
    final pendingCount = stats.suspendedOwners;
    final syncProblems = stats.ownersWithSyncProblems;
    final syncHealth = totalCount > 0 ? (((totalCount - syncProblems) / totalCount) * 100).round() : 100;
    final revenue = CurrencyFormatter.formatCompact(stats.totalRevenue);
    final profit = CurrencyFormatter.formatCompact(stats.totalProfit);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Active Owners
        AdminMetricTile(
          icon: Icons.home_outlined,
          value: '$activeCount',
          label: context.tr('ንቁ · Active', 'Active Owners'),
          badgeText: '$activePercent%',
          badgeColor: AdminColors.navy,
          onTap: () => context.push('/admin/owners?status=ACTIVE'),
        ),

        // 2. Pending Owners
        AdminMetricTile(
          icon: Icons.refresh_rounded,
          value: '$pendingCount',
          label: context.tr('በመጠባበቅ · Pending', 'Pending Approval'),
          badgeText: context.tr('ግምገማ', 'Review'),
          badgeColor: AdminColors.keraOrange,
          onTap: () => context.push('/admin/owners?status=SUSPENDED'),
        ),

        // 3. Parts Catalog
        AdminMetricTile(
          icon: Icons.sell_outlined,
          value: partsCount,
          label: context.tr('ዕቃዎች · Parts', 'Total Parts'),
          badgeText: context.tr('ሁሉም', 'All Owners'),
          badgeColor: const Color(0xFF5E6D82),
          onTap: () => context.push('/admin/catalog'),
        ),

        // 4. Sync Health
        AdminMetricTile(
          icon: Icons.sync_rounded,
          value: '$syncHealth%',
          label: context.tr('የማመሳሰል ሁኔታ · Sync', 'Sync Health'),
          badgeText: '$syncProblems ${context.tr("ችግር", "issues")}',
          badgeColor: syncProblems == 0 ? AdminColors.navy : AdminColors.keraOrange,
          onTap: () => context.push('/admin/sync'),
        ),

        // 5. Total Revenue
        AdminMetricTile(
          icon: Icons.bar_chart_rounded,
          value: revenue,
          label: context.tr('ሽያጭ · Revenue', 'Total Revenue'),
          badgeText: 'ETB',
          badgeColor: AdminColors.navy,
          onTap: () => context.push('/admin/reports'),
        ),

        // 6. Estimated Profit
        AdminMetricTile(
          icon: Icons.insert_chart_outlined_rounded,
          value: profit,
          label: context.tr('ትርፍ · Profit', 'Estimated Profit'),
          badgeText: 'ETB',
          badgeColor: AdminColors.navy,
          onTap: () => context.push('/admin/reports'),
        ),
      ],
    );
  }

  /// Secondary navigation strip for Reports, Sync Monitor, and Server Settings
  Widget _buildQuickFeatureStrip(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('ተጨማሪ ሞጁሎች · Administration Hub', 'Administration Modules'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminColors.navyTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_outlined, color: Color(0xFF3B82F6)),
            ),
            title: Text(
              context.tr('ሪፖርቶች · Sales Reports', 'Sales Analytics & Reports'),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
            ),
            subtitle: Text(
              context.tr('የሽያጭና የትርፍ ትንተና', 'Revenue and profit analytics across stores'),
              style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
            onTap: () => context.push('/admin/reports'),
          ),
          Divider(height: 16, color: context.borderColor),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminColors.orangeTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sync_problem_rounded, color: AdminColors.keraOrange),
            ),
            title: Text(
              context.tr('የማመሳሰል ሁኔታ · Sync Monitor', 'Sync Queue & Conflict Monitor'),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor),
            ),
            subtitle: Text(
              context.tr('የመሣሪያ አለመግባባቶችና ከመስመር ውጭ ወረፋዎች', 'Resolve device conflicts & offline queues'),
              style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
            onTap: () => context.push('/admin/sync'),
          ),
        ],
      ),
    );
  }
}
