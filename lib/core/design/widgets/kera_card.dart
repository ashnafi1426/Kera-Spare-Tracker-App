import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';

/// Level 1 resting card container with 1px border and subtle shadow.
class KeraCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const KeraCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = KeraSpacing.cardPadding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = KeraRadii.borderCard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBg = backgroundColor ??
        (isDark ? KeraColors.darkCard : KeraColors.surfacePure);
    final resolvedBorder = borderColor ??
        (isDark ? KeraColors.darkBorder : KeraColors.outlineBorder);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: borderRadius,
        border: Border.all(color: resolvedBorder, width: borderWidth),
        boxShadow: isDark
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                )
              ]
            : const [KeraColors.shadowLevel1],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: KeraColors.actionBlueTint,
            highlightColor: KeraColors.surfaceMuted,
            child: cardContent,
          ),
        ),
      );
    }

    if (margin != null) {
      return Container(
        margin: margin,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

