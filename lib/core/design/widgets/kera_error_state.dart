import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';
import 'kera_button.dart';

/// Reusable error state view displaying an error icon, localized message,
/// optional error code badge, and retry/secondary action buttons.
class KeraErrorState extends StatelessWidget {
  final String message;
  final String? title;
  final String? errorCode;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;

  const KeraErrorState({
    super.key,
    required this.message,
    this.title,
    this.errorCode,
    this.onRetry,
    this.retryLabel = 'እንደገና ይሞክሩ (Retry)',
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KeraSpacing.xl,
          vertical: KeraSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon in red tonal circle
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: KeraColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: KeraColors.error,
              ),
            ),
            const SizedBox(height: KeraSpacing.lg),

            // Optional Title
            if (title != null) ...[
              Text(
                title!,
                style: KeraTypography.headlineSmall(color: KeraColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KeraSpacing.xs),
            ],

            // Message
            Text(
              message,
              style: KeraTypography.bodyLarge(color: KeraColors.textPrimary),
              textAlign: TextAlign.center,
            ),

            // Optional Error Code Badge
            if (errorCode != null && errorCode!.isNotEmpty) ...[
              const SizedBox(height: KeraSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: KeraColors.surfaceMuted,
                  borderRadius: KeraRadii.borderMicro,
                ),
                child: Text(
                  errorCode!,
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],

            // Action Buttons
            if (onRetry != null || onSecondaryAction != null) ...[
              const SizedBox(height: KeraSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onSecondaryAction != null && secondaryActionLabel != null) ...[
                    Flexible(
                      child: KeraButton.outlined(
                        label: secondaryActionLabel!,
                        icon: secondaryActionIcon,
                        onPressed: onSecondaryAction,
                        isFullWidth: false,
                      ),
                    ),
                    const SizedBox(width: KeraSpacing.md),
                  ],
                  if (onRetry != null) ...[
                    Flexible(
                      child: KeraButton.primary(
                        label: retryLabel,
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry,
                        isFullWidth: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

