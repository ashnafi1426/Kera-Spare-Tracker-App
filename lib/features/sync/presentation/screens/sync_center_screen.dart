import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/tables/enums.dart';
import '../providers/sync_providers.dart';

/// Screen displaying the offline synchronization center and pending queue.
///
/// Follows Google Stitch Screen 1 (Sync Center & Queue — የዳታ ማመሳከሪያ ማዕከል).
class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final queueItemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountStreamProvider);
    final isOnlineAsync = ref.watch(isOnlineStreamProvider);
    final pushState = ref.watch(syncPushControllerProvider);
    final conflicts = ref.watch(activeConflictsProvider);

    final isOnline = isOnlineAsync.value ?? true;
    final pendingCount = pendingCountAsync.value ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'የዳታ ማመሳከሪያ ማዕከል',
              style: KeraTypography.titleMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Sync Center & Outbox Queue',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          // Online / Offline Status Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF00322D)
                  : KeraColors.warningAmberBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOnline
                    ? KeraColors.tealAccent.withValues(alpha: 0.3)
                    : KeraColors.warningAmberBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? KeraColors.tealAccent
                        : KeraColors.warningAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'በመስመር ላይ / Online' : 'ከመስመር ውጭ / Offline',
                  style: KeraTypography.labelSmall(
                    color: isOnline ? Colors.white : KeraColors.warningAmber,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncPushControllerProvider.notifier).pushNow();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            // 1. Status Hero Banner (Stitch Screen 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [KeraColors.primaryNavyDark, KeraColors.primaryNavy]
                      : [Colors.blueGrey.shade900, Colors.blueGrey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: KeraColors.primaryNavy.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
                            color: isOnline
                                ? KeraColors.tealAccent
                                : Colors.amber.shade300,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline
                                ? 'የዳታ ማስተላለፊያ ዝግጁ ነው'
                                : 'ከመስመር ውጭ (Offline Mode)',
                            style: KeraTypography.labelMedium(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pendingCount > 0
                              ? Colors.amber.shade400
                              : KeraColors.tealAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$pendingCount Pending',
                          style: KeraTypography.labelSmall(
                            color: Colors.black87,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pendingCount > 0
                        ? '$pendingCount የዳታ ለውጦች አልተላኩም'
                        : 'ሁሉም የቅርብ ለውጦች ወደ ሰርቨር ተመሳክረዋል',
                    style: KeraTypography.titleMedium(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ሁሉም ለውጦች በስልክዎ (SQLite) ውስጥ በሰላም ተቀምጠዋል። ኢንተርኔት ሲገኝ በራሱ ይላካል።',
                    style: KeraTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.8),
                    ).copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),

                  // Push Button & Status
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KeraColors.actionBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: pushState.isPushing
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(syncPushControllerProvider.notifier)
                                        .pushNow();
                                    if (context.mounted) {
                                      if (success) {
                                        context.showSnackBar(
                                          'የዳታ ማመሳሰል በተሳካ ሁኔታ ተጠናቋል / Sync Complete',
                                        );
                                      } else {
                                        context.showSnackBar(
                                          pushState.lastError ??
                                              'ማመሳሰል አልተሳካም / Sync Failed',
                                          isError: true,
                                        );
                                      }
                                    }
                                  },
                            icon: pushState.isPushing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 20),
                            label: Text(
                              pushState.isPushing
                                  ? 'በማመሳሰል ላይ...'
                                  : 'አሁን ሞክር / Sync Now',
                              style: KeraTypography.labelMedium(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        tooltip: 'Diagnostics',
                        onPressed: () => context.push('/sync/diagnostics'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Conflict Alert Banner (If Conflicts Exist)
            if (conflicts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KeraColors.warningAmberBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KeraColors.warningAmberBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded,
                        color: KeraColors.warningAmber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${conflicts.length} የዳታ ግጭት ተገኝቷል (Conflict Alert)',
                            style: KeraTypography.labelMedium(
                              color: KeraColors.warningAmber,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'በስልክዎ እና በሰርቨሩ መካከል ልዩነት ተፈጥሯል። እባክዎ ውሳኔ ይስጡ።',
                            style: KeraTypography.bodySmall(
                              color: Colors.brown.shade800,
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeraColors.warningAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => context.push('/sync/conflicts'),
                      child: const Text('ፍታ / Resolve'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Pending Categories Breakdown (Stitch Screen 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ያልተላኩ መረጃዎች ዝርዝር',
                  style: KeraTypography.titleSmall()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Pending Categories',
                  style: KeraTypography.bodySmall(
                    color: KeraColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            queueItemsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(err.toString()),
              data: (items) {
                final salesItems =
                    items.where((i) => i.tableTarget == 'sales').toList();
                final partsItems = items
                    .where((i) =>
                        i.tableTarget == 'spare_parts' &&
                        i.operation == SyncOperation.insert)
                    .toList();
                final stockItems = items
                    .where((i) => i.tableTarget == 'stock_movements')
                    .toList();
                final updateItems = items
                    .where((i) =>
                        i.tableTarget == 'spare_parts' &&
                        i.operation.name == 'update')
                    .toList();

                return Column(
                  children: [
                    _buildCategoryCard(
                      context,
                      icon: Icons.point_of_sale_rounded,
                      iconColor: KeraColors.actionBlue,
                      title: 'ያልተላኩ ሽያጮች (Offline Sales)',
                      subtitle: '${salesItems.length} ደረሰኞች በመጠባበቅ ላይ',
                      countText: '${salesItems.length} ደረሰኞች',
                      onTap: () => context.push('/sync/offline'),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.new_label_rounded,
                      iconColor: Colors.teal.shade700,
                      title: 'አዲስ የተመዘገቡ ዕቃዎች (New Parts)',
                      subtitle: '${partsItems.length} አዳዲስ መለዋወጫዎች በስልክ ተመዝግበዋል',
                      countText: '${partsItems.length} አዳዲስ',
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.warehouse_rounded,
                      iconColor: Colors.orange.shade800,
                      title: 'የክምችት ማስተካከያዎች (Stock Movements)',
                      subtitle: '${stockItems.length} የክምችት ጭማሪ እና ቅነሳ እንቅስቃሴዎች',
                      countText: '${stockItems.length} እንቅስቃሴዎች',
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.price_change_rounded,
                      iconColor: Colors.purple.shade700,
                      title: 'የተሻሻሉ መረጃዎች (Metadata & Price Edits)',
                      subtitle: '${updateItems.length} የዋጋ እና ዝርዝር ማሻሻያዎች',
                      countText: '${updateItems.length} ማሻሻያ',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 4. Quick Module Shortcuts
            Row(
              children: [
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.offline_bolt_rounded,
                    label: 'ከመስመር ውጭ\nዳሽቦርድ',
                    onTap: () => context.push('/sync/offline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.compare_arrows_rounded,
                    label: 'የዳታ ግጭት\nመፍቻ ገጽ',
                    onTap: () => context.push('/sync/conflicts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.dns_rounded,
                    label: 'የሰርቨር እና\nዲያግኖስቲክስ',
                    onTap: () => context.push('/sync/diagnostics'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. System Health & Storage Footnote (Stitch Screen 1 bottom)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KeraColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KeraColors.outlineBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: KeraColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Addis Central Server • SQLite Cache Valid',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.primaryNavy,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'የአካባቢ ዳታቤዝ (Drift SQLite) ጤናማ እና የተጠበቀ ነው',
                          style: KeraTypography.bodySmall(
                            color: KeraColors.textSecondary,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String countText,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KeraColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KeraColors.outlineBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KeraTypography.labelMedium()
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: KeraTypography.bodySmall(
                      color: KeraColors.textSecondary,
                    ).copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: KeraColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                countText,
                style: KeraTypography.labelSmall(
                  color: KeraColors.primaryNavy,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: KeraColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KeraColors.outlineBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: KeraColors.actionBlue),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KeraTypography.labelSmall().copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

