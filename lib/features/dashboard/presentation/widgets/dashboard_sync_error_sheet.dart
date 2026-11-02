import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_button.dart';

/// Modal bottom sheet for sync error diagnostics matching Stitch Screen 11.
class DashboardSyncErrorSheet extends StatelessWidget {
  final int pendingCount;
  final String? lastSyncTime;
  final VoidCallback onContinueLocal;
  final VoidCallback onRetryReconnect;

  const DashboardSyncErrorSheet({
    super.key,
    required this.pendingCount,
    this.lastSyncTime,
    required this.onContinueLocal,
    required this.onRetryReconnect,
  });

  static Future<void> show(
    BuildContext context, {
    required int pendingCount,
    String? lastSyncTime,
    required VoidCallback onContinueLocal,
    required VoidCallback onRetryReconnect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DashboardSyncErrorSheet(
        pendingCount: pendingCount,
        lastSyncTime: lastSyncTime,
        onContinueLocal: () {
          Navigator.of(ctx).pop();
          onContinueLocal();
        },
        onRetryReconnect: () {
          Navigator.of(ctx).pop();
          onRetryReconnect();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KeraColors.surfaceCard,
        borderRadius: KeraRadii.borderSheet,
      ),
      padding: const EdgeInsets.all(KeraSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KeraColors.borderNeutral,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: KeraSpacing.md),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KeraColors.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(KeraRadii.xs),
                  ),
                  child: const Icon(
                    Icons.sync_problem_rounded,
                    color: KeraColors.errorRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: KeraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ማመሳሰል አልተሳካም',
                        style: KeraTypography.titleMedium().copyWith(
                          fontWeight: FontWeight.bold,
                          color: KeraColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Synchronization Failed (Network Timeout)',
                        style: KeraTypography.labelSmall().copyWith(
                          color: KeraColors.errorRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: KeraSpacing.md),

            // Diagnostic Breakdown Card
            Container(
              padding: const EdgeInsets.all(KeraSpacing.md),
              decoration: BoxDecoration(
                color: KeraColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(KeraRadii.md),
                border: Border.all(color: KeraColors.borderVariant),
              ),
              child: Column(
                children: [
                  _DiagnosticRow(
                    label: 'የመጨረሻ ማመሳሰል / Last Synced:',
                    value: lastSyncTime ?? '42 ደቂቃ በፊት',
                    valueColor: KeraColors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  _DiagnosticRow(
                    label: 'ያልተላኩ መዝገቦች / Pending Queue:',
                    value: '$pendingCount ደረሰኞች ($pendingCount items)',
                    valueColor: KeraColors.errorRed,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  const _DiagnosticRow(
                    label: 'የአውታረ መረብ ሁኔታ / Network:',
                    value: 'Ethio Telecom (Edge / Unstable)',
                    valueColor: Color(0xFFD97706),
                  ),
                ],
              ),
            ),

            const SizedBox(height: KeraSpacing.md),

            // Offline Guarantee Explanation
            Text(
              'የአካባቢ ዳታቤዝ (Local SQLite) ደህንነቱ በተጠበቀ ሁኔታ እየሰራ ነው። ሽያጮችን ማስመዝገብ መቀጠል ይችላሉ፤ ግንኙነቱ ሲመለስ በራስ-ሰር ይላካሉ።',
              style: KeraTypography.bodySmall().copyWith(
                color: KeraColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: KeraSpacing.lg),

            // Actions
            KeraButton(
              label: 'በአካባቢ ዳታ ይቀጥሉ (Continue with Local DB)',
              onPressed: onContinueLocal,
              icon: Icons.offline_pin_rounded,
              variant: KeraButtonVariant.primary,
            ),
            const SizedBox(height: KeraSpacing.sm),
            KeraButton(
              label: 'እንደገና አገናኝ (Reconnect Server)',
              onPressed: onRetryReconnect,
              icon: Icons.refresh_rounded,
              variant: KeraButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: KeraTypography.labelSmall().copyWith(
              color: KeraColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: KeraTypography.labelSmall().copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
