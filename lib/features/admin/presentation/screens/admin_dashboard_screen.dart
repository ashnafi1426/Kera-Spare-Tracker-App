import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/metric_card.dart';
import '../../../../core/design/widgets/section_header.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

/// Screen 1: Admin Dashboard with high-level tenant statistics and aggregate counts.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () => ref.refresh(adminDashboardProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AdminSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SkeletonMetricLoader(),
                SizedBox(height: AdminSpacing.lg),
                SkeletonListLoader(count: 3),
              ],
            ),
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
          onRefresh: () async => ref.refresh(adminDashboardProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tenant Overview Metrics
                SectionHeader(title: l10n.adminTenantOverview),
                const SizedBox(height: AdminSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= AdminSpacing.tabletBreakpoint;
                    final crossAxisCount = isTablet ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AdminSpacing.md,
                      mainAxisSpacing: AdminSpacing.md,
                      childAspectRatio: isTablet ? 1.4 : 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MetricCard(
                          label: l10n.adminTotalOwners,
                          value: stats.totalOwners.toString(),
                          icon: Icons.storefront_rounded,
                          accentColor: AdminColors.primary,
                        ),
                        MetricCard(
                          label: l10n.adminActiveOwners,
                          value: stats.activeOwners.toString(),
                          icon: Icons.check_circle_outline_rounded,
                          accentColor: AdminColors.success,
                        ),
                        MetricCard(
                          label: l10n.adminSuspendedOwners,
                          value: stats.suspendedOwners.toString(),
                          icon: Icons.block_rounded,
                          accentColor: AdminColors.danger,
                        ),
                        MetricCard(
                          label: l10n.adminNewThisWeek,
                          value: stats.newOwnersThisWeek.toString(),
                          icon: Icons.person_add_rounded,
                          accentColor: AdminColors.info,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AdminSpacing.xl),

                // 2. System Inventory & Sales Statistics
                SectionHeader(title: l10n.adminSystemStatistics),
                const SizedBox(height: AdminSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: l10n.adminTotalPartsCount,
                        value: stats.totalParts.toString(),
                        icon: Icons.precision_manufacturing_rounded,
                        accentColor: const Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: MetricCard(
                        label: l10n.adminTotalSalesCount,
                        value: stats.totalSales.toString(),
                        icon: Icons.point_of_sale_rounded,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.xl),

                // 3. Sync Status Health breakdown card
                SectionHeader(title: l10n.adminSyncHealth),
                const SizedBox(height: AdminSpacing.sm),
                _buildSyncHealthCard(context, stats, l10n),
                const SizedBox(height: AdminSpacing.xl),

                // 4. App Version Distribution
                SectionHeader(title: l10n.adminAppVersionsTitle),
                const SizedBox(height: AdminSpacing.sm),
                _buildAppVersionDistribution(context, stats, l10n),
                const SizedBox(height: AdminSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncHealthCard(
    BuildContext context,
    dynamic stats,
    AppLocalizations l10n,
  ) {
    final hasProblems = stats.ownersWithSyncProblems > 0;
    final healthyCount = (stats.activeOwners - stats.ownersWithSyncProblems).clamp(0, stats.totalOwners);
    final neverSyncedCount = stats.inactiveOwners > 0
        ? stats.inactiveOwners
        : (stats.totalOwners - stats.activeOwners - stats.suspendedOwners).clamp(0, stats.totalOwners);

    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.sm),
                decoration: BoxDecoration(
                  color: hasProblems ? AdminColors.warningTint : AdminColors.successTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasProblems ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                  color: hasProblems ? AdminColors.warning : AdminColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProblems
                          ? l10n.adminSyncProblemsCount(stats.ownersWithSyncProblems.toString())
                          : l10n.adminSyncHealthyMessage,
                      style: AdminTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasProblems ? AdminColors.warning : AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      l10n.adminSyncHealth,
                      style: AdminTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: AdminSpacing.md),

          // 3 breakdown rows
          Row(
            children: [
              Expanded(
                child: _healthIndicator(
                  label: l10n.adminSyncHealthy,
                  count: healthyCount.toString(),
                  color: AdminColors.success,
                ),
              ),
              Expanded(
                child: _healthIndicator(
                  label: l10n.adminSyncNeverStarted,
                  count: neverSyncedCount.toString(),
                  color: AdminColors.textSecondary,
                ),
              ),
              Expanded(
                child: _healthIndicator(
                  label: l10n.adminSyncNeedsAttention,
                  count: stats.ownersWithSyncProblems.toString(),
                  color: hasProblems ? AdminColors.danger : AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthIndicator({
    required String label,
    required String count,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AdminSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AdminTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          count,
          style: AdminTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AdminColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersionDistribution(
    BuildContext context,
    dynamic stats,
    AppLocalizations l10n,
  ) {
    if (stats.appVersionDistribution.isEmpty) {
      return ListCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
          child: Center(
            child: Text(
              l10n.adminNoVersionsRecorded,
              style: AdminTypography.caption,
            ),
          ),
        ),
      );
    }

    final totalClients = stats.appVersionDistribution.values.fold<int>(
      0,
      (int acc, int c) => acc + c,
    );

    return ListCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.appVersionDistribution.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AdminColors.border),
        itemBuilder: (ctx, i) {
          final entry = stats.appVersionDistribution.entries.elementAt(i);
          final count = entry.value as int;
          final pct = totalClients > 0 ? count / totalClients : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          size: 16,
                          color: AdminColors.textSecondary,
                        ),
                        const SizedBox(width: AdminSpacing.xs),
                        Text(
                          'v${entry.key}',
                          style: AdminTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    StatusChip(
                      label: '$count (${(pct * 100).toStringAsFixed(0)}%)',
                      color: AdminColors.primary,
                      backgroundColor: AdminColors.infoTint,
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: AdminColors.raised,
                    valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
