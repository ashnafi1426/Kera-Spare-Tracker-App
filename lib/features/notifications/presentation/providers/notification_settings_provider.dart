import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database_provider.dart';

class NotificationSettings {
  final bool masterEnabled;
  final bool lowStockAlert;
  final bool outOfStockAlert;
  final bool deadStockWarning;
  final bool eachSaleAlert;
  final bool dailySummary;
  final bool highValueAlert;
  final bool syncErrorAlert;
  final bool conflictDetectionAlert;
  final bool syncCompletionSound;
  final bool channelPush;
  final bool channelTelegram;
  final bool channelSms;
  final int lowStockThreshold;

  const NotificationSettings({
    this.masterEnabled = true,
    this.lowStockAlert = true,
    this.outOfStockAlert = true,
    this.deadStockWarning = false,
    this.eachSaleAlert = true,
    this.dailySummary = true,
    this.highValueAlert = true,
    this.syncErrorAlert = true,
    this.conflictDetectionAlert = true,
    this.syncCompletionSound = false,
    this.channelPush = true,
    this.channelTelegram = true,
    this.channelSms = false,
    this.lowStockThreshold = 5,
  });

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? lowStockAlert,
    bool? outOfStockAlert,
    bool? deadStockWarning,
    bool? eachSaleAlert,
    bool? dailySummary,
    bool? highValueAlert,
    bool? syncErrorAlert,
    bool? conflictDetectionAlert,
    bool? syncCompletionSound,
    bool? channelPush,
    bool? channelTelegram,
    bool? channelSms,
    int? lowStockThreshold,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      outOfStockAlert: outOfStockAlert ?? this.outOfStockAlert,
      deadStockWarning: deadStockWarning ?? this.deadStockWarning,
      eachSaleAlert: eachSaleAlert ?? this.eachSaleAlert,
      dailySummary: dailySummary ?? this.dailySummary,
      highValueAlert: highValueAlert ?? this.highValueAlert,
      syncErrorAlert: syncErrorAlert ?? this.syncErrorAlert,
      conflictDetectionAlert: conflictDetectionAlert ?? this.conflictDetectionAlert,
      syncCompletionSound: syncCompletionSound ?? this.syncCompletionSound,
      channelPush: channelPush ?? this.channelPush,
      channelTelegram: channelTelegram ?? this.channelTelegram,
      channelSms: channelSms ?? this.channelSms,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final db = ref.watch(appDatabaseProvider);
    try {
      final master = await db.settingsDao.getSetting('notifications_master_enabled');
      final lowStock = await db.settingsDao.getSetting('notifications_low_stock');
      final outStock = await db.settingsDao.getSetting('notifications_out_of_stock');
      final deadStock = await db.settingsDao.getSetting('notifications_dead_stock');
      final sale = await db.settingsDao.getSetting('notifications_each_sale');
      final daily = await db.settingsDao.getSetting('notifications_daily_summary');
      final highVal = await db.settingsDao.getSetting('notifications_high_value');
      final syncErr = await db.settingsDao.getSetting('notifications_sync_error');
      final conflict = await db.settingsDao.getSetting('notifications_conflict_alert');
      final sound = await db.settingsDao.getSetting('notifications_sync_sound');
      final push = await db.settingsDao.getSetting('notifications_channel_push');
      final telegram = await db.settingsDao.getSetting('notifications_channel_telegram');
      final sms = await db.settingsDao.getSetting('notifications_channel_sms');
      final threshold = await db.settingsDao.getSetting('inventory_low_stock_threshold');

      return NotificationSettings(
        masterEnabled: master == null ? true : master == 'true',
        lowStockAlert: lowStock == null ? true : lowStock == 'true',
        outOfStockAlert: outStock == null ? true : outStock == 'true',
        deadStockWarning: deadStock == 'true',
        eachSaleAlert: sale == null ? true : sale == 'true',
        dailySummary: daily == null ? true : daily == 'true',
        highValueAlert: highVal == null ? true : highVal == 'true',
        syncErrorAlert: syncErr == null ? true : syncErr == 'true',
        conflictDetectionAlert: conflict == null ? true : conflict == 'true',
        syncCompletionSound: sound == 'true',
        channelPush: push == null ? true : push == 'true',
        channelTelegram: telegram == null ? true : telegram == 'true',
        channelSms: sms == 'true',
        lowStockThreshold: int.tryParse(threshold ?? '5') ?? 5,
      );
    } catch (_) {
      return const NotificationSettings();
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    final db = ref.read(appDatabaseProvider);
    state = AsyncValue.data(newSettings);

    final entries = {
      'notifications_master_enabled': newSettings.masterEnabled ? 'true' : 'false',
      'notifications_low_stock': newSettings.lowStockAlert ? 'true' : 'false',
      'notifications_out_of_stock': newSettings.outOfStockAlert ? 'true' : 'false',
      'notifications_dead_stock': newSettings.deadStockWarning ? 'true' : 'false',
      'notifications_each_sale': newSettings.eachSaleAlert ? 'true' : 'false',
      'notifications_daily_summary': newSettings.dailySummary ? 'true' : 'false',
      'notifications_high_value': newSettings.highValueAlert ? 'true' : 'false',
      'notifications_sync_error': newSettings.syncErrorAlert ? 'true' : 'false',
      'notifications_conflict_alert': newSettings.conflictDetectionAlert ? 'true' : 'false',
      'notifications_sync_sound': newSettings.syncCompletionSound ? 'true' : 'false',
      'notifications_channel_push': newSettings.channelPush ? 'true' : 'false',
      'notifications_channel_telegram': newSettings.channelTelegram ? 'true' : 'false',
      'notifications_channel_sms': newSettings.channelSms ? 'true' : 'false',
      'inventory_low_stock_threshold': newSettings.lowStockThreshold.toString(),
    };

    for (final e in entries.entries) {
      await db.settingsDao.setSetting(e.key, e.value);
    }
  }

  Future<void> resetDefaults() async {
    const defaults = NotificationSettings();
    await updateSettings(defaults);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

