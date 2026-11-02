import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';

enum KeraButtonVariant {
  primary,
  secondary,
  teal,
  outlined,
  destructive,
}

/// Industrial high-contrast button with >=48px touch targets,
/// loading spinner support, and clear active/pressed feedback.
class KeraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KeraButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const KeraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KeraButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = KeraSpacing.minTouchTarget,
    this.padding,
  });

  const factory KeraButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isFullWidth,
    double height,
    EdgeInsetsGeometry? padding,
  }) = _KeraPrimaryButton;

  const factory KeraButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isFullWidth,
    double height,
    EdgeInsetsGeometry? padding,
  }) = _KeraSecondaryButton;

  const factory KeraButton.teal({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isFullWidth,
    double height,
    EdgeInsetsGeometry? padding,
  }) = _KeraTealButton;

  const factory KeraButton.outlined({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isFullWidth,
    double height,
    EdgeInsetsGeometry? padding,
  }) = _KeraOutlinedButton;

  const factory KeraButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isFullWidth,
    double height,
    EdgeInsetsGeometry? padding,
  }) = _KeraDestructiveButton;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case KeraButtonVariant.primary:
        bg = isEnabled ? KeraColors.actionBlue : KeraColors.outlineVariant;
        fg = isEnabled ? KeraColors.textWhite : KeraColors.textMuted;
        break;
      case KeraButtonVariant.secondary:
        bg = isEnabled ? KeraColors.primaryNavy : KeraColors.outlineVariant;
        fg = isEnabled ? KeraColors.textWhite : KeraColors.textMuted;
        break;
      case KeraButtonVariant.teal:
        bg = isEnabled ? KeraColors.utilityTeal : KeraColors.outlineVariant;
        fg = isEnabled ? KeraColors.textWhite : KeraColors.textMuted;
        break;
      case KeraButtonVariant.outlined:
        bg = Colors.transparent;
        fg = isEnabled ? KeraColors.primaryNavy : KeraColors.textMuted;
        side = BorderSide(
          color: isEnabled ? KeraColors.outlineBorder : KeraColors.outlineVariant,
          width: 1.5,
        );
        break;
      case KeraButtonVariant.destructive:
        bg = isEnabled ? KeraColors.error : KeraColors.outlineVariant;
        fg = isEnabled ? KeraColors.textWhite : KeraColors.textMuted;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: KeraSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: KeraTypography.labelLarge(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        style: KeraTypography.labelLarge(color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: KeraColors.surfaceMuted,
      disabledForegroundColor: KeraColors.textMuted,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(KeraSpacing.minTouchTarget, height),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: KeraRadii.borderButton,
        side: side,
      ),
    );

    final button = ElevatedButton(
      style: buttonStyle,
      onPressed: isEnabled ? onPressed : null,
      child: content,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: button,
    );
  }
}

class _KeraPrimaryButton extends KeraButton {
  const _KeraPrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.height,
    super.padding,
  }) : super(variant: KeraButtonVariant.primary);
}

class _KeraSecondaryButton extends KeraButton {
  const _KeraSecondaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.height,
    super.padding,
  }) : super(variant: KeraButtonVariant.secondary);
}

class _KeraTealButton extends KeraButton {
  const _KeraTealButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.height,
    super.padding,
  }) : super(variant: KeraButtonVariant.teal);
}

class _KeraOutlinedButton extends KeraButton {
  const _KeraOutlinedButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.height,
    super.padding,
  }) : super(variant: KeraButtonVariant.outlined);
}

class _KeraDestructiveButton extends KeraButton {
  const _KeraDestructiveButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading,
    super.isFullWidth,
    super.height,
    super.padding,
  }) : super(variant: KeraButtonVariant.destructive);
}

