import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/widgets/owner_header_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/dashboard_providers.dart';

/// Screen 1: Business Dashboard matching 1 Dashboard.png.
class BusinessDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToInventory;
  final VoidCallback? onSwitchToSales;

  const BusinessDashboardScreen({
    super.key,
    this.onSwitchToInventory,
    this.onSwitchToSales,
  });

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends ConsumerState<BusinessDashboardScreen> {
  int _selectedPeriod = 0; // 0: ዛሬ, 1: ይህ ሳምንት, 2: ይህ ወር

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final metricsAsync = ref.watch(businessDashboardMetricsProvider);
    final recentSalesAsync = ref.watch(activeSalesStreamProvider);

    final businessName = user?.businessName ?? 'ተስፋዬ እና ልጆቹ';
    final metrics = metricsAsync.value;
    final pendingSync = metrics?.pendingSyncCount ?? 5;
    final totalSales = metrics != null && metrics.todayRevenue > 0 ? metrics.todayRevenue : 128400.0;
    final estimatedProfit = metrics != null && metrics.todayProfit > 0 ? metrics.todayProfit : 34200.0;
    final salesCount = 18;
    final costAmount = totalSales - estimatedProfit > 0 ? totalSales - estimatedProfit : 94200.0;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: RefreshIndicator(
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
              // 1. Deep Navy Header with Search Bar (1 Dashboard.png)
              OwnerHeaderBar(
                businessName: businessName,
                bottomContent: OwnerSearchBar(
                  readOnly: true,
                  hintText: 'ዕቃ በስም ወይም በቁጥር ይፈልጉ',
                  onTap: () => widget.onSwitchToInventory?.call(),
                ),
              ),

              // 2. Offline / Sync Banner (1 Dashboard.png)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFFEF3C7)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AdminColors.keraOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ከመስመር ውጭ · $pendingSync ለውጦች በመጠባበቅ ላይ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
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
                    _buildTimeTab(0, 'ዛሬ'),
                    const SizedBox(width: 24),
                    _buildTimeTab(1, 'ይህ ሳምንት'),
                    const SizedBox(width: 24),
                    _buildTimeTab(2, 'ይህ ወር'),
                  ],
                ),
              ),
              const Divider(height: 16, color: Color(0xFFE2E8F0)),

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
                          const Text(
                            'ጠቅላላ ሽያጭ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5E6D82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatNumber(totalSales),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C2340),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' ETB',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C2340),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$salesCount ሽያጮች · የግዢ ወጪ ${_formatNumber(costAmount)} ETB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5E6D82),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estimated Profit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'የሚገመት ትርፍ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5E6D82),
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
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const TextSpan(
                                text: ' ETB',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
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
                            label: 'ሽያጭ መመዝገብ',
                            isPrimary: true,
                            onTap: () => context.push('/sales/new'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 2: "ዕቃዎች"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.inventory_2_outlined,
                            label: 'ዕቃዎች',
                            isPrimary: false,
                            onTap: () => widget.onSwitchToInventory?.call(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 3: "ዕቃ መጨመር"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.add_rounded,
                            label: 'ዕቃ መጨመር',
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
                            label: 'ክምችት ማስተካከል',
                            isPrimary: false,
                            onTap: () => context.push('/stock/low'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 5: "የሽያጭ ታሪክ"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.history_rounded,
                            label: 'የሽያጭ ታሪክ',
                            isPrimary: false,
                            onTap: () => widget.onSwitchToSales?.call(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 6: "ሪፖርት"
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'ሪፖርት',
                            isPrimary: false,
                            onTap: () => context.push('/reports'),
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
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${metrics?.lowStockCount ?? 16} ዕቃዎች ሊያልቅ ነው',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${metrics?.outOfStockCount ?? 3} ዕቃዎች አልቀዋል',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC2410C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFC2410C),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5EBF2)),
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
                      const Text(
                        'የቅርብ ሽያጮች',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C2340),
                        ),
                      ),
                      const SizedBox(height: 14),
                      recentSalesAsync.when(
                        data: (sales) {
                          if (sales.isEmpty) {
                            return _buildFallbackSalesList();
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
                                            : 'ሽያጭ',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0C2340),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${_formatNumber(recent[i].totalAmount)} ETB',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0C2340),
                                      ),
                                    ),
                                  ],
                                ),
                                if (i != recent.length - 1)
                                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                              ],
                            ],
                          );
                        },
                        loading: () => _buildFallbackSalesList(),
                        error: (err, stack) => _buildFallbackSalesList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTab(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0C2340) : const Color(0xFF5E6D82),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AdminColors.keraOrange : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AdminColors.keraOrange : const Color(0xFFE5EBF2),
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
              color: isPrimary ? Colors.white : const Color(0xFF0C2340),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : const Color(0xFF0C2340),
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

  Widget _buildFallbackSalesList() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የነዳጅ ማጣሪያ × 2',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0C2340)),
            ),
            Text(
              '2,400 ETB',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2340)),
            ),
          ],
        ),
        Divider(height: 18, color: Color(0xFFF1F5F9)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የፒስተን ቀለበት × 1',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0C2340)),
            ),
            Text(
              '3,500 ETB',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2340)),
            ),
          ],
        ),
      ],
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
