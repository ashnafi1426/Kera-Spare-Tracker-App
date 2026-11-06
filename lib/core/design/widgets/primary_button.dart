import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Solid Orange (#F7941D) with bold Navy text (#061B3F). Exactly ONE primary action per screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? progressValue;
  final IconData? icon;
  final double height;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.progressValue,
    this.icon,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.orange500,
          foregroundColor: KeraColors.navy900,
          disabledBackgroundColor: KeraColors.border,
          disabledForegroundColor: KeraColors.disabledColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KeraRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: isLoading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(KeraColors.navy900),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: KeraColors.navy900),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: KeraColors.navy900,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
