import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/reports_providers.dart';

/// Modal bottom sheet for in-depth sales analytics and payment breakdown.
///
/// Follows Google Stitch Screen 2 (Sales Reports — የሽያጭ ሪፖርት).
class SalesAnalyticsSheet extends ConsumerWidget {
  const SalesAnalyticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SalesAnalyticsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final chartPointsAsync = ref.watch(chartPointsProvider);
    final salesHistoryAsync = ref.watch(activeSalesStreamProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KeraColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.query_stats_rounded,
                              size: 20, color: KeraColors.actionBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'የሽያጭ ሪፖርት / Sales Analytics',
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Revenue Velocity & Payment Breakdown',
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Executive Summary Card
                summaryAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(err.toString()),
                  data: (summary) {
                    final atv = summary.salesCount > 0
                        ? summary.totalRevenue / summary.salesCount
                        : 0.0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KeraColors.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KeraColors.primaryNavyLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ጠቅላላ ገቢ / TOTAL REVENUE',
                                style: KeraTypography.labelSmall(
                                  color: Colors.white70,
                                ).copyWith(letterSpacing: 1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'የተረጋገጠ',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.tealAccent,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.formatEtb(summary.totalRevenue),
                              style: KeraTypography.headlineMedium(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ደረሰኞች (Receipts)',
                                      style: KeraTypography.labelSmall(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${summary.salesCount} ሽያጮች',
                                      style: KeraTypography.labelLarge(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'አማካይ ደረሰኝ (ATV)',
                                      style: KeraTypography.labelSmall(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        CurrencyFormatter.formatEtb(atv),
                                        style: KeraTypography.labelLarge(
                                          color: Colors.white,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // 2. Payment Method Breakdown (Calculated from real DB transactions)
                Text(
                  'የክፍያ ዘዴዎች / Payment Breakdown',
                  style: KeraTypography.titleSmall()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                salesHistoryAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Text(err.toString()),
                  data: (sales) {
                    double cashTotal = 0.0;
                    double telebirrTotal = 0.0;
                    double bankTotal = 0.0;
                    double creditTotal = 0.0;

                    for (final s in sales) {
                      final method = (s.paymentMethod ?? 'Cash').toLowerCase();
                      if (method.contains('telebirr')) {
                        telebirrTotal += s.totalAmount;
                      } else if (method.contains('cbe') || method.contains('bank')) {
                        bankTotal += s.totalAmount;
                      } else if (method.contains('credit')) {
                        creditTotal += s.totalAmount;
                      } else {
                        cashTotal += s.totalAmount;
                      }
                    }

                    final grandTotal =
                        cashTotal + telebirrTotal + bankTotal + creditTotal;
                    final cashPct =
                        grandTotal > 0 ? (cashTotal / grandTotal * 100) : 0.0;
                    final telebirrPct =
                        grandTotal > 0 ? (telebirrTotal / grandTotal * 100) : 0.0;
                    final bankPct =
                        grandTotal > 0 ? (bankTotal / grandTotal * 100) : 0.0;
                    final creditPct =
                        grandTotal > 0 ? (creditTotal / grandTotal * 100) : 0.0;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KeraColors.outlineBorder),
                      ),
                      child: Column(
                        children: [
                          _buildPaymentRow(
                            icon: Icons.payments_rounded,
                            iconColor: Colors.green.shade700,
                            name: 'ጥሬ ገንዘብ (Cash)',
                            amount: cashTotal,
                            percent: cashPct,
                          ),
                          const Divider(height: 16),
                          _buildPaymentRow(
                            icon: Icons.phone_android_rounded,
                            iconColor: KeraColors.actionBlue,
                            name: 'ቴሌብር (Telebirr)',
                            amount: telebirrTotal,
                            percent: telebirrPct,
                          ),
                          const Divider(height: 16),
                          _buildPaymentRow(
                            icon: Icons.account_balance_rounded,
                            iconColor: Colors.purple.shade700,
                            name: 'የባንክ ሂሳብ (CBE / BOA)',
                            amount: bankTotal,
                            percent: bankPct,
                          ),
                          if (creditTotal > 0) ...[
                            const Divider(height: 16),
                            _buildPaymentRow(
                              icon: Icons.assignment_late_outlined,
                              iconColor: KeraColors.warningAmber,
                              name: 'ብድር (Credit)',
                              amount: creditTotal,
                              percent: creditPct,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // 3. Peak Velocity Insights
                chartPointsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (points) {
                    if (points.isEmpty) return const SizedBox.shrink();

                    final peakPoint = points.reduce(
                      (curr, next) => curr.revenue > next.revenue ? curr : next,
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: KeraColors.actionBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: KeraColors.actionBlue, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ከፍተኛ የሽያጭ ቀን / Record Peak Day',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.actionBlue,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${peakPoint.label}: ${CurrencyFormatter.formatEtb(peakPoint.revenue)}',
                                  style: KeraTypography.labelLarge(
                                    color: KeraColors.primaryNavy,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required IconData icon,
    required Color iconColor,
    required String name,
    required double amount,
    required double percent,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: KeraTypography.labelMedium()
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${percent.toStringAsFixed(1)}% ድርሻ',
                style: KeraTypography.bodySmall(color: KeraColors.textSecondary)
                    .copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.formatEtb(amount),
          style: KeraTypography.labelMedium(color: KeraColors.primaryNavy)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

