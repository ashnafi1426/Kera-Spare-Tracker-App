import 'dart:io';
import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';
import 'kera_card.dart';
import 'kera_status_badge.dart';

/// Industrial auto spare parts card adhering to Stitch specification (Screens 12 & 15).
///
/// Features 64x64 thumbnail, OEM number, brand badge, shelf location,
/// tabular Ethiopian Birr price, stock pill, and quick-add POS action.
/// Supports both compact list item layout and 2-column grid layout.
class KeraProductCard extends StatelessWidget {
  final String title;
  final String? partNumber;
  final String? brandName;
  final String? shelfLocation;
  final String? photoPath;
  final double? price;
  final String currencySymbol;
  final double stockQuantity;
  final String? unit;
  final bool isLowStock;
  final bool isOutOfStock;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAction;
  final IconData quickActionIcon;
  final String? quickActionTooltip;
  final bool isGrid;
  final VoidCallback? onEdit;
  final VoidCallback? onSell;
  final String? outOfStockLabel;

  const KeraProductCard({
    super.key,
    required this.title,
    this.partNumber,
    this.brandName,
    this.shelfLocation,
    this.photoPath,
    this.price,
    this.currencySymbol = 'ብር',
    required this.stockQuantity,
    this.unit,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.onTap,
    this.onQuickAction,
    this.quickActionIcon = Icons.add_rounded,
    this.quickActionTooltip,
    this.isGrid = false,
    this.onEdit,
    this.onSell,
    this.outOfStockLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    return KeraCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 64x64 Part Image Thumbnail
          _buildThumbnail(size: 64),
          const SizedBox(width: KeraSpacing.md),

          // 2. Central Information Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title (Part Name)
                Text(
                  title,
                  style: KeraTypography.titleSmall(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // OEM Part Number & Brand Pill
                Row(
                  children: [
                    if (partNumber != null && partNumber!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          '#$partNumber',
                          style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (brandName != null && brandName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: const BoxDecoration(
                          color: KeraColors.surfaceMuted,
                          borderRadius: KeraRadii.borderMicro,
                          border: Border.fromBorderSide(
                            BorderSide(color: KeraColors.outlineBorder),
                          ),
                        ),
                        child: Text(
                          brandName!,
                          style: KeraTypography.labelSmall(color: KeraColors.actionBlue).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Shelf Location
                if (shelfLocation != null && shelfLocation!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.shelves, size: 12, color: KeraColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          shelfLocation!,
                          style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: KeraSpacing.sm),

          // 3. Right Status, Price & Quick Action Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price
              if (price != null) ...[
                Text(
                  '${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)} $currencySymbol',
                  style: KeraTypography.numericCompact(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Stock Status Pill
              _buildStockPill(),

              // Quick Action Trigger (for POS cart addition or sales)
              if (onQuickAction != null || onSell != null) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      backgroundColor: KeraColors.actionBlue,
                      foregroundColor: KeraColors.textWhite,
                      shape: const RoundedRectangleBorder(
                        borderRadius: KeraRadii.borderMicro,
                      ),
                    ),
                    icon: Icon(quickActionIcon, size: 18),
                    tooltip: quickActionTooltip ?? 'Add to cart',
                    onPressed: onQuickAction ?? onSell,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return KeraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image banner
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: KeraRadii.borderCard,
                    child: Container(
                      color: KeraColors.surfaceMuted,
                      child: _buildImageOrPlaceholder(),
                    ),
                  ),
                ),
                if (brandName != null && brandName!.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KeraColors.primaryNavy.withValues(alpha: 0.85),
                        borderRadius: KeraRadii.borderMicro,
                      ),
                      child: Text(
                        brandName!,
                        style: KeraTypography.labelSmall(color: KeraColors.textWhite).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Part Name
          Text(
            title,
            style: KeraTypography.titleSmall(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Part Number
          if (partNumber != null && partNumber!.isNotEmpty)
            Text(
              '#$partNumber',
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),

          // Price & Stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (price != null)
                Text(
                  '${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)} $currencySymbol',
                  style: KeraTypography.numericCompact(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                )
              else
                const SizedBox.shrink(),
              _buildStockPill(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail({double size = 64}) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Container(
        width: size,
        height: size,
        color: KeraColors.surfaceMuted,
        child: _buildImageOrPlaceholder(),
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: 160,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.build_circle_outlined,
        color: KeraColors.actionBlue,
        size: 28,
      ),
    );
  }

  Widget _buildStockPill() {
    if (isOutOfStock || stockQuantity <= 0) {
      return KeraStatusBadge.outOfStock(label: outOfStockLabel ?? 'ያለቀ');
    } else if (isLowStock) {
      return KeraStatusBadge.lowStock(quantity: stockQuantity);
    } else {
      return KeraStatusBadge.inStock(quantity: stockQuantity, unit: unit);
    }
  }
}
