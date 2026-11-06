import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Navy outline button with 48px touch target.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = isDark ? KeraColors.textWhite : KeraColors.navy800;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: context.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KeraRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

