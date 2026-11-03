import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../parts/presentation/providers/inventory_providers.dart';
import '../../../sync/data/services/sync_push_service.dart';
import '../../data/services/export_backup_service.dart';
import '../providers/business_profile_provider.dart';

/// Comprehensive Settings and Administration screen adhering to Google Stitch Screen 1.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  int _lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final currentThemeMode = ref.watch(themeModeControllerProvider);
    final currentLocale = ref.watch(localeControllerProvider);
    final profileAsync = ref.watch(businessProfileProvider);
    final profile = profileAsync.value;
    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final lastOnlineAsync = ref.watch(lastOnlineTimestampProvider);
    final lastOnline = lastOnlineAsync.value;

    final isSynced = pendingCount == 0;
    final businessName = profile?.businessName ??
        (user?.businessName.isNotEmpty == true
            ? user!.businessName
            : 'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ');
    final ownerName = profile?.ownerFullName ??
        (user != null ? 'አቶ ተስፋዬ ገብረመስቀል' : 'የመደብር ባለቤት');
    final phone = profile?.primaryPhone ??
        (user?.phoneNumber.isNotEmpty == true
            ? user!.phoneNumber
            : '+251 911 458 920');

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          context.tr('ቅንብሮች', 'Settings'),
          style: KeraTypography.titleMedium(color: Colors.white),
        ),
        actions: [
          // Language toggle pill
          Consumer(
            builder: (context, ref, _) {
              final isAmharic = context.isAmharic;
              return InkWell(
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(
                        Locale(isAmharic ? 'en' : 'am'),
                      );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
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

          // Network Sync Status Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSynced ? KeraColors.stockInText : KeraColors.warning,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isSynced
                      ? context.tr('የተገናኘ', 'Synced')
                      : '$pendingCount ${context.tr("በመጠባበቅ ላይ", "pending")}',
                  style: KeraTypography.labelSmall(color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: KeraSpacing.screenPadding,
            children: [
              // 0. Session Banners
              const NeedsLoginBanner(),
              const OfflineMaxDaysBanner(),
              const AccountSuspendedBanner(),
              const PasswordChangedBanner(),
              const SizedBox(height: 8),

              // Hero Merchant Profile Card
              _buildMerchantHeroCard(
                businessName: businessName,
                ownerName: ownerName,
                phone: phone,
                role: user?.role ?? 'Owner',
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 1: መለያ እና ንግድ (Account & Business)
              _buildSectionHeader(
                icon: Icons.store_rounded,
                title: 'መለያ እና ንግድ / Account & Business',
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
                    _buildSettingsRow(
                      icon: Icons.badge_outlined,
                      titleAm: 'የንግድ መረጃ',
                      titleEn: '/ Business Profile',
                      subtitle: 'ስም፣ አድራሻ፣ ሎጎ እና ስልክ ቁጥር',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.stockInBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: KeraColors.stockInText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'የተሟላ / Done',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.stockInText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => context.push('/settings/profile'),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.account_circle_outlined,
                      titleAm: 'የባለቤት መገለጫ',
                      titleEn: '/ Owner Profile',
                      subtitle: '$ownerName • $phone',
                      onTap: () => context.push('/settings/profile'),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.lock_reset_rounded,
                      titleAm: 'ደህንነት እና የይለፍ ቃል',
                      titleEn: '/ Security',
                      subtitle: 'የይለፍ ቃል፣ ገቢር ስልኮች እና ፒን ቁጥር',
                      onTap: () => context.push('/settings/security'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 2: ምርጫዎች እና አጠቃቀም (Preferences)
              _buildSectionHeader(
                icon: Icons.tune_rounded,
                title: 'ምርጫዎች እና አጠቃቀም / Preferences',
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
                    // Language
                    _buildSettingsRow(
                      icon: Icons.translate_rounded,
                      titleAm: 'ቋንቋ',
                      titleEn: '/ Language',
                      subtitle: 'የአሰራር ቋንቋ ይምረጡ',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.actionBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentLocale.languageCode == 'am'
                              ? 'አማርኛ (Amharic)'
                              : 'English (US)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.actionBlue,
                          ),
                        ),
                      ),
                      onTap: () => context.push('/settings/language'),
                    ),
                    const Divider(height: 1),
                    // Theme
                    _buildSettingsRow(
                      icon: Icons.light_mode_outlined,
                      titleAm: 'ገጽታ',
                      titleEn: '/ Theme',
                      subtitle: 'የቀን እና የሌሊት ገጽታ',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          switch (currentThemeMode) {
                            ThemeMode.light => 'ፈካ ያለ (Light)',
                            ThemeMode.dark => 'ጨለማ (Dark)',
                            ThemeMode.system => 'ስርዓት (System)',
                          },
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                      ),
                      onTap: () =>
                          _showThemeModeDialog(context, currentThemeMode),
                    ),
                    const Divider(height: 1),
                    // Notifications
                    _buildSettingsRow(
                      icon: Icons.notifications_active_outlined,
                      titleAm: 'ማሳወቂያዎች',
                      titleEn: '/ Alerts',
                      subtitle: 'የክምችት እና የሽያጭ ማንቂያዎች',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '4 ነቅተዋል (Active)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.warning,
                          ),
                        ),
                      ),
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 3: የመጋዘን እና ዕቃዎች ቅንብር (Inventory Defaults)
              _buildSectionHeader(
                icon: Icons.inventory_2_outlined,
                title: 'የመጋዘን እና ዕቃዎች ቅንብር / Inventory Defaults',
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
                    _buildSettingsRow(
                      icon: Icons.warning_amber_rounded,
                      iconBg: KeraColors.warningBg,
                      iconColor: KeraColors.warning,
                      titleAm: 'አነስተኛ ክምችት ማስጠንቀቂያ',
                      titleEn: '/ Low Stock Threshold',
                      subtitle: 'ዕቃ ሊያልቅ ሲል የሚላክበት ገደብ',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.warningBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_lowStockThreshold pcs',
                          style: KeraTypography.labelMedium(
                            color: KeraColors.warning,
                          ),
                        ),
                      ),
                      onTap: () => _showThresholdDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.straighten_rounded,
                      titleAm: 'ነባሪ መለኪያ',
                      titleEn: '/ Default Unit',
                      subtitle: 'ለተመዘገቡ አዳዲስ መለዋወጫዎች',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ቁራጭ (Pcs)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textPrimary,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.showSnackBar('ነባሪ መለኪያ: ቁራጭ (Pcs)');
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.sort_rounded,
                      titleAm: 'ነባሪ ቅደም ተከተል',
                      titleEn: '/ Sorting',
                      subtitle: 'የካታሎግ ቅደም ተከተል ማሳያ',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ከፍተኛ ተፈላጊ',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textPrimary,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.showSnackBar('ነባሪ ቅደም ተከተል: ከፍተኛ ተፈላጊ');
                      },
                    ),
                    const Divider(height: 1),
                    // Sub-routes for Brands, Categories, Locations
                    _buildSettingsRow(
                      icon: Icons.branding_watermark_outlined,
                      titleAm: 'የዕቃ ብራንዶች',
                      titleEn: '/ Brands Management',
                      subtitle: 'Toyota, Isuzu, Caterpillar, Nissan...',
                      onTap: () => context.push('/settings/brands'),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.category_outlined,
                      titleAm: 'ምድቦች',
                      titleEn: '/ Categories',
                      subtitle: 'ሞተር፣ ፍሬን፣ ኤሌክትሪክ፣ ሰስፔንሽን...',
                      onTap: () => context.push('/settings/categories'),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.shelves,
                      titleAm: 'መጋዘን እና መደርደሪያዎች',
                      titleEn: '/ Shelves & Locations',
                      subtitle: 'የመደብር እና መጋዘን መደርደሪያ ኮዶች',
                      onTap: () => context.push('/settings/locations'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 4: የዳታ ማመሳሰል (Data Synchronization & Offline)
              _buildSectionHeader(
                icon: Icons.cloud_sync_rounded,
                title: 'የዳታ ማመሳሰል / Cloud Sync & Storage',
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(KeraSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: KeraColors.borderVariant),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => context.push('/sync'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: KeraColors.stockInBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.cloud_done_rounded,
                                  color: KeraColors.stockInText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'የማመሳሰል ሁኔታ',
                                        style: KeraTypography.titleSmall(),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSynced
                                              ? KeraColors.stockInBg
                                              : KeraColors.warningBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isSynced
                                              ? '100% Synced'
                                              : '$pendingCount Queued',
                                          style: KeraTypography.labelSmall(
                                            color: isSynced
                                                ? KeraColors.stockInText
                                                : KeraColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    lastOnline == null
                                        ? 'የመጨረሻ ማመሳሰል፡ አልተገናኘም'
                                        : 'የመጨረሻ ማመሳሰል፡ ዛሬ 11:42 AM',
                                    style: KeraTypography.bodySmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: KeraColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storage_rounded,
                                size: 16,
                                color: KeraColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'ከመስመር ውጭ ዳታ (SQLite)',
                                  style: KeraTypography.bodySmall(
                                    color: KeraColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1,482 ዕቃዎች • 4.2 MB',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.actionBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KeraColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ref.read(syncPushServiceProvider).pushPendingQueue();
                          context.showSnackBar(
                            'ማመሳሰል ተጀምሯል... (Syncing with server)',
                          );
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          context.tr('አሁን አመሳስል', 'Sync Now'),
                          style: KeraTypography.titleSmall(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section: ዳታ ማውጣት እና መጠባበቂያ (Data Backup & Export)
              _buildSectionHeader(
                icon: Icons.backup_outlined,
                title: 'ዳታ መጠባበቂያ እና ኤክስፖርት / Backup & Export',
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
                    _buildSettingsRow(
                      icon: Icons.file_download_outlined,
                      titleAm: 'የዕቃዎች ዝርዝር ኤክስፖርት',
                      titleEn: '/ Export Inventory CSV',
                      subtitle: 'የመጋዘን ካታሎግ በExcel/CSV ፎርማት',
                      onTap: user == null
                          ? null
                          : () => _handleExportInventory(context, user.ownerId),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.receipt_long_outlined,
                      titleAm: 'የሽያጭ ሪፖርት ኤክስፖርት',
                      titleEn: '/ Export Sales CSV',
                      subtitle: 'የተጠናቀቁ ሽያጮች ዝርዝር በCSV',
                      onTap: user == null
                          ? null
                          : () => _handleExportSales(context, user.ownerId),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.backup_rounded,
                      titleAm: 'የዳታቤዝ መጠባበቂያ (Backup)',
                      titleEn: '/ Backup SQLite',
                      subtitle: 'ሙሉውን የአካባቢ ዳታ ወደ ፋይል ያስቀምጡ',
                      onTap: () => _handleBackupDatabase(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.settings_backup_restore_rounded,
                      titleAm: 'ዳታቤዝ መልስ (Restore)',
                      titleEn: '/ Restore SQLite',
                      subtitle: 'የተቀመጠ የመጠባበቂያ ፋይል ይመልሱ',
                      onTap: () => _confirmRestoreDatabase(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 5: ስለ መተግበሪያው (App & Legal)
              _buildSectionHeader(
                icon: Icons.info_outline_rounded,
                title: 'ስለ መተግበሪያው / App & Legal',
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
                    _buildSettingsRow(
                      icon: Icons.directions_car_rounded,
                      titleAm: 'ስለ ኬራ መከታተያ / About Kera',
                      titleEn: '',
                      subtitle: 'v2.4.0 Build 142 • Addis Ababa',
                      onTap: () {
                        context.showSnackBar(
                          'Kera Spare Parts Tracker • v2.4.0 (Build 142)',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.support_agent_rounded,
                      titleAm: 'የደንበኛ እገዛ እና ድጋፍ',
                      titleEn: '/ Support',
                      subtitle: 'Telegram & Phone direct support (8100)',
                      onTap: () {
                        context.showSnackBar(
                          'ድጋፍ: 8100 ወይም @KeraSupportBot',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsRow(
                      icon: Icons.policy_rounded,
                      titleAm: 'የግላዊነት ፖሊሲ እና ውሎች',
                      titleEn: '/ Privacy & Terms',
                      subtitle: 'Privacy Policy & Terms of Service',
                      onTap: () {
                        context.showSnackBar(
                          'የግላዊነት ፖሊሲ በቅርቡ ይዘመናል',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section: የፈተና መሳሪያዎች (Benchmark & Developer Tools)
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(Icons.speed_rounded, color: KeraColors.primaryNavy),
                title: Text(
                  'የሙከራ መሳሪያዎች (Benchmark Tools)',
                  style: KeraTypography.titleSmall(),
                ),
                subtitle: Text(
                  'ዕቃዎችን በብዛት ለመሙላት እና ለማፅዳት',
                  style: KeraTypography.labelSmall(color: KeraColors.textMuted),
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_chart_rounded, color: KeraColors.actionBlue),
                    title: const Text('2,000 የሙከራ ዕቃዎችን ሙላ (Seed Test Parts)'),
                    onTap: () async {
                      context.showSnackBar('ዕቃዎችን የመሙላት ሂደት ተጀምሯል...');
                      final success = await ref
                          .read(inventoryListProvider.notifier)
                          .seedTestParts(count: 2000);
                      if (context.mounted) {
                        if (success) {
                          context.showSnackBar('2,000 ዕቃዎች በተሳካ ሁኔታ ተሞልተዋል');
                        } else {
                          context.showSnackBar('ዕቃዎችን መሙላት አልተሳካም', isError: true);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: KeraColors.error),
                    title: const Text(
                      'የሙከራ ዕቃዎችን አፅዳ (Clear Test Parts)',
                      style: TextStyle(color: KeraColors.error),
                    ),
                    onTap: () => _confirmClearParts(context),
                  ),
                ],
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Logout Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.errorBg,
                    foregroundColor: KeraColors.error,
                    elevation: 0,
                    side: BorderSide(color: KeraColors.error.withAlpha(40)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: KeraRadii.borderButton,
                    ),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'ከመለያ ውጣ (Sign Out / Logout)',
                    style: KeraTypography.titleSmall(color: KeraColors.error),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Kera Auto Spare Parts POS • System ID: KR-992-ETH',
                  style: KeraTypography.labelSmall(
                    color: KeraColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),

          if (_isExporting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('ሂደቱ እየተከናወነ ነው...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Sub-Widgets ---

  Widget _buildMerchantHeroCard({
    required String businessName,
    required String ownerName,
    required String phone,
    required String role,
  }) {
    return Container(
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
          // Business Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: KeraColors.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.precision_manufacturing_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: KeraColors.actionBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: KeraSpacing.md),
          // Info Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kera Hub #14',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.actionBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KeraColors.stockInBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role.toUpperCase() == 'ADMIN'
                            ? 'Admin Merchant'
                            : 'Pro Merchant',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.stockInText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  businessName,
                  style: KeraTypography.titleMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tesfaye Auto Spares & Parts',
                  style: KeraTypography.labelSmall(
                    color: KeraColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: KeraColors.textMuted,
                    ),
                    Text(
                      ownerName,
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    Text(
                      '•',
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textMuted,
                      ),
                    ),
                    Text(
                      phone,
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: KeraColors.textMuted,
            ),
            onPressed: () => context.push('/settings/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    String displayTitle = title;
    if (title.contains(' / ')) {
      final parts = title.split(' / ');
      displayTitle = context.isAmharic ? parts[0].trim() : parts[1].trim();
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: KeraColors.actionBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            displayTitle,
            style: KeraTypography.labelSmall(color: KeraColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    Color? iconBg,
    Color? iconColor,
    required String titleAm,
    required String titleEn,
    required String subtitle,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    final cleanEn = titleEn.startsWith('/')
        ? titleEn.substring(1).trim()
        : titleEn.trim();
    final displayTitle = context.isAmharic
        ? titleAm
        : (cleanEn.isNotEmpty ? cleanEn : titleAm);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KeraSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg ?? KeraColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? KeraColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: KeraTypography.titleSmall(),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              trailingWidget,
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: KeraColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- Handlers & Dialogs ---

  void _showThresholdDialog(BuildContext context) {
    int tempVal = _lowStockThreshold;

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
                setState(() => _lowStockThreshold = tempVal);
                Navigator.pop(dialogCtx);
                context.showSnackBar(
                  'አነስተኛ ክምችት ገደብ ወደ $tempVal pcs ተቀይሯል',
                );
              },
              child: const Text('አረጋግጥ (Apply)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeMode currentMode) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.themeMode),
        children: [
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.system
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: currentMode == ThemeMode.system
                  ? KeraColors.actionBlue
                  : null,
            ),
            title: Text(l10n.themeSystem),
            onTap: () {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.light
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: currentMode == ThemeMode.light
                  ? KeraColors.actionBlue
                  : null,
            ),
            title: Text(l10n.themeLight),
            onTap: () {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: Icon(
              currentMode == ThemeMode.dark
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: currentMode == ThemeMode.dark
                  ? KeraColors.actionBlue
                  : null,
            ),
            title: Text(l10n.themeDark),
            onTap: () {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportInventory(
    BuildContext context,
    String ownerId,
  ) async {
    setState(() => _isExporting = true);
    try {
      final file = await ref
          .read(exportBackupServiceProvider)
          .exportInventoryCsv(ownerId: ownerId);
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportSales(
    BuildContext context,
    String ownerId,
  ) async {
    setState(() => _isExporting = true);
    try {
      final file = await ref
          .read(exportBackupServiceProvider)
          .exportSalesCsv(ownerId: ownerId);
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleBackupDatabase(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final file =
          await ref.read(exportBackupServiceProvider).backupDatabase();
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmRestoreDatabase(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restoreDatabase),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      setState(() => _isExporting = true);
      try {
        final restored =
            await ref.read(exportBackupServiceProvider).restoreDatabase();
        if (context.mounted) {
          if (restored) {
            context.showSnackBar(context.l10n.restoreSuccess);
          }
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar(context.l10n.restoreError, isError: true);
        }
      } finally {
        if (mounted) setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _confirmClearParts(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearTestParts),
        content: Text(l10n.clearTestPartsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(inventoryListProvider.notifier).clearTestParts();
      if (context.mounted) {
        if (success) {
          context.showSnackBar(l10n.clearTestPartsSuccess);
        } else {
          context.showSnackBar('Failed to clear test parts', isError: true);
        }
      }
    }
  }

  // Logout prechecks and safe flows
  Future<void> _handleLogout(BuildContext context) async {
    final l10n = context.l10n;
    final user = ref.read(authControllerProvider).value;

    final precheck =
        await ref.read(authControllerProvider.notifier).precheckLogout();

    if (!context.mounted) return;

    // CASE 1: No pending un-synced changes
    if (!precheck.hasPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.logoutConfirmTitle),
          content: Text(l10n.logoutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KeraColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.logout),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      return;
    }

    // CASE 2: Has pending changes and phone is ONLINE
    if (precheck.isOnline) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.logoutPendingOnlineTitle),
          content: Text(l10n.logoutPendingOnlineMessage(precheck.pendingCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded),
              label: Text(l10n.syncNowAndLogout),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        context.showSnackBar(l10n.syncStatusSyncing);
        final result = await ref
            .read(authControllerProvider.notifier)
            .performSyncAndLogout();

        if (context.mounted && result.isFailure) {
          context.showSnackBar(
            l10n.syncFailedLogoutCancelled(
              result.failureOrNull?.message ?? 'Sync failed',
            ),
            isError: true,
          );
        }
      }
      return;
    }

    // CASE 3: Has pending changes and phone is OFFLINE
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: KeraColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.logoutBlockedOfflineTitle)),
          ],
        ),
        content: Text(
          l10n.logoutBlockedOfflineMessage(precheck.pendingCount),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l10n.exportDataAction),
            onPressed: () {
              Navigator.pop(ctx);
              if (user != null) {
                _handleExportInventory(context, user.ownerId);
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDiscardDoubleConfirmationDialog(context);
            },
            child: Text(l10n.logoutDiscardButton),
          ),
        ],
      ),
    );
  }

  Future<void> _showDiscardDoubleConfirmationDialog(
      BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isValid = controller.text.trim() == 'DISCARD';
            return AlertDialog(
              title: Text(l10n.logoutDiscardButton),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.logoutDiscardPrompt),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'DISCARD',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isValid ? () => Navigator.pop(ctx, true) : null,
                  child: Text(l10n.logoutDiscardButton),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).forceDiscardAndLogout();
    }
  }
}
