import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../sales/domain/models/sale_model.dart';

/// Recent transactions list matching Stitch Screen 7.
class DashboardRecentSales extends StatelessWidget {
  final List<SaleModel> sales;
  final ValueChanged<SaleModel>? onSaleTap;

  const DashboardRecentSales({
    super.key,
    required this.sales,
    this.onSaleTap,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'ከሰዓት (PM)' : 'ጧት (AM)';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const SizedBox.shrink();

    final recent3 = sales.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'የቅርብ ሽያጮች / Recent Sales',
                    style: KeraTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: KeraColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Latest recorded customer checkouts',
                    style: KeraTypography.labelSmall().copyWith(
                      color: KeraColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: KeraSpacing.xs),
            Text(
              'ዛሬ የተቀበሉ',
              style: KeraTypography.labelSmall().copyWith(
                color: KeraColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: KeraSpacing.sm),

        // Grouped container
        Container(
          decoration: BoxDecoration(
            color: KeraColors.surfaceCard,
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(color: KeraColors.borderVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ListView.separated(
            itemCount: recent3.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: KeraColors.borderVariant),
            itemBuilder: (context, index) {
              final sale = recent3[index];
              final invoiceCode = sale.receiptNumber != null &&
                      sale.receiptNumber!.isNotEmpty
                  ? sale.receiptNumber!
                  : 'TRX-${sale.id.substring(0, mathMin(6, sale.id.length)).toUpperCase()}';

              return InkWell(
                onTap: onSaleTap != null ? () => onSaleTap!(sale) : null,
                child: Padding(
                  padding: const EdgeInsets.all(KeraSpacing.sm),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: KeraColors.borderNeutral,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  invoiceCode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: KeraColors.primaryNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(sale.soldAt),
                                style: KeraTypography.labelSmall().copyWith(
                                  color: KeraColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ተጠናቋል',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sale.items.length} ዕቃዎች ተሽጠዋል',
                                  style: KeraTypography.bodySmall().copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: KeraColors.textPrimary,
                                  ),
                                ),
                                if (sale.totalProfit > 0)
                                  Text(
                                    'ትርፍ: +${sale.totalProfit.toStringAsFixed(0)} ብር',
                                    style: KeraTypography.labelSmall().copyWith(
                                      color: KeraColors.tealDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    sale.totalAmount.toStringAsFixed(0),
                                    style:
                                        KeraTypography.titleMedium().copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: KeraColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'ብር',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${sale.paymentMethod ?? "ጥሬ ገንዘብ (Cash)"} • ክፍያ ተፈጽሟል',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: KeraColors.textSecondary,
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
            },
          ),
        ),
      ],
    );
  }

  int mathMin(int a, int b) => a < b ? a : b;
}
