import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_notification.dart';

enum NotificationFilter {
  all,
  unread,
  stock,
  salesSync,
}
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    return _buildInitialNotifications();
  }

  List<AppNotification> _buildInitialNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif-1',
        type: NotificationType.outOfStock,
        title: 'CTP D6R Track Roller',
        titleAm: 'CTP D6R Track Roller',
        description: 'Part #: 120-4389 • Shelf R-02 (ግቢ 3)',
        descriptionAm: 'ክፍል ቁጥር / Part #: 120-4389 • መደርደሪያ: Shelf R-02 (ግቢ 3)',
        timestamp: now.subtract(const Duration(minutes: 8)),
        isRead: false,
        partNumber: '120-4389',
        shelfLocation: 'Shelf R-02',
        remainingQuantity: 0,
      ),
      AppNotification(
        id: 'notif-2',
        type: NotificationType.lowStock,
        title: 'CAT 320D Oil Filter (ኦሪጅናል)',
        titleAm: 'CAT 320D Oil Filter (ኦሪጅናል)',
        description: 'Model code: 1R-0716 • Threshold: 10 pcs',
        descriptionAm: 'የሞዴል ኮድ: 1R-0716 • ዝቅተኛ ወለል: 10 pcs',
        timestamp: now.subtract(const Duration(minutes: 34)),
        isRead: false,
        partNumber: '1R-0716',
        remainingQuantity: 3,
        amount: 1450.0,
      ),
      AppNotification(
        id: 'notif-3',
        type: NotificationType.saleCompleted,
        title: 'Receipt #KS-POS-9844',
        titleAm: 'ደረሰኝ / Receipt #KS-POS-9844',
        description: 'Counter 01 • Telebirr • 2 items sold',
        descriptionAm: 'ተቀባይ ካውንተር: Kera Hub Counter 01 • በቴሌብር (Telebirr)',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 18)),
        isRead: false,
        receiptNumber: 'KS-POS-9844',
        amount: 4850.0,
      ),
      AppNotification(
        id: 'notif-4',
        type: NotificationType.syncFailed,
        title: 'Network Timeout',
        titleAm: 'የኔትወርክ መቋረጥ (Network Timeout)',
        description: '2 offline sales queued. Local data preserved safely.',
        descriptionAm: '2 ያልተላኩ የሽያጭ መረጃዎች በመጠባበቂያ ላይ ናቸው (2 offline sales queued). የአካባቢ ዳታ ተቀምጧል።',
        timestamp: now.subtract(const Duration(hours: 18)),
        isRead: false,
        pendingSyncCount: 2,
      ),
      AppNotification(
        id: 'notif-5',
        type: NotificationType.syncComplete,
        title: 'Sync Complete',
        titleAm: 'ማመሳሰል ተጠናቋል / Synced',
        description: '14 stock & sales records transferred to central server.',
        descriptionAm: '14 የክምችት እና የሽያጭ መረጃዎች ወደ ዋናው ሰርቨር ተላልፈዋል።',
        timestamp: now.subtract(const Duration(hours: 22)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-6',
        type: NotificationType.securityAlert,
        title: 'Security Review',
        titleAm: 'የይለፍ ቃል እና ቴሌብር ክፍያ ማረጋገጫ',
        description: 'Quarterly review: verify your Telebirr payout OTP and counter credentials.',
        descriptionAm: 'የሩብ ዓመት ደህንነት ክለሳ: እባክዎ የቴሌብር Payout OTP እንዲሁም የካውንተር መለያ የይለፍ ቃልዎን ያረጋግጡ።',
        timestamp: now.subtract(const Duration(days: 4)),
        isRead: true,
      ),
    ];
  }

  void markAllRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void dismissNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => NotificationFilter.all;

  void setFilter(NotificationFilter filter) {
    state = filter;
  }
}

final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
  NotificationFilterNotifier.new,
);

final filteredNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notifs = ref.watch(notificationsProvider);
  final filter = ref.watch(notificationFilterProvider);

  return switch (filter) {
    NotificationFilter.all => notifs,
    NotificationFilter.unread => notifs.where((n) => !n.isRead).toList(),
    NotificationFilter.stock => notifs
        .where((n) =>
            n.type == NotificationType.outOfStock ||
            n.type == NotificationType.lowStock)
        .toList(),
    NotificationFilter.salesSync => notifs
        .where((n) =>
            n.type == NotificationType.saleCompleted ||
            n.type == NotificationType.syncFailed ||
            n.type == NotificationType.syncComplete)
        .toList(),
  };
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});
