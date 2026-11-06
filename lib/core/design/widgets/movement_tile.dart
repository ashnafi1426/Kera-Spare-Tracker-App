import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Stock Movement history tile showing quantity change, note, and timestamp.
class MovementTile extends StatelessWidget {
  final String title;
  final double quantityChange;
  final String dateText;
  final String? note;
  final String unit;
  final VoidCallback? onTap;

  const MovementTile({
    super.key,
    required this.title,
    required this.quantityChange,
    required this.dateText,
    this.note,
    this.unit = 'Pcs',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = quantityChange > 0;
    final changeText = '${isPositive ? "+" : ""}${quantityChange.toStringAsFixed(quantityChange % 1 == 0 ? 0 : 1)} $unit';

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
            // Direction Icon in soft circular badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPositive ? KeraColors.navy100 : KeraColors.orange100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.add_rounded : Icons.remove_rounded,
                color: isPositive ? KeraColors.navy800 : KeraColors.orange700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note ?? dateText,
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

            // Quantity change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  changeText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? KeraColors.navy800 : KeraColors.orange700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

