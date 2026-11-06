import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

/// High-contrast text button.
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? KeraColors.orange700,
        minimumSize: const Size(48, 48),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? (context.isDark ? KeraColors.orange500 : KeraColors.orange700),
        ),
      ),
    );
  }
}

