import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/widgets/kera_skeleton_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/inventory_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../parts/presentation/screens/part_details_screen.dart';
import '../../../parts/presentation/screens/part_form_screen.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../../../sales/presentation/screens/new_sale_screen.dart';
import '../../../sales/presentation/screens/sale_details_screen.dart';
import '../../../stock/presentation/screens/low_stock_screen.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_best_sellers.dart';
import '../widgets/dashboard_empty_onboarding.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_low_stock_banner.dart';
import '../widgets/dashboard_metrics_grid.dart';
import '../widgets/dashboard_offline_banner.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent_sales.dart';
import '../widgets/dashboard_sales_trend.dart';

/// Screen 1 / Module 2: Business Dashboard (ዋና ዳሽቦርድ).
///
/// Implements Google Stitch Screen 7 (Business Dashboard), Screen 9 (Offline
/// Dashboard), Screen 10 (Empty State Onboarding Journey), and Screen 11
/// (Loading & Sync Error Diagnostics).
///
/// Connects to real SQLite database models, ledger summaries, and Riverpod streams.
class BusinessDashboardScreen extends ConsumerWidget {
  final VoidCallback? onSwitchToInventory;
  final VoidCallback? onSwitchToSales;

  const BusinessDashboardScreen({
    super.key,
    this.onSwitchToInventory,
    this.onSwitchToSales,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final metricsAsync = ref.watch(businessDashboardMetricsProvider);
    final period = ref.watch(selectedReportPeriodProvider);
    final chartPointsAsync = ref.watch(chartPointsProvider);
    final topSellingAsync = ref.watch(topSellingPartsProvider);
    final recentSalesAsync = ref.watch(activeSalesStreamProvider);

    final businessName = user?.businessName ?? '';
    final phoneNumber = user?.phoneNumber;

    return Scaffold(
      backgroundColor: KeraColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: KeraColors.actionBlue,
          onRefresh: () async {
            ref.invalidate(partsStreamProvider);
            ref.invalidate(salesSummaryProvider);
            ref.invalidate(chartPointsProvider);
            ref.invalidate(topSellingPartsProvider);
            ref.invalidate(activeSalesStreamProvider);
            ref.invalidate(pendingSyncCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dashboard Header Banner (Screen 7)
                DashboardHeader(
                  businessName: businessName,
                  phoneNumber: phoneNumber,
                  pendingSyncCount:
                      metricsAsync.value?.pendingSyncCount ?? 0,
                  onSyncTap: () {
                    context.push('/sync');
                  },
                ),

                // 2. Offline Mode & Pending Sync Banner (Screen 9)
                if (metricsAsync.value != null &&
                    metricsAsync.value!.pendingSyncCount > 0)
                  DashboardOfflineBanner(
                    pendingCount: metricsAsync.value!.pendingSyncCount,
                    onInspectQueue: () => context.push('/sync/offline'),
                    onRetrySync: () {
                      ref.invalidate(pendingSyncCountProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('የዳታ ማመሳሰል በመሞከር ላይ... (Retrying Sync)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                // 3. Main Content Canvas
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeraSpacing.lg,
                    vertical: KeraSpacing.md,
                  ),
                  child: metricsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: KeraSpacing.xl),
                      child: Column(
                        children: [
                          KeraSkeletonLoader.card(height: 120),
                          const SizedBox(height: KeraSpacing.md),
                          KeraSkeletonLoader.card(height: 180),
                        ],
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(KeraSpacing.xl),
                        child: Text(
                          'ስህተት: $err',
                          style: const TextStyle(color: KeraColors.errorRed),
                        ),
                      ),
                    ),
                    data: (metrics) {
                      // Case A: Empty Store (Screen 10)
                      if (!metrics.hasItems) {
                        return DashboardEmptyOnboarding(
                          onAddFirstPart: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PartFormScreen(),
                              ),
                            );
                          },
                          onLoadStarterParts: () async {
                            final success = await ref
                                .read(inventoryListProvider.notifier)
                                .seedTestParts(count: 50);
                            if (context.mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('50 የናሙና ዕቃዎች ተጭነዋል (Loaded 50 starter parts)'),
                                ),
                              );
                              ref.invalidate(partsStreamProvider);
                            }
                          },
                        );
                      }

                      // Case B: Normal Populated Dashboard (Screen 7)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Business Statistics Grid (2x3)
                          DashboardMetricsGrid(
                            metrics: metrics,
                            onInventoryTap: onSwitchToInventory,
                            onLowStockTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LowStockScreen(),
                                ),
                              );
                            },
                            onOutOfStockTap: onSwitchToInventory,
                          ),

                          const SizedBox(height: KeraSpacing.xl),

                          // 2. Quick Actions Matrix (4-columns)
                          DashboardQuickActions(
                            onAddPart: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PartFormScreen(),
                                ),
                              );
                            },
                            onNewSale: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NewSaleScreen(),
                                ),
                              );
                            },
                            onRestock: onSwitchToInventory ?? () {},
                            onScanBarcode: onSwitchToInventory ?? () {},
                          ),

                          const SizedBox(height: KeraSpacing.xl),

                          // 3. Sales Analytics & Revenue Trend Chart
                          DashboardSalesTrend(
                            selectedPeriod: period,
                            onPeriodChanged: (newPeriod) {
                              ref
                                  .read(selectedReportPeriodProvider.notifier)
                                  .setPeriod(newPeriod);
                            },
                            points: chartPointsAsync.value ?? [],
                            periodRevenue: metrics.todayRevenue,
                            profitMargin: metrics.profitMargin,
                          ),

                          // 4. Low-Stock Alert Quick Banner (if any)
                          if (metrics.lowStockCount > 0) ...[
                            const SizedBox(height: KeraSpacing.lg),
                            DashboardLowStockBanner(
                              count: metrics.lowStockCount,
                              onReorderTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LowStockScreen(),
                                  ),
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: KeraSpacing.xl),

                          // 5. Best-Selling Auto Parts (Top 3)
                          DashboardBestSellers(
                            items: topSellingAsync.value ?? [],
                            onViewAll: onSwitchToInventory,
                            onItemTap: (part) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PartDetailsScreen(
                                    partId: part.partId,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: KeraSpacing.xl),

                          // 6. Recent Sales Feed (Last 3)
                          DashboardRecentSales(
                            sales: recentSalesAsync.value ?? [],
                            onSaleTap: (sale) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SaleDetailsScreen(
                                    saleId: sale.id,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: KeraSpacing.xxl),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab_add_part',
        backgroundColor: KeraColors.actionBlue,
        foregroundColor: Colors.white,
        tooltip: '+ Part',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PartFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
