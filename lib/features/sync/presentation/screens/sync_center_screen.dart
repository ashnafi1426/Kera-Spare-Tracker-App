import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../data/local/tables/enums.dart';
import '../providers/sync_providers.dart';

/// Screen displaying the offline synchronization center and pending queue.
///
/// Follows Google Stitch Screen 1 (Sync Center & Queue — የዳታ ማመሳከሪያ ማዕከል).
class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAmharic = context.isAmharic;
    final queueItemsAsync = ref.watch(syncQueueItemsStreamProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountStreamProvider);
    final isOnlineAsync = ref.watch(isOnlineStreamProvider);
    final pushState = ref.watch(syncPushControllerProvider);
    final conflicts = ref.watch(activeConflictsProvider);

    final isOnline = isOnlineAsync.value ?? true;
    final pendingCount = pendingCountAsync.value ?? 0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        title: Row(
          children: [
            const KeraLogoWidget(size: 34, borderRadius: 6),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('የዳታ ማመሳከሪያ ማዕከል', 'Sync Center'),
                    style: KeraTypography.titleMedium(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    context.tr('ኬራ ስፔር • የዳታ ማስተላለፊያ እና ወረፋ', 'Kera Spare • Outbox Queue & Cloud Sync'),
                    style: KeraTypography.labelSmall(
                      color: Colors.white.withValues(alpha: 0.7),
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // One-tap Language Toggle Pill
          Consumer(
            builder: (context, ref, _) {
              return InkWell(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(
                        Locale(isAmharic ? 'en' : 'am'),
                      );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'English' : 'አማርኛ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Online / Offline Status Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  isOnline
                      ? context.tr('በመስመር ላይ', 'Online')
                      : context.tr('ከመስመር ውጭ', 'Offline'),
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
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
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
                                ? context.tr('የዳታ ማስተላለፊያ ዝግጁ ነው', 'Cloud Sync Ready')
                                : context.tr('ከመስመር ውጭ ይሰራል', 'Offline Mode Active'),
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
                          pendingCount > 0
                              ? context.tr('$pendingCount በመጠባበቅ ላይ', '$pendingCount Pending')
                              : context.tr('ተመሳስሏል', 'Synced'),
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
                        ? context.tr(
                            '$pendingCount የዳታ ለውጦች ወደ ሰርቨር አልተላኩም',
                            '$pendingCount changes waiting to sync',
                          )
                        : context.tr(
                            'ሁሉም የቅርብ ለውጦች ወደ ሰርቨር ተመሳክረዋል',
                            'All changes are fully synced to the server',
                          ),
                    style: KeraTypography.titleMedium(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'ሁሉም መረጃዎች በስልክዎ (SQLite) ውስጥ በሰላም ተቀምጠዋል። ኢንተርኔት ሲገኝ በራሱ ይላካል።',
                      'All local sales and parts are securely stored in SQLite and will push automatically when connected.',
                    ),
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
                                          context.tr('የዳታ ማመሳሰል በተሳካ ሁኔታ ተጠናቋል', 'Data sync completed successfully'),
                                        );
                                      } else {
                                        context.showSnackBar(
                                          pushState.lastError ??
                                              context.tr('ማመሳሰል አልተሳካም', 'Sync failed, will retry'),
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
                                  ? context.tr('በማመሳሰል ላይ...', 'Syncing...')
                                  : context.tr('አሁን አመሳስል', 'Sync Now'),
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
                        tooltip: context.tr('የሰርቨር ምርመራ', 'Diagnostics'),
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
                  color: context.isDark ? const Color(0xFF38290E) : KeraColors.warningAmberBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDark ? Colors.amber.shade700 : KeraColors.warningAmberBorder,
                  ),
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
                            context.tr(
                              '${conflicts.length} የዳታ ግጭት ተገኝቷል',
                              '${conflicts.length} Data Conflicts Detected',
                            ),
                            style: KeraTypography.labelMedium(
                              color: KeraColors.warningAmber,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr(
                              'በስልክዎ እና በሰርቨሩ መካከል ልዩነት ተፈጥሯል። እባክዎ ውሳኔ ይስጡ።',
                              'Discrepancies found between local and server data. Please review.',
                            ),
                            style: KeraTypography.bodySmall(
                              color: context.isDark ? Colors.amber.shade200 : Colors.brown.shade800,
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
                      child: Text(context.tr('ፍታ', 'Resolve')),
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
                  context.tr('ያልተላኩ መረጃዎች ዝርዝር', 'Outbox Categories'),
                  style: KeraTypography.titleSmall(
                    color: context.textPrimaryColor,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  context.tr('በወረፋ ላይ ያሉ', 'Pending Queue'),
                  style: KeraTypography.bodySmall(
                    color: context.textSecondaryColor,
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
                      title: context.tr('ያልተላኩ ሽያጮች', 'Offline Sales'),
                      subtitle: context.tr(
                        '${salesItems.length} ደረሰኞች በመጠባበቅ ላይ',
                        '${salesItems.length} receipts awaiting upload',
                      ),
                      countText: '${salesItems.length}',
                      onTap: () => context.push('/sync/offline'),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.new_label_rounded,
                      iconColor: Colors.teal.shade700,
                      title: context.tr('አዲስ የተመዘገቡ ዕቃዎች', 'New Parts'),
                      subtitle: context.tr(
                        '${partsItems.length} አዳዲስ መለዋወጫዎች በስልክ ተመዝግበዋል',
                        '${partsItems.length} parts created locally',
                      ),
                      countText: '${partsItems.length}',
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.warehouse_rounded,
                      iconColor: Colors.orange.shade800,
                      title: context.tr('የክምችት ማስተካከያዎች', 'Stock Movements'),
                      subtitle: context.tr(
                        '${stockItems.length} የክምችት ጭማሪ እና ቅነሳ እንቅስቃሴዎች',
                        '${stockItems.length} stock restocks & adjustments',
                      ),
                      countText: '${stockItems.length}',
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCard(
                      context,
                      icon: Icons.price_change_rounded,
                      iconColor: Colors.purple.shade700,
                      title: context.tr('የተሻሻሉ መረጃዎች', 'Price & Metadata Edits'),
                      subtitle: context.tr(
                        '${updateItems.length} የዋጋ እና ዝርዝር ማሻሻያዎች',
                        '${updateItems.length} catalog updates',
                      ),
                      countText: '${updateItems.length}',
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
                    context,
                    icon: Icons.offline_bolt_rounded,
                    label: context.tr('ከመስመር ውጭ\nዳሽቦርድ', 'Offline\nDashboard'),
                    onTap: () => context.push('/sync/offline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionPill(
                    context,
                    icon: Icons.compare_arrows_rounded,
                    label: context.tr('የዳታ ግጭት\nመፍቻ', 'Conflict\nResolver'),
                    onTap: () => context.push('/sync/conflicts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionPill(
                    context,
                    icon: Icons.dns_rounded,
                    label: context.tr('የሰርቨር\nምርመራ', 'Server\nDiagnostics'),
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
                color: context.cardCanvasColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
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
                            color: context.textPrimaryColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          context.tr(
                            'የአካባቢ ዳታቤዝ (Drift SQLite) ጤናማ እና የተጠበቀ ነው',
                            'Local database (Drift SQLite) is healthy and protected',
                          ),
                          style: KeraTypography.bodySmall(
                            color: context.textSecondaryColor,
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
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
                    style: KeraTypography.labelMedium(
                      color: context.textPrimaryColor,
                    ).copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: KeraTypography.bodySmall(
                      color: context.textSecondaryColor,
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
                color: context.isDark ? const Color(0xFF1E3A5F) : KeraColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                countText,
                style: KeraTypography.labelSmall(
                  color: context.isDark ? KeraColors.tealAccent : KeraColors.primaryNavy,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill(
    BuildContext context, {
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: KeraColors.actionBlue),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KeraTypography.labelSmall(
                color: context.textPrimaryColor,
              ).copyWith(
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
