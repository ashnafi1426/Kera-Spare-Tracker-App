import 'package:flutter/material.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';

/// Standard list and content card for the Admin portal.
/// Features a subtle 1px border (#2A3B52 in dark) and 12px corner radius.
class ListCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;

  const ListCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AdminSpacing.lg),
    this.margin = const EdgeInsets.only(bottom: AdminSpacing.md),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? AdminColors.surfaceOf(isDark);
    final border = borderColor ?? AdminColors.borderOf(isDark);

    return Card(
      elevation: 0,
      margin: margin,
      color: bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        side: BorderSide(color: border, width: 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
