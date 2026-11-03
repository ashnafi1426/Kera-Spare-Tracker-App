import 'package:flutter/material.dart';

import '../design/tokens/kera_colors.dart';
import '../design/tokens/kera_radii.dart';

/// Standard branded Kera Spare logo widget used across headers.
///
/// Displays the official store logo from `assets/images/logo.png` with
/// an industrial rounded container and a fallback icon.
class KeraLogoWidget extends StatelessWidget {
  final double size;
  final double borderRadius;
  final Color backgroundColor;

  const KeraLogoWidget({
    super.key,
    this.size = 38,
    this.borderRadius = 8,
    this.backgroundColor = KeraColors.primaryNavyDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.precision_manufacturing_rounded,
          color: KeraColors.tealAccent,
          size: size * 0.55,
        ),
      ),
    );
  }
}
