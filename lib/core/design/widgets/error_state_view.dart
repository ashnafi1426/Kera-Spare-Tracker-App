import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import 'secondary_button.dart';

/// Reusable error state view with retry trigger.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRetryLabel =
        retryLabel ?? AppLocalizations.of(context)?.tryAgain ?? 'Try Again';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: KeraColors.orange100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: KeraColors.orange700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SecondaryButton(
                label: effectiveRetryLabel,
                icon: Icons.refresh_rounded,
                width: 200,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

