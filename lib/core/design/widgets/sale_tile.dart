import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Receipt-style sale transaction summary tile.
class SaleTile extends StatelessWidget {
  final String receiptNumber;
  final int itemCount;
  final double totalAmount;
  final String dateText;
  final VoidCallback? onTap;

  const SaleTile({
    super.key,
    required this.receiptNumber,
    required this.itemCount,
    required this.totalAmount,
    required this.dateText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(KeraRadii.md),
          border: Border.all(color: context.borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Receipt Icon
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: KeraColors.navy100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: KeraColors.navy800,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Receipt & Items info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$receiptNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount items · $dateText',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Total Amount
            Text(
              '${totalAmount.toStringAsFixed(totalAmount % 1 == 0 ? 0 : 2)} ETB',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

