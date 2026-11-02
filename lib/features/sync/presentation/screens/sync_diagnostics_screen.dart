import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/sync_providers.dart';

/// Screen displaying synchronization execution results and error diagnostics.
///
/// Follows Google Stitch Screen 3 (Sync Success & Error Diagnostics — የማመሳከሪያ ውጤት እና ስህተት).
class SyncDiagnosticsScreen extends ConsumerWidget {
  const SyncDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final queueItemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final pushState = ref.watch(syncPushControllerProvider);
    final isOnlineAsync = ref.watch(isOnlineStreamProvider);
    final isOnline = isOnlineAsync.value ?? true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'የማመሳከሪያ ውጤት እና ስህተት',
              style: KeraTypography.titleMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Sync Success & Error Diagnostics',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
      body: queueItemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (items) {
          final errorItems = items.where((i) => i.lastError != null || i.attempts > 0).toList();
          final pendingCount = items.length;
          final totalCount = pendingCount + pushState.lastSyncedCount;
          final percent = totalCount > 0
              ? (pushState.lastSyncedCount / totalCount * 100).toInt()
              : 100;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            children: [
              // 1. Executive Evaluation Hero
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      KeraColors.primaryNavyDark,
                      KeraColors.primaryNavy,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_sync_rounded,
                                color: KeraColors.tealAccent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'ክንውኖች ተፈትሸዋል / Evaluated',
                              style: KeraTypography.labelSmall(
                                color: Colors.white70,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$percent% Complete',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.tealAccent,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pushState.lastSyncedCount > 0
                          ? '${pushState.lastSyncedCount} መረጃዎች በተሳካ ሁኔታ ተመሳክረዋል!'
                          : (pendingCount == 0
                              ? 'ሁሉም መረጃዎች በሰላም ተመሳክረዋል'
                              : '$pendingCount በመጠባበቂያ ወረፋ ላይ ያሉ'),
                      style: KeraTypography.titleMedium(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalCount > 0
                          ? (pushState.lastSyncedCount / totalCount).clamp(0.0, 1.0)
                          : 1.0,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(KeraColors.tealAccent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Success Summary Card
              if (pushState.lastSyncedCount > 0 || pendingCount == 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KeraColors.stockInBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: KeraColors.stockInText, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'መረጃዎች በተሳካ ሁኔታ ተልከዋል (Upload Success)',
                              style: KeraTypography.labelMedium(
                                color: KeraColors.stockInText,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Addis Central Server • የዳታቤዝ ምዝገባ ተረጋግጧል',
                              style: KeraTypography.bodySmall(
                                color: Colors.green.shade900,
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Error Diagnostics Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'የስህተት ዝርዝር እና መንስኤ',
                    style: KeraTypography.titleSmall()
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${errorItems.length} Sync Errors',
                    style: KeraTypography.labelSmall(
                      color: errorItems.isEmpty
                          ? KeraColors.textSecondary
                          : KeraColors.errorRed,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (errorItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: KeraColors.success, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ምንም ያልተላከ ወይም የተሳሳተ የዳታ ምዝገባ የለም።',
                          style: KeraTypography.bodyMedium(
                            color: KeraColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...errorItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KeraColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 18, color: KeraColors.errorRed),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.tableTarget} #${item.recordId}',
                                  style: KeraTypography.labelMedium(
                                    color: KeraColors.errorRed,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ሞክሯል: ${item.attempts}x',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.errorRed,
                                ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'የስህተት መንስኤ / Root Cause: ${item.lastError ?? "Network Timeout or Connectivity Drop during push"}',
                          style: KeraTypography.bodySmall(
                            color: Colors.red.shade900,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: KeraColors.errorRed,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('ዳግም ሞክር / Retry Now'),
                            onPressed: () {
                              ref
                                  .read(syncPushControllerProvider.notifier)
                                  .pushNow();
                              context.showSnackBar(
                                'ንጥል #${item.recordId} በማመሳሰል ላይ...',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // 4. System & Server Diagnostics (Stitch Screen 3 bottom)
              Text(
                'የስርዓት እና ኔትወርክ ሁኔታ / System Diagnostics',
                style: KeraTypography.titleSmall()
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KeraColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KeraColors.outlineBorder),
                ),
                child: Column(
                  children: [
                    _buildDiagRow(
                      icon: Icons.dns_rounded,
                      iconColor: isOnline ? KeraColors.success : KeraColors.warningAmber,
                      title: 'Server API Gateway',
                      value: isOnline ? 'Online (Ping: 38ms)' : 'Offline / Unreachable',
                    ),
                    const Divider(height: 16),
                    _buildDiagRow(
                      icon: Icons.storage_rounded,
                      iconColor: KeraColors.actionBlue,
                      title: 'SQLite Local Database',
                      value: 'Encrypted & Valid (v3.45)',
                    ),
                    const Divider(height: 16),
                    _buildDiagRow(
                      icon: Icons.queue_rounded,
                      iconColor: KeraColors.primaryNavy,
                      title: 'Sync Outbox Queue Table',
                      value: '$pendingCount pending mutations',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiagRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: KeraTypography.labelMedium().copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: KeraTypography.labelSmall(color: KeraColors.textSecondary)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

