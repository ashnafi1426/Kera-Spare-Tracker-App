import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/admin_typography.dart';

/// Reusable error state view with an icon, message, and retry button.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xl, vertical: AdminSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AdminColors.dangerTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AdminColors.danger,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Text(
              message,
              style: AdminTypography.body(isDark).copyWith(
                color: AdminColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AdminSpacing.lg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? l10n?.retry ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
