import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';

/// Low-Stock Alert Quick Banner matching Stitch Screen 7.
///
/// Prominently informs the store manager about parts that fell below
/// safety threshold, with a direct reorder CTA.
class DashboardLowStockBanner extends StatelessWidget {
  final int count;
  final VoidCallback onReorderTap;

  const DashboardLowStockBanner({
    super.key,
    required this.count,
    required this.onReorderTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // amber-50
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(
          color: const Color(0xFFFDE68A), // amber-200
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(KeraRadii.xs),
            ),
            child: const Icon(
              Icons.notification_important_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
          const SizedBox(width: KeraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count እቃዎች ዝቅተኛ ክምችት ላይ ናቸው',
                  style: KeraTypography.bodySmall().copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF78350F),
                  ),
                ),
                Text(
                  'Critical items below safety threshold',
                  style: KeraTypography.labelSmall().copyWith(
                    color: const Color(0xFF92400E),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeraSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KeraRadii.xs),
              ),
            ),
            onPressed: onReorderTap,
            child: const Text(
              'እዘዝ (View)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
