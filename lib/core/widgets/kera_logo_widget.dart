import 'package:flutter/material.dart';
import '../design/tokens/kera_colors.dart';

/// Standard branded Kera Spare logo widget used across headers.
///
/// Displays the official store logo from `assets/images/logo.png` with
/// a clean light background plate ensuring maximum legibility in both light and dark modes.
class KeraLogoWidget extends StatelessWidget {
  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final bool showShadow;
  final EdgeInsetsGeometry? padding;

  const KeraLogoWidget({
    super.key,
    this.size = 38,
    this.borderRadius = 8,
    this.backgroundColor,
    this.showShadow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? Colors.white;

    // In tests, avoid hanging ImageStream decoder
    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      padding: padding ?? EdgeInsets.all(size * 0.08),
      clipBehavior: Clip.antiAlias,
      child: isTestEnvironment
          ? Icon(
              Icons.precision_manufacturing_rounded,
              color: KeraColors.navy800,
              size: size * 0.6,
            )
          : Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.precision_manufacturing_rounded,
                color: KeraColors.primaryNavy,
                size: size * 0.6,
              ),
            ),
    );
  }
}
