import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';

enum StatusBadgeVariant {
  inStock,
  lowStock,
  outOfStock,
  synced,
  syncing,
  pending,
  failed,
  conflict,
  offline,
  active,
  suspended,
  custom,
}

/// The unified status component for Kera Spare Tracker.
///
/// Implements Step 2 of the 2-Color Design System:
/// - Never relies on color alone: EVERY status has an ICON and a TEXT LABEL.
/// - Synced / Success / In stock: Soft Navy chip (#E6ECF7), check icon, Navy text (#0B2A5B).
/// - Pending / Syncing: Soft Orange chip (#FFF1DC), sync/clock icon, Orange-700 text (#9A5000).
/// - Low stock: Soft Orange chip (#FFF1DC), alert-triangle icon, Orange-700 text (#9A5000).
/// - Out of stock: Solid Orange chip (#F7941D), inventory_2 icon, bold Navy text (#061B3F), heavier border (1.5px).
/// - Failed: Solid Orange chip (#F7941D), sync_problem_rounded icon, bold Navy text (#061B3F).
/// - Conflict: Solid Orange chip (#F7941D), report_rounded (octagon) icon, bold Navy text (#061B3F), heavier border (2.0px).
/// - Offline: Navy outline chip, cloud-off icon, Navy text (#0B2A5B).
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  /// In Stock / Available
  factory StatusBadge.inStock({
    Key? key,
    required double quantity,
    String? unit,
    String defaultLabel = 'In Stock',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    final text = unit != null && unit.isNotEmpty ? '$qtyStr $unit' : '$defaultLabel: $qtyStr';
    return StatusBadge(
      key: key,
      label: text,
      icon: Icons.check_circle_rounded,
      backgroundColor: KeraColors.navy100,
      textColor: KeraColors.navy800,
      border: Border.all(color: KeraColors.border),
    );
  }

  /// Low Stock Warning
  factory StatusBadge.lowStock({
    Key? key,
    required double quantity,
    String defaultLabel = 'Low Stock',
  }) {
    final qtyStr = quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
    return StatusBadge(
      key: key,
      label: '$defaultLabel: $qtyStr',
      icon: Icons.warning_amber_rounded,
      backgroundColor: KeraColors.orange100,
      textColor: KeraColors.orange700,
      border: Border.all(color: KeraColors.orange600),
    );
  }

  /// Out of Stock / Depleted
  factory StatusBadge.outOfStock({
    Key? key,
    String label = 'Out of Stock',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.inventory_2_outlined,
      backgroundColor: KeraColors.orange500,
      textColor: KeraColors.navy900,
      border: Border.all(color: KeraColors.orange700, width: 1.5),
    );
  }

  /// Cloud Synced / Up to Date
  factory StatusBadge.synced({
    Key? key,
    String label = 'Synced',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.check_circle_rounded,
      backgroundColor: KeraColors.navy100,
      textColor: KeraColors.navy800,
      border: Border.all(color: KeraColors.border),
    );
  }

  /// Active Synchronization in Progress
  factory StatusBadge.syncing({
    Key? key,
    String label = 'Syncing...',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.sync_rounded,
      backgroundColor: KeraColors.orange100,
      textColor: KeraColors.orange700,
      border: Border.all(color: KeraColors.orange500),
    );
  }

  /// Pending Sync in Outbox Queue
  factory StatusBadge.pending({
    Key? key,
    required int count,
    String defaultLabel = 'Pending',
  }) {
    return StatusBadge(
      key: key,
      label: count > 0 ? '$defaultLabel ($count)' : defaultLabel,
      icon: Icons.access_time_rounded,
      backgroundColor: KeraColors.orange100,
      textColor: KeraColors.orange700,
      border: Border.all(color: KeraColors.orange500),
    );
  }

  /// Sync Failed / Error
  factory StatusBadge.failed({
    Key? key,
    String label = 'Failed',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.sync_problem_rounded,
      backgroundColor: KeraColors.orange500,
      textColor: KeraColors.navy900,
      border: Border.all(color: KeraColors.orange700, width: 1.5),
    );
  }

  /// Discrepancy / Sync Conflict
  factory StatusBadge.conflict({
    Key? key,
    String label = 'Conflict',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.report_rounded,
      backgroundColor: KeraColors.orange500,
      textColor: KeraColors.navy900,
      border: Border.all(color: KeraColors.orange700, width: 2.0),
    );
  }

  /// Device Offline
  factory StatusBadge.offline({
    Key? key,
    String label = 'Offline',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.cloud_off_rounded,
      backgroundColor: Colors.transparent,
      textColor: KeraColors.navy800,
      border: Border.all(color: KeraColors.navy800, width: 1.5),
    );
  }

  /// Account Active
  factory StatusBadge.active({
    Key? key,
    String label = 'Active',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.check_circle_rounded,
      backgroundColor: KeraColors.navy100,
      textColor: KeraColors.navy800,
      border: Border.all(color: KeraColors.border),
    );
  }

  /// Account Suspended / Disabled
  factory StatusBadge.suspended({
    Key? key,
    String label = 'Suspended',
  }) {
    return StatusBadge(
      key: key,
      label: label,
      icon: Icons.block_rounded,
      backgroundColor: KeraColors.orange500,
      textColor: KeraColors.navy900,
      border: Border.all(color: KeraColors.orange700, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBg = isDark && backgroundColor == Colors.transparent
        ? Colors.transparent
        : (isDark && backgroundColor == KeraColors.navy100
            ? KeraColors.navy800
            : backgroundColor);
    final resolvedText = isDark && textColor == KeraColors.navy800
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
          Icon(
            icon,
            size: 13,
            color: resolvedText,
          ),
          const SizedBox(width: KeraSpacing.xs),
          Text(
            label,
            style: KeraTypography.labelSmall(color: resolvedText).copyWith(
              fontWeight: backgroundColor == KeraColors.orange500
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
