import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';

/// Offline & Pending Sync Banner matching Stitch Screen 9.
///
/// Displayed prominently when the local SQLite queue contains pending mutations
/// or the device is running disconnected. Builds trust and provides manual sync retry.
class DashboardOfflineBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onRetrySync;
  final VoidCallback? onInspectQueue;

  const DashboardOfflineBanner({
    super.key,
    required this.pendingCount,
    required this.onRetrySync,
    this.onInspectQueue,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: KeraSpacing.lg,
        vertical: KeraSpacing.sm,
      ),
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Light amber tint from Stitch
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(
          color: KeraColors.warningAmber.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KeraColors.warningAmber.withValues(alpha: 0.2),
                  borderRadius: KeraRadii.borderMicro,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
              ),
              const SizedBox(width: KeraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ከመስመር ውጭ ይሰራል',
                          style: KeraTypography.titleMedium().copyWith(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Offline Mode)',
                          style: KeraTypography.labelSmall().copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount ያልተላኩ ሽያጮች እና የክምችት ለውጦች በስልክዎ ላይ ተቀምጠዋል',
                      style: KeraTypography.bodySmall().copyWith(
                        color: const Color(0xFF78350F),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '($pendingCount pending transactions stored locally. Auto-syncs when online)',
                      style: KeraTypography.labelSmall().copyWith(
                        color: const Color(0xFF92400E).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: KeraSpacing.sm),
          const Divider(height: 1, color: Color(0x33F59E0B)),
          const SizedBox(height: KeraSpacing.sm),

          // Action row: Status pill + Retry button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Offline Amber Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KeraRadii.borderPill,
                  border: Border.all(
                    color: KeraColors.warningAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pendingCount በመጠባበቅ ላይ',
                      style: KeraTypography.labelSmall().copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Manual Retry Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KeraRadii.xs),
                  ),
                ),
                onPressed: onRetrySync,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'አሁን ሞክር (Retry)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
