import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_radii.dart';
import 'secondary_button.dart';
import 'status_badge.dart';

/// Stock card with large quantity, status badge, and Stock In / Out triggers.
class StockCard extends StatelessWidget {
  final double currentQuantity;
  final double minQuantity;
  final String unit;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;

  const StockCard({
    super.key,
    required this.currentQuantity,
    required this.minQuantity,
    this.unit = 'Pcs',
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLow = currentQuantity <= minQuantity && currentQuantity > 0;
    final isOut = currentQuantity <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.stockStatus,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              if (isOut)
                StatusBadge.outOfStock(label: l10n.statusOutOfStock)
              else if (isLow)
                StatusBadge.lowStock(quantity: currentQuantity, defaultLabel: l10n.statusLowStock)
              else
                StatusBadge.inStock(quantity: currentQuantity, unit: unit),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currentQuantity.toStringAsFixed(currentQuantity % 1 == 0 ? 0 : 1)} $unit',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.stockIn,
                  icon: Icons.add_rounded,
                  onPressed: onStockIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: l10n.stockOut,
                  icon: Icons.remove_rounded,
                  onPressed: onStockOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

