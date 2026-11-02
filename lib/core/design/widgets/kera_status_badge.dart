import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';

enum KeraStatusBadgeType {
  inStock,
  lowStock,
  outOfStock,
  syncPending,
  synced,
  custom,
}

/// Compact status pill for stock availability, sync status, and category tags.
/// Designed for immediate discrimination under bright daylight.
class KeraStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;

  const KeraStatusBadge({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.padding = KeraSpacing.badgePadding,
  });

  /// In-Stock indicator (Green).
  factory KeraStatusBadge.inStock({
    Key? key,
    required double quantity,
    String? unit,
    String defaultLabel = 'በክምችት አለ',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    final text = unit != null && unit.isNotEmpty ? '$qtyStr $unit' : '$defaultLabel: $qtyStr';
    return KeraStatusBadge(
      key: key,
      label: text,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: KeraColors.stockInBg,
      textColor: KeraColors.stockInText,
    );
  }

  /// Low Stock indicator (Amber alert).
  factory KeraStatusBadge.lowStock({
    Key? key,
    required double quantity,
    String defaultLabel = 'አነስተኛ ክምችት',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    return KeraStatusBadge(
      key: key,
      label: '$defaultLabel: $qtyStr',
      icon: Icons.warning_amber_rounded,
      backgroundColor: KeraColors.stockLowBg,
      textColor: KeraColors.stockLowText,
    );
  }

  /// Depleted stock indicator (Red alert).
  factory KeraStatusBadge.outOfStock({
    Key? key,
    String label = 'አልቋል',
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: Icons.error_outline_rounded,
      backgroundColor: KeraColors.stockOutBg,
      textColor: KeraColors.stockOutText,
    );
  }

  /// Unsynced offline queue pending badge (Amber).
  factory KeraStatusBadge.syncPending({
    Key? key,
    required int count,
    String defaultLabel = 'ያልተላከ',
  }) {
    return KeraStatusBadge(
      key: key,
      label: count > 0 ? '$defaultLabel ($count)' : defaultLabel,
      icon: Icons.cloud_queue_rounded,
      backgroundColor: KeraColors.syncPendingBg,
      textColor: KeraColors.syncPendingText,
    );
  }

  /// Online synced badge (Green check).
  factory KeraStatusBadge.synced({
    Key? key,
    String label = 'የተገናኘ',
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: Icons.cloud_done_rounded,
      backgroundColor: KeraColors.syncSuccessBg,
      textColor: KeraColors.syncSuccessText,
    );
  }

  /// Category or Brand tag pill (Muted neutral).
  factory KeraStatusBadge.tag({
    Key? key,
    required String label,
    IconData? icon,
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: KeraColors.surfaceMuted,
      textColor: KeraColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: KeraRadii.borderMicro,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: KeraTypography.labelSmall(color: textColor).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

