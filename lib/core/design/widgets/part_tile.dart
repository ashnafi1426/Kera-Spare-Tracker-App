import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/kera_image_widget.dart';
import '../tokens/kera_radii.dart';
import 'status_badge.dart';

/// Mobile inventory item tile designed for high touch usability.
///
/// Handles 2-line Amharic text and large font scales up to 200% without overflow.
class PartTile extends StatelessWidget {
  final String title;
  final String? partNumber;
  final String? shelfLocation;
  final String? photoPath;
  final double? price;
  final double quantity;
  final String unit;
  final double minQuantity;
  final VoidCallback? onTap;

  const PartTile({
    super.key,
    required this.title,
    this.partNumber,
    this.shelfLocation,
    this.photoPath,
    this.price,
    required this.quantity,
    this.unit = 'Pcs',
    this.minQuantity = 5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLow = quantity <= minQuantity && quantity > 0;
    final isOut = quantity <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(KeraRadii.md),
          border: Border.all(color: context.borderColor, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail with safe DPR-aware decode
            KeraPartImage(
              localPath: photoPath != null && !photoPath!.startsWith('http') ? photoPath : null,
              remoteUrl: photoPath != null && photoPath!.startsWith('http') ? photoPath : null,
              width: 54,
              height: 54,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),

            // Main Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (partNumber != null && partNumber!.isNotEmpty)
                        Text(
                          '#$partNumber',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (shelfLocation != null && shelfLocation!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                shelfLocation!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Price & Stock Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (price != null)
                  Text(
                    '${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)} ETB',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                const SizedBox(height: 4),
                if (isOut)
                  StatusBadge.outOfStock(label: l10n.statusOutOfStock)
                else if (isLow)
                  StatusBadge.lowStock(
                    quantity: quantity,
                    defaultLabel: l10n.statusLowStock,
                  )
                else
                  StatusBadge.inStock(
                    quantity: quantity,
                    unit: unit,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
