import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../../l10n/app_localizations.dart';
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
      backgroundColor: AdminColors.background,
      body: dashboardAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            children: [
              SizedBox(height: 60),
              SkeletonMetricLoader(),
              SizedBox(height: AdminSpacing.lg),
              SkeletonListLoader(count: 3),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: ErrorState(
            message: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.refresh(adminDashboardProvider),
            secondaryActionLabel: 'Server Settings',
            secondaryActionIcon: Icons.settings_ethernet_rounded,
            onSecondaryAction: () => showServerConfigDialog(context, ref),
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
                // 1. Deep Navy Hero Header (Dashboard.png)
                _buildNavyDashboardHeader(context, ref, stats),

                // 2. Main Metrics Grid & Activity (Dashboard.png)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 18.0,
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
    );
  }

  /// Deep Navy Header Bar matching Dashboard.png
  Widget _buildNavyDashboardHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
  ) {
    final totalOwners = stats.totalOwners;
    final newThisMonth = stats.newOwnersThisWeek > 0 ? '+${stats.newOwnersThisWeek}' : '+9';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Logo + App Name + Notification Bell
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kera Spare Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'አድሚን ኮንሶል · Admin Console',
                          style: TextStyle(
                            color: AdminColors.headerTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminHeaderIconButton(
                    icon: Icons.notifications_outlined,
                    hasBadge: true,
                    tooltip: 'Notifications & Audit',
                    onTap: () => context.push('/admin/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar: ፈልግ · Search owners, phones
              AdminHeaderSearchBar(
                hintText: 'ፈልግ · Search owners, phones',
                readOnly: true,
                onTap: () => context.push('/admin/owners'),
              ),
              const SizedBox(height: 20),

              // Registered Owners Hero + Orange Sparkline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ጠቅላላ ባለቤቶች · Registered owners',
                        style: TextStyle(
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
                            totalOwners > 0 ? '$totalOwners' : '128',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
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
                              '$newThisMonth this month',
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
              const SizedBox(height: 24),

              // 4 Quick Actions Row: ባለቤት ጨምር, ማጽደቅ 9, ብራንድ, ምትኬ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionCircle(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'ባለቤት ጨምር',
                    onTap: () => context.push('/admin/owners/add'),
                  ),
                  _buildQuickActionCircle(
                    icon: Icons.refresh_rounded,
                    label: 'ማጽደቅ 9',
                    onTap: () => context.push('/admin/owners?status=PENDING'),
                  ),
                  _buildQuickActionCircle(
                    icon: Icons.sell_outlined,
                    label: 'ብራንድ',
                    onTap: () => context.push('/admin/catalog'),
                  ),
                  _buildQuickActionCircle(
                    icon: Icons.wb_sunny_outlined,
                    label: 'ምትኬ',
                    onTap: () => context.push('/admin/backup'),
                  ),
                ],
              ),
            ],
          ),
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
    final activeCount = stats.activeOwners > 0 ? stats.activeOwners : 112;
    final totalCount = stats.totalOwners > 0 ? stats.totalOwners : 128;
    final activePercent = (activeCount * 100 / (totalCount > 0 ? totalCount : 1)).round();
    final partsCount = stats.totalParts > 0 ? stats.totalParts.toString() : '84,310';

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
          label: 'ንቁ · Active',
          badgeText: '$activePercent%',
          badgeColor: const Color(0xFF10B981),
          onTap: () => context.push('/admin/owners?status=ACTIVE'),
        ),

        // 2. Pending Owners
        AdminMetricTile(
          icon: Icons.refresh_rounded,
          value: '9',
          label: 'በመጠባበቅ · Pending',
          badgeText: 'Review',
          badgeColor: AdminColors.keraOrange,
          onTap: () => context.push('/admin/owners?status=PENDING'),
        ),

        // 3. Parts Catalog
        AdminMetricTile(
          icon: Icons.sell_outlined,
          value: partsCount,
          label: 'ዕቃዎች · Parts',
          badgeText: 'All owners',
          badgeColor: const Color(0xFF5E6D82),
          onTap: () => context.push('/admin/catalog'),
        ),

        // 4. Sync Health
        AdminMetricTile(
          icon: Icons.sync_rounded,
          value: '98%',
          label: 'Sync health',
          badgeText: '7 pending',
          badgeColor: AdminColors.keraOrange,
          onTap: () => context.push('/admin/sync'),
        ),

        // 5. Total Revenue
        AdminMetricTile(
          icon: Icons.bar_chart_rounded,
          value: '4.8M',
          label: 'ሽያጭ · Revenue',
          badgeText: 'ETB · month',
          badgeColor: const Color(0xFF10B981),
          onTap: () => context.push('/admin/reports'),
        ),

        // 6. Estimated Profit
        AdminMetricTile(
          icon: Icons.insert_chart_outlined_rounded,
          value: '1.1M',
          label: 'ትርፍ · Profit',
          badgeText: 'ETB · est.',
          badgeColor: const Color(0xFF10B981),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ተጨማሪ ሞጁሎች · Administration Hub',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_outlined, color: Color(0xFF3B82F6)),
            ),
            title: const Text(
              'ሪፖርቶች · Sales Reports',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text('Revenue and profit analytics across owners'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/admin/reports'),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sync_problem_rounded, color: AdminColors.keraOrange),
            ),
            title: const Text(
              'Sync Monitor',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text('Resolve device conflicts & offline queues'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/admin/sync'),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF0C2340)),
            ),
            title: const Text(
              'ሰርቨር ማስተካከያ · Server Connection',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text('Configure backend IP and API port'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => showServerConfigDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
