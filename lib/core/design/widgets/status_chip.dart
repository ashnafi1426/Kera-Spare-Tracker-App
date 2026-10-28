import 'package:flutter/material.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';

enum StatusType { success, warning, danger, info }

/// Semantic badge displaying an icon, localized label, and status color.
/// Ensuring color is not the sole conveyor of information (WCAG compliance).
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final StatusType type;
  final Color? color;
  final Color? backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.type = StatusType.info,
    this.color,
    this.backgroundColor,
  });

  factory StatusChip.active(String label) {
    return StatusChip(
      label: label,
      icon: Icons.check_circle_rounded,
      type: StatusType.success,
    );
  }

  factory StatusChip.suspended(String label) {
    return StatusChip(
      label: label,
      icon: Icons.block_rounded,
      type: StatusType.danger,
    );
  }

  factory StatusChip.warning(String label) {
    return StatusChip(
      label: label,
      icon: Icons.warning_amber_rounded,
      type: StatusType.warning,
    );
  }

  factory StatusChip.info(String label, {IconData icon = Icons.info_outline_rounded}) {
    return StatusChip(
      label: label,
      icon: icon,
      type: StatusType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (defaultTextColor, defaultBgColor) = _resolveColors();
    final textColor = color ?? defaultTextColor;
    final bgColor = backgroundColor ?? defaultBgColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AdminSpacing.radiusChip),
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
                fontWeight: FontWeight.w600,
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

  (Color, Color) _resolveColors() {
    switch (type) {
      case StatusType.success:
        return (AdminColors.success, AdminColors.successTint);
      case StatusType.warning:
        return (AdminColors.warning, AdminColors.warningTint);
      case StatusType.danger:
        return (AdminColors.danger, AdminColors.dangerTint);
      case StatusType.info:
        return (AdminColors.info, AdminColors.infoTint);
    }
  }
}
