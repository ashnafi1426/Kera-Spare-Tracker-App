import 'package:flutter/material.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/kera_colors.dart';

enum StatusType { success, warning, danger, info }

/// Semantic badge displaying an icon, localized label, and status color.
/// Strictly conforms to the 2-color brand system: every status has an icon AND label.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final StatusType type;
  final Color? color;
  final Color? backgroundColor;
  final Border? border;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.type = StatusType.info,
    this.color,
    this.backgroundColor,
    this.border,
  });

  /// Active status (Soft Navy chip + check icon).
  factory StatusChip.active(String label) {
    return StatusChip(
      label: label,
      icon: Icons.check_circle_rounded,
      type: StatusType.success,
    );
  }

  /// Suspended / Disabled status (Solid Orange chip + bold Navy text + block icon).
  factory StatusChip.suspended(String label) {
    return StatusChip(
      label: label,
      icon: Icons.block_rounded,
      type: StatusType.danger,
    );
  }

  /// Warning / Pending status (Soft Orange chip + alert icon).
  factory StatusChip.warning(String label) {
    return StatusChip(
      label: label,
      icon: Icons.warning_amber_rounded,
      type: StatusType.warning,
    );
  }

  /// Informational status (Soft Navy chip + info icon).
  factory StatusChip.info(String label, {IconData icon = Icons.info_outline_rounded}) {
    return StatusChip(
      label: label,
      icon: icon,
      type: StatusType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (defaultTextColor, defaultBgColor, defaultBorder) = _resolveColors();
    final textColor = color ?? defaultTextColor;
    final bgColor = backgroundColor ?? defaultBgColor;
    final resolvedBorder = border ?? defaultBorder;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AdminSpacing.radiusChip),
        border: resolvedBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: textColor,
            ),
            const SizedBox(width: AdminSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: type == StatusType.danger ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Border?) _resolveColors() {
    switch (type) {
      case StatusType.success:
        return (KeraColors.navy800, KeraColors.navy100, Border.all(color: KeraColors.border));
      case StatusType.warning:
        return (KeraColors.orange700, KeraColors.orange100, Border.all(color: KeraColors.orange600));
      case StatusType.danger:
        return (KeraColors.navy900, KeraColors.orange500, Border.all(color: KeraColors.orange700, width: 1.5));
      case StatusType.info:
        return (KeraColors.navy800, KeraColors.navy100, Border.all(color: KeraColors.border));
    }
  }
}
