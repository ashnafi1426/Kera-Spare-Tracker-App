import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/notification_settings_provider.dart';

/// Screen 4: Notification Settings Screen adhering strictly to Stitch Screen 4.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late NotificationSettings _currentSettings;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (settings) {
        if (!_initialized) {
          _currentSettings = settings;
          _initialized = true;
        }

        return Scaffold(
          backgroundColor: KeraColors.surfaceCanvas,
          appBar: AppBar(
            backgroundColor: KeraColors.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 1,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'የማሳወቂያ ቅንብሮች',
                  style: KeraTypography.titleMedium(color: Colors.white),
                ),
                Text(
                  'Notifications',
                  style: KeraTypography.labelSmall(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ref
                      .read(notificationSettingsProvider.notifier)
                      .resetDefaults();
                  setState(() {
                    _currentSettings = const NotificationSettings();
                  });
                  if (context.mounted) {
                    context.showSnackBar('ቅንብሮች እንደገና ተጀምረዋል (Reset to default)');
                  }
                },
                child: Text(
                  'እንደገና አስጀምር',
                  style: KeraTypography.labelMedium(
                    color: KeraColors.utilityTeal,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: KeraSpacing.screenPadding,
                    children: [
                      const SizedBox(height: 8),

                      // Master Toggle Hero Banner
                      Container(
                        padding: const EdgeInsets.all(KeraSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KeraRadii.borderCard,
                          border: Border.all(color: KeraColors.borderVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: KeraColors.actionBlue.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: KeraColors.actionBlue,
                                size: 24,
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
                                        'የስራ ማንቂያዎች',
                                        style: KeraTypography.titleMedium(),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentSettings.masterEnabled
                                              ? KeraColors.actionBlue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _currentSettings.masterEnabled
                                        ? 'Push Notifications Active'
                                        : 'Push Notifications Paused',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.actionBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'በመጋዘን እና በሽያጭ ወቅት ፈጣን ማንቂያዎችን በስልክዎ ይቀበሉ',
                                    style: KeraTypography.bodySmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _currentSettings.masterEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    masterEnabled: val,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KeraSpacing.lg),

                      // 1. Stock Alerts
                      _buildSectionHeader(
                        icon: Icons.warning_rounded,
                        iconColor: KeraColors.warning,
                        titleAm: 'የክምችት እና ዕቃዎች ማንቂያ',
                        titleEn: '(Stock Alerts)',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KeraRadii.borderCard,
                          border: Border.all(color: KeraColors.borderVariant),
                        ),
                        child: Column(
                          children: [
                            // Low-Stock Threshold Alert
                            Padding(
                              padding: const EdgeInsets.all(KeraSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'አነስተኛ ክምችት ሲደርስ',
                                              style: KeraTypography.titleSmall(),
                                            ),
                                            Text(
                                              'Low-Stock Threshold Alert',
                                              style: KeraTypography.labelSmall(
                                                color: KeraColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ዕቃ ከተቀመጠው ገደብ (${_currentSettings.lowStockThreshold} pcs) በታች ሲወርድ ወዲያውኑ አሳውቀኝ',
                                              style: KeraTypography.bodySmall(
                                                color: KeraColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _currentSettings.lowStockAlert,
                                        onChanged: (val) {
                                          setState(() {
                                            _currentSettings =
                                                _currentSettings.copyWith(
                                              lowStockAlert: val,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _showThresholdDialog(context),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: KeraColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: KeraColors.borderVariant,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.tune_rounded,
                                            size: 16,
                                            color: KeraColors.actionBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ገደብ፡ ${_currentSettings.lowStockThreshold} pcs (ቀይር / Edit)',
                                            style: KeraTypography.labelSmall(
                                              color: KeraColors.actionBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Out-of-Stock Zero Alert
                            _buildToggleTile(
                              title: 'ዕቃ ሙሉ በሙሉ ሲያልቅ',
                              badge: '0 QTY',
                              badgeColor: KeraColors.errorBg,
                              badgeTextColor: KeraColors.error,
                              subTitle: 'Out-of-Stock Zero Alert',
                              description:
                                  'ሽያጭ እንዳያመልጥ ዕቃ 0 ሲሆን አስቸኳይ ማንቂያ ይላክ',
                              value: _currentSettings.outOfStockAlert,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    outOfStockAlert: val,
                                  );
                                });
                              },
                            ),
                            const Divider(height: 1),

                            // Dead Stock Warning
                            _buildToggleTile(
                              title: 'የደነደነ/የቆየ ክምችት',
                              subTitle: 'Dead Stock Warning - 90+ Days',
                              description:
                                  'ከ90 ቀናት በላይ ያልተሸጡ ዕቃዎች ሳምንታዊ ማጠቃለያ',
                              value: _currentSettings.deadStockWarning,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    deadStockWarning: val,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KeraSpacing.lg),

                      // 2. Sales Notifications
                      _buildSectionHeader(
                        icon: Icons.point_of_sale_rounded,
                        iconColor: KeraColors.actionBlue,
                        titleAm: 'የሽያጭ ማንቂያዎች',
                        titleEn: '(Sales & Revenue)',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KeraRadii.borderCard,
                          border: Border.all(color: KeraColors.borderVariant),
                        ),
                        child: Column(
                          children: [
                            _buildToggleTile(
                              title: 'እያንዳንዱ የተጠናቀቀ ሽያጭ',
                              subTitle: 'Each Completed Sale',
                              description: 'ካሳሪው ሽያጭ ሲመዘግብ ድምፅ እና መልዕክት አሳይ',
                              value: _currentSettings.eachSaleAlert,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    eachSaleAlert: val,
                                  );
                                });
                              },
                            ),
                            const Divider(height: 1),
                            _buildToggleTile(
                              title: 'የቀን ሽያጭ ማጠቃለያ',
                              subTitle: 'Daily Closing Summary',
                              description:
                                  'በየቀኑ 12:00 ሰዓት (6:00 PM) የዕለቱን ጠቅላላ ገቢ እና ትርፍ ላክ',
                              value: _currentSettings.dailySummary,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    dailySummary: val,
                                  );
                                });
                              },
                            ),
                            const Divider(height: 1),
                            _buildToggleTile(
                              title: 'ከፍተኛ ዋጋ ያላቸው ሽያጮች',
                              badge: 'ETB 50k+',
                              badgeColor: KeraColors.actionBlue.withAlpha(20),
                              badgeTextColor: KeraColors.actionBlue,
                              subTitle: 'High-Value Transaction Alert',
                              description: 'ከ 50,000 ETB በላይ የሆነ ሽያጭ ሲደረግ',
                              value: _currentSettings.highValueAlert,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    highValueAlert: val,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KeraSpacing.lg),

                      // 3. Sync & Offline Alerts
                      _buildSectionHeader(
                        icon: Icons.sync_rounded,
                        iconColor: KeraColors.primaryNavy,
                        titleAm: 'የዳታ ማመሳሰል እና መስመር ውጭ',
                        titleEn: '(Sync & Offline)',
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: KeraRadii.borderCard,
                          border: Border.all(color: KeraColors.borderVariant),
                        ),
                        child: Column(
                          children: [
                            _buildToggleTile(
                              title: 'የማመሳሰል ስህተት ሲያጋጥም',
                              badge: 'አስፈላጊ / Critical',
                              badgeColor: KeraColors.errorBg,
                              badgeTextColor: KeraColors.error,
                              subTitle: 'Sync Error Alert',
                              description:
                                  'ኔትወርክ ሲቋረጥ ወይም ዳታ ሳይመሳከር ሲቀር ወዲያውኑ አሳውቀኝ',
                              value: _currentSettings.syncErrorAlert,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    syncErrorAlert: val,
                                  );
                                });
                              },
                            ),
                            const Divider(height: 1),
                            _buildToggleTile(
                              title: 'የዳታ ግጭት ማንቂያ',
                              subTitle: 'Conflict Detection Alert',
                              description: 'በአንድ ዕቃ ላይ የተለያየ መረጃ ሲመዘገብ መፍቻ ይጠይቁ',
                              value: _currentSettings.conflictDetectionAlert,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    conflictDetectionAlert: val,
                                  );
                                });
                              },
                            ),
                            const Divider(height: 1),
                            _buildToggleTile(
                              title: 'የተሳካ ማመሳሰል ማረጋገጫ',
                              subTitle: 'Sync Completion Sound',
                              description:
                                  'ከመስመር ውጭ የነበሩ ሽያጮች ክላውድ ላይ ሲገቡ በድምፅ አረጋግጥ',
                              value: _currentSettings.syncCompletionSound,
                              onChanged: (val) {
                                setState(() {
                                  _currentSettings = _currentSettings.copyWith(
                                    syncCompletionSound: val,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: KeraSpacing.lg),

                      // 4. Notification Channels
                      _buildSectionHeader(
                        icon: Icons.hub_rounded,
                        iconColor: KeraColors.textSecondary,
                        titleAm: 'የማሳወቂያ ዘዴዎች',
                        titleEn: '(Notification Channels)',
                      ),
                      const SizedBox(height: 6),
                      _buildChannelCard(
                        icon: Icons.phone_android_rounded,
                        title: 'በስልኩ ላይ (Push Notification)',
                        subtitle: 'System Push Notifications',
                        statusTag: 'በርቷል / ON',
                        statusColor: KeraColors.stockInBg,
                        statusTextColor: KeraColors.stockInText,
                      ),
                      const SizedBox(height: 8),
                      _buildChannelCard(
                        icon: Icons.send_rounded,
                        title: 'በቴሌግራም ቦት (Telegram Bot)',
                        subtitle: 'የተገናኘ: @KeraSpareBot',
                        statusTag: 'ON',
                        statusColor: KeraColors.stockInBg,
                        statusTextColor: KeraColors.stockInText,
                      ),
                      const SizedBox(height: 8),
                      _buildChannelCard(
                        icon: Icons.sms_rounded,
                        title: 'በአስቸኳይ አጭር መልዕክት (SMS)',
                        subtitle: 'ለአስቸኳይ ማንቂያዎች ብቻ',
                        statusTag: 'Critical Only',
                        statusColor: KeraColors.surfaceContainerLow,
                        statusTextColor: KeraColors.textSecondary,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Sticky Bottom Confirmation Bar
                Container(
                  padding: const EdgeInsets.all(KeraSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: KeraColors.borderVariant),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeraColors.actionBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: KeraRadii.borderButton,
                        ),
                      ),
                      onPressed: () async {
                        await ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(_currentSettings);
                        if (context.mounted) {
                          context.showSnackBar(
                            'የማሳወቂያ ቅንብሮች ተቀምጠዋል! (Settings Saved)',
                          );
                          if (context.canPop()) {
                            context.pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        'ቅንብሮቹን አስቀምጥ (Save Notification Settings)',
                        style: KeraTypography.titleSmall(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String titleAm,
    required String titleEn,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          titleAm,
          style: KeraTypography.titleSmall(),
        ),
        const SizedBox(width: 6),
        Text(
          titleEn,
          style: KeraTypography.labelSmall(color: KeraColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    required String subTitle,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(KeraSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: KeraTypography.titleSmall(),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? KeraColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: KeraTypography.labelSmall(
                            color: badgeTextColor ?? KeraColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subTitle,
                  style: KeraTypography.labelSmall(color: KeraColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: KeraTypography.bodySmall(
                    color: KeraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusTag,
    required Color statusColor,
    required Color statusTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.borderVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KeraColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: KeraColors.primaryNavy, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KeraTypography.titleSmall()),
                  Text(
                    subtitle,
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusTag,
              style: KeraTypography.labelSmall(color: statusTextColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showThresholdDialog(BuildContext context) {
    int tempVal = _currentSettings.lowStockThreshold;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('አነስተኛ ክምችት ገደብ (Low Stock Threshold)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ዕቃ ከዚህ ቁጥር በታች ሲደርስ የማስጠንቀቂያ ማንቂያ ይላካል፡'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: tempVal > 1
                        ? () => setDialogState(() => tempVal--)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$tempVal pcs',
                    style: KeraTypography.headlineMedium(
                      color: KeraColors.actionBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: () => setDialogState(() => tempVal++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('ይቅር (Cancel)'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    lowStockThreshold: tempVal,
                  );
                });
                Navigator.pop(dialogCtx);
              },
              child: const Text('አረጋግጥ (Apply)'),
            ),
          ],
        ),
      ),
    );
  }
}

