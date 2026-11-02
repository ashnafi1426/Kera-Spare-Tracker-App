import 'package:flutter/material.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
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

  String _formatTime(BuildContext context, DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? context.tr('ከሰዓት', 'PM') : context.tr('ጧት', 'AM');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _getPaymentMethodLabel(BuildContext context, String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return context.tr('ጥሬ ገንዘብ', 'Cash');
      case 'BANK_TRANSFER':
        return context.tr('የባንክ ዝውውር', 'Bank Transfer');
      case 'CREDIT':
        return context.tr('ብድር', 'Credit');
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const SizedBox.shrink();

    final recent3 = sales.take(3).toList();
    final itemsUnit = context.tr('ዓይነቶች', 'items');

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
                    context.tr('የቅርብ ሽያጮች', 'Recent Sales'),
                    style: KeraTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: KeraColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.tr('የቅርብ የደንበኛ ሽያጭ መዝገቦች', 'Latest recorded customer checkouts'),
                    style: KeraTypography.labelSmall().copyWith(
                      color: KeraColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: KeraSpacing.sm),
        Column(
          children: recent3.map((sale) {
            return Padding(
              padding: const EdgeInsets.only(bottom: KeraSpacing.xs),
              child: Material(
                color: KeraColors.surfaceCard,
                borderRadius: BorderRadius.circular(KeraRadii.md),
                child: InkWell(
                  onTap: onSaleTap != null ? () => onSaleTap!(sale) : null,
                  borderRadius: BorderRadius.circular(KeraRadii.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeraSpacing.md,
                      vertical: KeraSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(KeraRadii.md),
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Row(
                      children: [
                        // Sale icon badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: KeraColors.tealFixed.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: KeraColors.tealDark,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: KeraSpacing.sm),

                        // Sale receipt details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.receiptNumber ?? sale.id.substring(0, 8),
                                style: KeraTypography.bodyMedium().copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KeraColors.textPrimary,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatTime(context, sale.createdAt),
                                    style: KeraTypography.labelSmall().copyWith(
                                      color: KeraColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: KeraColors.borderNeutral,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      _getPaymentMethodLabel(context, sale.paymentMethod),
                                      style: KeraTypography.labelSmall().copyWith(
                                        fontSize: 9,
                                        color: KeraColors.primaryNavy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Items & Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatEtb(sale.totalAmount),
                              style: KeraTypography.labelLarge().copyWith(
                                fontWeight: FontWeight.bold,
                                color: KeraColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${sale.items.length} $itemsUnit',
                              style: KeraTypography.labelSmall().copyWith(
                                color: KeraColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
