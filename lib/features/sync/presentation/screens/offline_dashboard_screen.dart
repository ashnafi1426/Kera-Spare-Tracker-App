import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/local/app_database.dart';
import '../providers/sync_providers.dart';

/// Screen displaying the Offline & Pending Sync Dashboard.
///
/// Follows Google Stitch Screen 4 (Offline & Pending Sync Dashboard — ከመስመር ውጭ ዳሽቦርድ).
/// Implements local sales tallies, queue status, offline resilience assurances,
/// quick POS actions, and itemized pending transaction list.
class OfflineDashboardScreen extends ConsumerWidget {
  const OfflineDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final queueItemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountStreamProvider);
    final isOnlineAsync = ref.watch(isOnlineStreamProvider);
    final pushState = ref.watch(syncPushControllerProvider);

    final isOnline = isOnlineAsync.value ?? true;
    final pendingCount = pendingCountAsync.value ?? 0;
    final queueItems = queueItemsAsync.value ?? const [];

    // Calculate pending sales metrics from SQLite sync queue
    final saleItems = queueItems
        .where((item) => item.tableTarget == 'sales')
        .toList();
    final stockItems = queueItems
        .where((item) => item.tableTarget == 'stock_movements')
        .toList();

    double totalPendingSalesAmount = 0.0;
    for (final item in saleItems) {
      try {
        final decoded = jsonDecode(item.payload);
        if (decoded is Map<String, dynamic>) {
          final amt = decoded['total_amount'] ?? decoded['totalAmount'];
          if (amt is num) {
            totalPendingSalesAmount += amt.toDouble();
          }
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ኬራ ስፔር / Kera Spare',
              style: KeraTypography.titleMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'ከመስመር ውጭ ዳሽቦርድ / Offline Dashboard',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          // Pending Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'ያልተላከ ($pendingCount)',
                  style: KeraTypography.labelSmall(
                    color: const Color(0xFFF59E0B),
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: pushState.isPushing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sync / ደጋግም',
            onPressed: pushState.isPushing
                ? null
                : () async {
                    final success = await ref
                        .read(syncPushControllerProvider.notifier)
                        .pushNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'የዳታ ማመሳሰል በተሳካ ሁኔታ ተጠናቋል!'
                                : (isOnline
                                    ? 'ማመሳሰል አልተሳካም፤ እባክዎ እንደገና ይሞክሩ።'
                                    : 'ኔትወርክ አልተገኘም (Offline)። መረጃዎች በመሳሪያው ላይ ተቀምጠዋል።'),
                          ),
                          backgroundColor: success
                              ? KeraColors.successGreen
                              : (isOnline
                                  ? KeraColors.errorRed
                                  : KeraColors.warningAmber),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncPushControllerProvider.notifier).pushNow();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // 1. Prominent Warning Offline Banner (Stitch Screen 4)
            _buildOfflineAlertBanner(context, ref, isOnline, pendingCount),
            const SizedBox(height: 14),

            // 2. Local Sync Queue Bento Card
            _buildSyncQueueBentoCard(
              context,
              pendingCount: pendingCount,
              salesCount: saleItems.length,
              salesTotal: totalPendingSalesAmount,
              stockCount: stockItems.length,
            ),
            const SizedBox(height: 14),

            // 3. Adjusted Local Figures / Local Stats
            _buildLocalStatsSection(
              salesTotal: totalPendingSalesAmount,
              salesCount: saleItems.length,
              pendingCount: pendingCount,
            ),
            const SizedBox(height: 14),

            // 4. Quick Actions (Optimized for Offline Operations)
            _buildQuickActions(context),
            const SizedBox(height: 18),

            // 5. Offline Transaction Feed (Itemized Pending Items)
            _buildPendingFeedSection(
              context,
              queueItems: queueItems,
              pendingCount: pendingCount,
            ),
            const SizedBox(height: 16),

            // 6. Persistent Storage Engine Details / Resilience Box
            _buildResilienceBox(pendingCount),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineAlertBanner(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
    int pendingCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.all(14),
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
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wifi_off,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOnline ? 'ማመሳሰል በመጠባበቅ ላይ' : 'ከመስመር ውጭ ይሰራል',
                          style: KeraTypography.labelLarge(
                            color: const Color(0xFF92400E),
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline
                              ? '(Sync In Progress)'
                              : '(Offline Mode Active)',
                          style: KeraTypography.labelSmall(
                            color: const Color(0xFFB45309),
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount ያልተላኩ ሽያጮች እና የክምችት ለውጦች በስልክዎ ላይ ተቀምጠዋል',
                      style: KeraTypography.bodySmall(
                        color: const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '($pendingCount pending transactions stored locally. Auto-syncs when reconnects)',
                      style: KeraTypography.labelSmall(
                        color: const Color(0xFF92400E).withValues(alpha: 0.8),
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Color(0xFFD97706),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ከመስመር ውጭ • $pendingCount በመጠባበቅ ላይ',
                        style: KeraTypography.labelSmall(
                          color: const Color(0xFFB45309),
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await ref
                        .read(syncPushControllerProvider.notifier)
                        .pushNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'ሁሉም መረጃዎች በተሳካ ሁኔታ ተመሳስለዋል!'
                                : (isOnline
                                    ? 'ማመሳሰል አልተሳካም፤ አውታረ መረብዎን ይፈትሹ።'
                                    : 'ኔትወርክ አልተገኘም (Offline)። መረጃዎች በስልኩ ማህደረ-ትውስታ ደህንነታቸው ተጠብቋል'),
                          ),
                          backgroundColor: success
                              ? KeraColors.successGreen
                              : (isOnline
                                  ? KeraColors.errorRed
                                  : KeraColors.warningAmber),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'አሁን ሞክር (Retry Sync)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncQueueBentoCard(
    BuildContext context, {
    required int pendingCount,
    required int salesCount,
    required double salesTotal,
    required int stockCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KeraColors.borderLight.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.cloud_sync,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'የመጠባበቂያ ወረፋ',
                        style: KeraTypography.titleMedium()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '(Offline Synchronization Queue)',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KeraColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Queue #$pendingCount',
                  style: KeraTypography.labelSmall().copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Split Metric
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: KeraColors.borderLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ሽያጮች (Sales)',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textSecondary,
                            ).copyWith(fontSize: 11),
                          ),
                          const Icon(
                            Icons.receipt,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$salesCount ሽያጭ',
                        style: KeraTypography.headlineSmall()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(salesTotal),
                        style: KeraTypography.labelSmall(
                          color: const Color(0xFF2563EB),
                        ).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: KeraColors.borderLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ማስተካከያ (Stock)',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textSecondary,
                            ).copyWith(fontSize: 11),
                          ),
                          const Icon(
                            Icons.inventory,
                            color: Color(0xFFD97706),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$stockCount እቃዎች',
                        style: KeraTypography.headlineSmall()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adjustments cached',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Security stamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: KeraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KeraColors.borderLight.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SQLite Encrypted • 100% Safe Offline',
                      style: KeraTypography.labelSmall().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Secure Local DB',
                  style: KeraTypography.labelSmall(
                    color: const Color(0xFF16A34A),
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Operational Reassurance Callout
          InkWell(
            onTap: () => context.push('/sales/new'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: KeraColors.primaryNavyDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6BD8CB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ከኢንተርኔት ውጭ ሽያጭ መመዝገብ ይቀጥሉ',
                          style: KeraTypography.labelMedium(
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '(Continue Selling Offline without interruption)',
                          style: KeraTypography.labelSmall(
                            color: const Color(0xFF8093BB),
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF8093BB),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalStatsSection({
    required double salesTotal,
    required int salesCount,
    required int pendingCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የአካባቢ መረጃ ማጠቃለያ (Local Stats)',
              style: KeraTypography.titleMedium()
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'ዛሬ (Today)',
              style: KeraTypography.labelSmall(
                color: KeraColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KeraColors.borderLight.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ዛሬ ሽያጭ (Local Sales)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.payments,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(salesTotal),
                      style: KeraTypography.titleMedium()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.pending,
                          color: Color(0xFFD97706),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$salesCount receipts pending',
                          style: KeraTypography.labelSmall(
                            color: const Color(0xFFD97706),
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KeraColors.borderLight.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'በአካባቢ የተያዘ (Local Orders)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.receipt_long,
                          color: KeraColors.primaryNavyDark,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$pendingCount ደረሰኞች',
                      style: KeraTypography.titleMedium()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.storage,
                          color: KeraColors.textSecondary,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'In Local Buffer',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Catalog Warning Alert
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notification_important,
                color: Color(0xFFD97706),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'የክምችት ማንቂያ (Catalog Alert): ከመስመር ውጭ ካታሎግ ዝግጁ ነው (Cached catalog live)',
                  style: KeraTypography.labelSmall(
                    color: const Color(0xFF78350F),
                  ).copyWith(fontSize: 11),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD97706),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ፈጣን ተግባራት (Offline Actions)',
          style: KeraTypography.titleMedium()
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Action 1: Cash POS
            Expanded(
              child: InkWell(
                onTap: () => context.push('/sales/new'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ፈጣን ሽያጭ',
                        style: KeraTypography.labelMedium(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Cash POS',
                        style: KeraTypography.labelSmall(
                          color: Colors.white.withValues(alpha: 0.8),
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Action 2: Bluetooth Printer
            Expanded(
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'የብሉቱዝ ፕሪንተር ዝግጁ ነው (Thermal BT Printer Ready)',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: KeraColors.primaryNavyDark,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bluetooth,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ደረሰኝ አትም',
                        style: KeraTypography.labelMedium(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'BT Printer',
                        style: KeraTypography.labelSmall(
                          color: Colors.white.withValues(alpha: 0.8),
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Action 3: Cached Inventory Search
            Expanded(
              child: InkWell(
                onTap: () => context.go('/home'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KeraColors.borderLight.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: KeraColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search,
                          color: KeraColors.primaryNavyDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ዕቃ ፈልግ',
                        style: KeraTypography.labelMedium()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Local Search',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingFeedSection(
    BuildContext context, {
    required List<SyncQueueItem> queueItems,
    required int pendingCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'ያልተላኩ የሽያጭ ደረሰኞች',
                  style: KeraTypography.titleMedium()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount ወረፋ',
                    style: KeraTypography.labelSmall(
                      color: const Color(0xFFB45309),
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/sync'),
              child: const Text(
                'ሁሉንም እይ',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (queueItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KeraColors.borderLight.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: KeraColors.successGreen,
                  size: 38,
                ),
                const SizedBox(height: 8),
                Text(
                  'ምንም ያልተላከ ደረሰኝ የለም',
                  style: KeraTypography.titleMedium()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'All offline changes are completely synchronized.',
                  style: KeraTypography.labelSmall(
                    color: KeraColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...queueItems.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return _buildPendingItemTile(index, item);
          }),

        if (queueItems.length > 5) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: KeraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KeraColors.borderLight.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'ተጨማሪ ${queueItems.length - 5} ያልተላኩ መዝገቦች በአካባቢው ዳታቤዝ ውስጥ ይገኛሉ (+${queueItems.length - 5} more pending)',
              style: KeraTypography.labelSmall(
                color: KeraColors.textSecondary,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPendingItemTile(int index, SyncQueueItem item) {
    String title = 'ደረሰኝ መዝገብ #${item.recordId.substring(0, 6.clamp(0, item.recordId.length))}';
    String subtitle = 'ጥሬ ገንዘብ (Cash)';
    String amountStr = '';

    try {
      final decoded = jsonDecode(item.payload);
      if (decoded is Map<String, dynamic>) {
        if (item.tableTarget == 'sales') {
          final receipt = decoded['receipt_number'] ?? decoded['receiptNumber'];
          final amt = decoded['total_amount'] ?? decoded['totalAmount'];
          final payment = decoded['payment_method'] ?? decoded['paymentMethod'] ?? 'Cash';
          if (receipt != null) title = 'ደረሰኝ #$receipt';
          if (amt is num) amountStr = CurrencyFormatter.format(amt.toDouble());
          subtitle = '$payment • ${_formatTime(item.createdAt)}';
        } else if (item.tableTarget == 'stock_movements') {
          title = 'የክምችት ማስተካከያ (${decoded['note'] ?? 'Stock'})';
          subtitle = '${decoded['quantity_change'] ?? ''} ቆጠራ • ${_formatTime(item.createdAt)}';
          amountStr = 'የቆጠራ ለውጥ';
        } else {
          title = decoded['name_am'] ?? decoded['name_en'] ?? item.tableTarget;
          subtitle = '${item.operation.name.toUpperCase()} • ${_formatTime(item.createdAt)}';
        }
      }
    } catch (_) {}

    final indexStr = index < 10 ? '#0$index' : '#$index';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KeraColors.borderLight.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KeraColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              indexStr,
              style: KeraTypography.labelSmall().copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: KeraColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KeraTypography.labelLarge()
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KeraTypography.labelSmall(
                    color: KeraColors.textSecondary,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (amountStr.isNotEmpty)
                Text(
                  amountStr,
                  style: KeraTypography.labelLarge()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'በመጠባበቅ ላይ',
                      style: KeraTypography.labelSmall(
                        color: const Color(0xFFD97706),
                      ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
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

  Widget _buildResilienceBox(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KeraColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KeraColors.borderLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storage,
            color: Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'የዳታ ደህንነት ማረጋገጫ (Offline Resilience)',
                  style: KeraTypography.labelMedium()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'ስልክዎ ባትሪ ቢጨርስ ወይም ቢጠፋ፣ ሁሉም $pendingCount ሽያጮች እና የዋጋ መዝገቦች በመሳሪያው ላይ ሳይጠፉ ይቆያሉ። የኢንተርኔት ግንኙነት እንደተመለሰ ወደ ዋናው ሰርቨር ወዲያውኑ ይላካሉ።',
                  style: KeraTypography.bodySmall(
                    color: KeraColors.textSecondary,
                  ).copyWith(fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

