import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../sync/data/services/sync_push_service.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notifications_provider.dart';

/// Screen 3: Notification Center adhering to Google Stitch Screen 3.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(filteredNotificationsProvider);
    final allNotifs = ref.watch(notificationsProvider);
    final currentFilter = ref.watch(notificationFilterProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final stockCount = allNotifs
        .where((n) =>
            n.type == NotificationType.outOfStock ||
            n.type == NotificationType.lowStock)
        .length;
    final salesSyncCount = allNotifs
        .where((n) =>
            n.type == NotificationType.saleCompleted ||
            n.type == NotificationType.syncFailed ||
            n.type == NotificationType.syncComplete)
        .length;

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ኬራ ስፔር / Kera Spare',
              style: KeraTypography.titleMedium(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: KeraColors.utilityTeal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'አዲስ አበባ',
                  style: KeraTypography.labelSmall(
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sync',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              ref.read(syncPushServiceProvider).pushAll();
              context.showSnackBar('ማመሳሰል ተጀምሯል (Syncing...)');
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-Header: Page Identity & Mark All Read Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: KeraColors.borderVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'የማሳወቂያ ማዕከል',
                            style: KeraTypography.headlineSmall(),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: KeraColors.errorBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount አዲስ',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: KeraColors.actionBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAllRead();
                          context.showSnackBar('ሁሉም እንደተነበቡ ተደርገዋል');
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(
                          'ሁሉንም አንብብ',
                          style: KeraTypography.labelMedium(
                            color: KeraColors.actionBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Notifications Center & System Dispatch Log',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Filter Chips Scroller
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: KeraColors.borderVariant),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'ሁሉም (All ${allNotifs.length})',
                    isSelected: currentFilter == NotificationFilter.all,
                    onTap: () => ref
                        .read(notificationFilterProvider.notifier)
                        .state = NotificationFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'ያልተነበቡ (Unread $unreadCount)',
                    hasDot: unreadCount > 0,
                    isSelected: currentFilter == NotificationFilter.unread,
                    onTap: () => ref
                        .read(notificationFilterProvider.notifier)
                        .state = NotificationFilter.unread,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'የክምችት (Stock $stockCount)',
                    isSelected: currentFilter == NotificationFilter.stock,
                    onTap: () => ref
                        .read(notificationFilterProvider.notifier)
                        .state = NotificationFilter.stock,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'ሽያጭና ሲንክ (Sales $salesSyncCount)',
                    isSelected: currentFilter == NotificationFilter.salesSync,
                    onTap: () => ref
                        .read(notificationFilterProvider.notifier)
                        .state = NotificationFilter.salesSync,
                  ),
                ],
              ),
            ),

            // Notification Cards Feed
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ምንም ማሳወቂያ የለም',
                            style: KeraTypography.titleMedium(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No notifications for the selected filter',
                            style: KeraTypography.bodySmall(
                              color: KeraColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: KeraSpacing.screenPadding,
                      children: [
                        const SizedBox(height: 8),
                        // Timestamp Group Header: Today
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ዛሬ / Today — 11 ሚያዝያ',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Kera Hub Main',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        for (final notif in notifications) ...[
                          _buildNotificationCard(context, ref, notif),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    bool hasDot = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? KeraColors.primaryNavy
              : KeraColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? KeraColors.primaryNavy
                : KeraColors.borderVariant,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: KeraColors.error,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: KeraTypography.labelMedium(
                color: isSelected ? Colors.white : KeraColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    switch (notif.type) {
      case NotificationType.outOfStock:
        return _buildOutOfStockCard(context, ref, notif);
      case NotificationType.lowStock:
        return _buildLowStockCard(context, ref, notif);
      case NotificationType.saleCompleted:
        return _buildSaleCompletedCard(context, ref, notif);
      case NotificationType.syncFailed:
        return _buildSyncFailedCard(context, ref, notif);
      case NotificationType.syncComplete:
        return _buildSyncCompleteCard(context, ref, notif);
      case NotificationType.securityAlert:
        return _buildSecurityAlertCard(context, ref, notif);
    }
  }

  // Card 1: Out of Stock Alert
  Widget _buildOutOfStockCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: KeraRadii.borderCard,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: KeraColors.error, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(KeraSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.errorBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: KeraColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: KeraColors.error,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ዕቃ አልቋል: Out of Stock',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ከ 8 ደቂቃ በፊት',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.titleAm,
                      style: KeraTypography.titleMedium(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.descriptionAm,
                      style: KeraTypography.bodySmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'የቀረው ክምችት: 0 pcs remaining',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.error,
                            ),
                          ),
                          Text(
                            'ደቂቅ ትዕዛዝ #441',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KeraColors.primaryNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                context.push('/stock/low-stock');
                              },
                              icon: const Icon(
                                Icons.shopping_cart_checkout_rounded,
                                size: 16,
                              ),
                              label: const Text('አሁን እዘዝ / Reorder Now'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            side: BorderSide(color: KeraColors.borderVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 18,
                          ),
                          onPressed: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(notif.id);
                            context.showSnackBar('ዕቃ ምልክት ተደርጎበታል (Bookmarked)');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 2: Low Stock Warning
  Widget _buildLowStockCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      child: ClipRRect(
        borderRadius: KeraRadii.borderCard,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: KeraColors.warning, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(KeraSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.warningBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: KeraColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.warningBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'አስቸኳይ: አነስተኛ ክምችት',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ከ 34 ደቂቃ በፊት',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.titleAm,
                      style: KeraTypography.titleMedium(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.descriptionAm,
                      style: KeraTypography.bodySmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'የቀረው: 3 pcs left (Critical)',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.warning,
                            ),
                          ),
                          Text(
                            'ዋጋ: 1,450 ETB',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KeraColors.actionBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                context.push('/stock/low-stock');
                              },
                              icon: const Icon(
                                Icons.add_box_rounded,
                                size: 16,
                              ),
                              label: const Text('ፈጣን ማሟያ / Quick Restock'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: KeraColors.borderVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .dismissNotification(notif.id);
                          },
                          child: const Text('አስወግድ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 3: Successful POS Sale
  Widget _buildSaleCompletedCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      child: ClipRRect(
        borderRadius: KeraRadii.borderCard,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: KeraColors.stockInText, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(KeraSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.stockInBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: KeraColors.stockInText,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.stockInBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'የተሳካ ሽያጭ: Sale Completed',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.stockInText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '10:42 ጠዋት',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif.titleAm,
                          style: KeraTypography.titleSmall(),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '4,850 ',
                                style: KeraTypography.headlineSmall(),
                              ),
                              TextSpan(
                                text: 'ETB',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.descriptionAm,
                      style: KeraTypography.bodySmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2 ዕቃዎች ተሽጠዋል',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textMuted,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            context.push('/home');
                          },
                          icon: const Icon(Icons.receipt_rounded, size: 16),
                          label: const Text('ደረሰኝ ይመልከቱ / View Receipt'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 4: Sync Failed Network Error
  Widget _buildSyncFailedCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      child: ClipRRect(
        borderRadius: KeraRadii.borderCard,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: KeraColors.error, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(KeraSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.errorBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.sync_problem_rounded,
                          color: KeraColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ማመሳሰል አልተሳካም: Sync Failed',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ትናንት 4:15 ከሰዓት',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.titleAm,
                      style: KeraTypography.titleSmall(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.descriptionAm,
                      style: KeraTypography.bodySmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KeraColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ref.read(syncPushServiceProvider).pushAll();
                          context.showSnackBar('ዳግም ማመሳሰል ተጀምሯል (Retrying sync...)');
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('እንደገና ሞክር (Retry Sync Now)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 5: Sync Complete
  Widget _buildSyncCompleteCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      padding: const EdgeInsets.all(KeraSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: KeraColors.utilityTeal.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: KeraColors.utilityTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: KeraColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ማመሳሰል ተጠናቋል / Synced',
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'ትናንት 2:00',
                style: KeraTypography.labelSmall(
                  color: KeraColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.descriptionAm,
                  style: KeraTypography.bodyMedium(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      size: 14,
                      color: KeraColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Addis Central Server • All records verified',
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 6: Account & Security Notice
  Widget _buildSecurityAlertCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      child: ClipRRect(
        borderRadius: KeraRadii.borderCard,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: KeraColors.actionBlue, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(KeraSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.actionBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: KeraColors.actionBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.actionBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'የመለያ ደህንነት ማሳሰቢያ',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.actionBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ሚያዝያ 08',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.titleAm,
                      style: KeraTypography.titleSmall(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.descriptionAm,
                      style: KeraTypography.bodySmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: KeraColors.borderVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.push('/settings/security');
                      },
                      icon: const Icon(Icons.verified_user_rounded, size: 16),
                      label: const Text('ደህንነት አረጋግጥ / Verify'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
