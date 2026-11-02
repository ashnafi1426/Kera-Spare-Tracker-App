import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';

/// Top header banner for the business dashboard.
///
/// Features:
/// - Store branding: "ኬራ ስፔር / Kera Spare"
/// - Business Persona avatar with initials & shop title
/// - Live connectivity and sync status indicator
class DashboardHeader extends StatelessWidget {
  final String businessName;
  final String? phoneNumber;
  final int pendingSyncCount;
  final VoidCallback? onSyncTap;
  final VoidCallback? onNotificationTap;

  const DashboardHeader({
    super.key,
    required this.businessName,
    this.phoneNumber,
    this.pendingSyncCount = 0,
    this.onSyncTap,
    this.onNotificationTap,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'KS';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second';
    }
    return trimmed.length > 2 ? trimmed.substring(0, 2) : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isSynced = pendingSyncCount == 0;
    final initials = _getInitials(businessName);

    return Container(
      color: KeraColors.primaryNavy,
      padding: const EdgeInsets.symmetric(
        horizontal: KeraSpacing.lg,
        vertical: KeraSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: App Name & Action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: KeraRadii.borderMicro,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KeraSpacing.sm),
                  Text(
                    'ኬራ ስፔር / Kera Spare',
                    style: KeraTypography.titleMedium().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isSynced
                          ? Icons.sync_rounded
                          : Icons.sync_problem_rounded,
                      color: isSynced
                          ? Colors.white
                          : KeraColors.warningAmber,
                    ),
                    tooltip: 'Sync',
                    onPressed: onSyncTap,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Notifications',
                    onPressed: onNotificationTap,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: KeraSpacing.sm),

          // Business Persona & Store details
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: KeraColors.actionBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: KeraTypography.titleMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isSynced
                            ? KeraColors.tealAccent
                            : KeraColors.warningAmber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KeraColors.primaryNavy,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: KeraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName.isNotEmpty
                          ? businessName
                          : 'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ',
                      style: KeraTypography.headlineSmall().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneNumber != null && phoneNumber!.isNotEmpty
                          ? '$phoneNumber • ኬራ መገናኛ'
                          : 'Tesfaye Auto Spares • Kera Zone',
                      style: KeraTypography.labelSmall().copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: KeraSpacing.md),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: KeraSpacing.sm),

          // Greeting & Live Sync status pill strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'እንደምን ዋሉ',
                          style: KeraTypography.bodySmall().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    Text(
                      'ዛሬ • Today',
                      style: KeraTypography.labelSmall().copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: KeraRadii.borderPill,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isSynced
                            ? KeraColors.tealAccent
                            : KeraColors.warningAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSynced
                          ? 'የመስመር ላይ • የተመሳሰለ'
                          : 'ያልተላከ ($pendingSyncCount)',
                      style: KeraTypography.labelSmall().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSynced ? Icons.done_all_rounded : Icons.pending_rounded,
                      color: isSynced
                          ? KeraColors.tealAccent
                          : KeraColors.warningAmber,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
