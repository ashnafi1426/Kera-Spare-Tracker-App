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
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const KeraCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = KeraSpacing.cardPadding,
    this.margin,
    this.backgroundColor = KeraColors.surfacePure,
    this.borderColor = KeraColors.outlineBorder,
    this.borderWidth = 1.0,
    this.borderRadius = KeraRadii.borderCard,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [KeraColors.shadowLevel1],
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

