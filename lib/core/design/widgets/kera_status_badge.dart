import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';
export 'status_badge.dart';

enum KeraStatusBadgeType {
  inStock,
  lowStock,
  outOfStock,
  syncPending,
  synced,
  custom,
}

/// Compact status pill for stock availability, sync status, and category tags.
/// Strictly conforms to the 2-color brand system with Icon + Label pairing.
class KeraStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final EdgeInsetsGeometry padding;

  const KeraStatusBadge({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.border,
    this.padding = KeraSpacing.badgePadding,
  });

  /// In-Stock indicator (Navy soft chip).
  factory KeraStatusBadge.inStock({
    Key? key,
    required double quantity,
    String? unit,
    String defaultLabel = 'In Stock',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    final text = unit != null && unit.isNotEmpty ? '$qtyStr $unit' : '$defaultLabel: $qtyStr';
    return KeraStatusBadge(
      key: key,
      label: text,
      icon: Icons.check_circle_rounded,
      backgroundColor: KeraColors.stockInBg,
      textColor: KeraColors.stockInText,
      border: Border.all(color: KeraColors.border),
    );
  }

  /// Low Stock indicator (Soft orange chip).
  factory KeraStatusBadge.lowStock({
    Key? key,
    required double quantity,
    String defaultLabel = 'Low Stock',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    return KeraStatusBadge(
      key: key,
      label: '$defaultLabel: $qtyStr',
      icon: Icons.warning_amber_rounded,
      backgroundColor: KeraColors.stockLowBg,
      textColor: KeraColors.stockLowText,
      border: Border.all(color: KeraColors.orange600),
    );
  }

  /// Depleted stock indicator (Solid orange chip with bold navy text).
  factory KeraStatusBadge.outOfStock({
    Key? key,
    String label = 'Out of Stock',
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: Icons.error_outline_rounded,
      backgroundColor: KeraColors.stockOutBg,
      textColor: KeraColors.stockOutText,
      border: Border.all(color: KeraColors.orange700, width: 1.5),
    );
  }

  /// Unsynced offline queue pending badge (Soft orange chip).
  factory KeraStatusBadge.syncPending({
    Key? key,
    required int count,
    String defaultLabel = 'Pending',
  }) {
    return KeraStatusBadge(
      key: key,
      label: count > 0 ? '$defaultLabel ($count)' : defaultLabel,
      icon: Icons.access_time_rounded,
      backgroundColor: KeraColors.syncPendingBg,
      textColor: KeraColors.syncPendingText,
      border: Border.all(color: KeraColors.orange500),
    );
  }

  /// Online synced badge (Navy soft chip).
  factory KeraStatusBadge.synced({
    Key? key,
    String label = 'Synced',
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: Icons.check_circle_rounded,
      backgroundColor: KeraColors.syncSuccessBg,
      textColor: KeraColors.syncSuccessText,
      border: Border.all(color: KeraColors.border),
    );
  }

  /// Offline badge (Navy outline chip).
  factory KeraStatusBadge.offline({
    Key? key,
    String label = 'Offline',
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: Icons.cloud_off_rounded,
      backgroundColor: Colors.transparent,
      textColor: KeraColors.navy800,
      border: Border.all(color: KeraColors.navy800, width: 1.5),
    );
  }

  /// Custom badge conforming to the design system.
  factory KeraStatusBadge.custom({
    Key? key,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    Border? border,
  }) {
    return KeraStatusBadge(
      key: key,
      label: label,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      border: border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBg = isDark && backgroundColor == Colors.transparent
        ? Colors.transparent
        : (isDark && backgroundColor == KeraColors.stockInBg
            ? KeraColors.navy800
            : backgroundColor);
    final resolvedText = isDark && textColor == KeraColors.stockInText
        ? Colors.white
        : textColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(KeraRadii.full),
        border: border ?? Border.all(color: KeraColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: resolvedText,
            ),
            const SizedBox(width: KeraSpacing.xs),
          ],
          Text(
            label,
            style: KeraTypography.labelSmall(color: resolvedText).copyWith(
              fontWeight: backgroundColor == KeraColors.stockOutBg
                  ? FontWeight.w700
                  : FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
