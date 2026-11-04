import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../parts/presentation/providers/inventory_providers.dart';
import '../../../parts/presentation/widgets/sample_parts_dialog.dart';
import '../../../security/presentation/widgets/app_lock_settings_card.dart';
import '../../../sync/data/services/sync_push_service.dart';
import '../../data/services/export_backup_service.dart';
import '../providers/business_profile_provider.dart';
import '../widgets/profile_photo_avatar.dart';

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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KeraLogoWidget(size: 34, borderRadius: 6),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.tr('ቅንብሮች', 'Settings'),
                style: KeraTypography.titleMedium(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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

          // Network Sync Status Pill (tap to sync independently anytime)
          Tooltip(
            message: isSynced
                ? context.tr('ሁሉም መረጃዎች የተመሳሰሉ ናቸው', 'All data is synced')
                : context.tr('አሁን ለማመሳሰል ይጫኑ', 'Tap to sync now'),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  context.showSnackBar(
                    context.tr('ማመሳሰል ተጀምሯል...', 'Syncing with server...'),
                  );
                  final syncRes = await ref
                      .read(syncPushServiceProvider)
                      .pushPendingQueue();
                  if (!context.mounted) return;
                  if (syncRes.isSuccess) {
                    final count = syncRes.valueOrNull ?? 0;
                    context.showSnackBar(
                      count > 0
                          ? context.tr('$count መረጃዎች በተሳካ ሁኔታ ተመሳስለዋል', '$count items synced successfully')
                          : context.tr('ሁሉም መረጃዎች የተመሳሰሉ ናቸው', 'All data is fully synced'),
                    );
                  } else {
                    context.showSnackBar(
                      context.tr(
                        'ማመሳሰል አልተሳካም: ${syncRes.failureOrNull?.message ?? ""}',
                        'Sync failed: ${syncRes.failureOrNull?.message ?? ""}',
                      ),
                      isError: true,
                    );
                  }
                },
                child: Container(
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
              ),
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
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.badge_outlined,
                      titleAm: 'የንግድ መረጃ',
                      titleEn: '/ Business Profile',
                      subtitle: 'ስም፣ አድራሻ፣ ሎጎ እና ስልክ ቁጥር / Name, address, logo & phone',
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
                              context.tr('የተሟላ', 'Done'),
                              style: KeraTypography.labelSmall(
                                color: KeraColors.stockInText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => context.push('/settings/profile'),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.account_circle_outlined,
                      titleAm: 'የባለቤት መገለጫ',
                      titleEn: '/ Owner Profile',
                      subtitle: '$ownerName • $phone',
                      onTap: () => context.push('/settings/profile'),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.lock_reset_rounded,
                      titleAm: 'ደህንነት እና የይለፍ ቃል',
                      titleEn: '/ Security & Password',
                      subtitle: 'የይለፍ ቃል፣ ገቢር ስልኮች እና ፒን ቁጥር / Password, active devices & PIN',
                      onTap: () => context.push('/settings/security'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section 1b: App Lock & PIN
              _buildSectionHeader(
                icon: Icons.security_rounded,
                title: context.tr('የመተግበሪያ ቁልፍ / App Lock', 'App Lock & PIN Security'),
              ),
              const SizedBox(height: 6),
              const AppLockSettingsCard(),

              const SizedBox(height: KeraSpacing.lg),

              // Section 2: ምርጫዎች እና አጠቃቀም (Preferences)
              _buildSectionHeader(
                icon: Icons.tune_rounded,
                title: 'ምርጫዎች እና አጠቃቀም / Preferences',
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    // Language
                    _buildSettingsRow(
                      icon: Icons.translate_rounded,
                      titleAm: 'ቋንቋ',
                      titleEn: '/ Language',
                      subtitle: 'የአሰራር ቋንቋ ይምረጡ / Choose interface language',
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
                              ? 'አማርኛ'
                              : 'English',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.actionBlue,
                          ),
                        ),
                      ),
                      onTap: () => context.push('/settings/language'),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    // Theme
                    _buildSettingsRow(
                      icon: Icons.light_mode_outlined,
                      titleAm: 'ገጽታ',
                      titleEn: '/ Theme',
                      subtitle: 'የቀን እና የሌሊት ገጽታ / Day and night color theme',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardCanvasColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          switch (currentThemeMode) {
                            ThemeMode.light => context.tr('ፈካ ያለ', 'Light'),
                            ThemeMode.dark => context.tr('ጨለማ', 'Dark'),
                            ThemeMode.system => context.tr('ስርዓት', 'System'),
                          },
                          style: KeraTypography.labelSmall(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      onTap: () =>
                          _showThemeModeDialog(context, currentThemeMode),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    // Notifications
                    _buildSettingsRow(
                      icon: Icons.notifications_active_outlined,
                      titleAm: 'ማሳወቂያዎች',
                      titleEn: '/ Alerts',
                      subtitle: 'የክምችት እና የሽያጭ ማንቂያዎች / Stock and sales notifications',
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
                          context.tr('4 ነቅተዋል', '4 Active'),
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
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.warning_amber_rounded,
                      iconBg: KeraColors.warningBg,
                      iconColor: KeraColors.warning,
                      titleAm: 'አነስተኛ ክምችት ማስጠንቀቂያ',
                      titleEn: '/ Low Stock Threshold',
                      subtitle: 'ዕቃ ሊያልቅ ሲል የሚላክበት ገደብ / Alert threshold before running out',
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
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.straighten_rounded,
                      titleAm: 'ነባሪ መለኪያ',
                      titleEn: '/ Default Unit',
                      subtitle: 'ለተመዘገቡ አዳዲስ መለዋወጫዎች / Unit for newly registered items',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardCanvasColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('ቁራጭ', 'Pcs'),
                          style: KeraTypography.labelSmall(
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.showSnackBar(context.tr('ነባሪ መለኪያ: ቁራጭ', 'Default Unit: Pcs'));
                      },
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.sort_rounded,
                      titleAm: 'ነባሪ ቅደም ተከተል',
                      titleEn: '/ Sorting',
                      subtitle: 'የካታሎግ ቅደም ተከተል ማሳያ / Catalog display order',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardCanvasColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('ከፍተኛ ተፈላጊ', 'Popular'),
                          style: KeraTypography.labelSmall(
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.showSnackBar(context.tr('ነባሪ ቅደም ተከተል: ከፍተኛ ተፈላጊ', 'Default sorting: Most Popular'));
                      },
                    ),
                    Divider(height: 1, color: context.borderColor),
                    // Sub-routes for Brands, Categories, Locations
                    _buildSettingsRow(
                      icon: Icons.branding_watermark_outlined,
                      titleAm: 'የዕቃ ብራንዶች',
                      titleEn: '/ Brands Management',
                      subtitle: 'Toyota, Isuzu, Caterpillar, Nissan...',
                      onTap: () => context.push('/settings/brands'),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.category_outlined,
                      titleAm: 'ምድቦች',
                      titleEn: '/ Categories',
                      subtitle: 'ሞተር፣ ፍሬን፣ ኤሌክትሪክ፣ ሰስፔንሽን... / Engine, brakes, electrical...',
                      onTap: () => context.push('/settings/categories'),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.shelves,
                      titleAm: 'መጋዘን እና መደርደሪያዎች',
                      titleEn: '/ Shelves & Locations',
                      subtitle: 'የመደብር እና መጋዘን መደርደሪያ ኮዶች / Store & warehouse shelf codes',
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
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
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
                                        context.tr('የማመሳሰል ሁኔታ', 'Sync Status'),
                                        style: KeraTypography.titleSmall(color: context.textPrimaryColor),
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
                                              ? context.tr('የተመሳሰለ', 'Synced')
                                              : context.tr('$pendingCount ያልተላከ', '$pendingCount Queued'),
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
                                        ? context.tr('የመጨረሻ ማመሳሰል፡ አልተገናኘም', 'Last sync: Not connected')
                                        : context.tr('የመጨረሻ ማመሳሰል፡ ዛሬ 11:42 AM', 'Last sync: Today 11:42 AM'),
                                    style: KeraTypography.bodySmall(
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.textMutedColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: context.borderColor),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage_rounded,
                                size: 16,
                                color: context.textMutedColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.tr('ከመስመር ውጭ ዳታ (SQLite)', 'Offline Database (SQLite)'),
                                  style: KeraTypography.bodySmall(
                                    color: context.textSecondaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('1,482 ዕቃዎች • 4.2 MB', '1,482 items • 4.2 MB'),
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
                            context.tr('ማመሳሰል ተጀምሯል...', 'Syncing with server...'),
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
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.file_download_outlined,
                      titleAm: 'የዕቃዎች ዝርዝር ኤክስፖርት',
                      titleEn: '/ Export Inventory CSV',
                      subtitle: 'የመጋዘን ካታሎግ በExcel/CSV ፎርማት / Inventory catalog in CSV/Excel',
                      onTap: user == null
                          ? null
                          : () => _handleExportInventory(context, user.ownerId),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.receipt_long_outlined,
                      titleAm: 'የሽያጭ ሪፖርት ኤክስፖርት',
                      titleEn: '/ Export Sales CSV',
                      subtitle: 'የተጠናቀቁ ሽያጮች ዝርዝር በCSV / Completed sales records in CSV',
                      onTap: user == null
                          ? null
                          : () => _handleExportSales(context, user.ownerId),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.backup_rounded,
                      titleAm: 'የዳታቤዝ መጠባበቂያ',
                      titleEn: '/ Database Backup',
                      subtitle: 'ሙሉውን የአካባቢ ዳታ ወደ ፋይል ያስቀምጡ / Export full local DB to file',
                      onTap: () => _handleBackupDatabase(context),
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.settings_backup_restore_rounded,
                      titleAm: 'ዳታቤዝ መልስ',
                      titleEn: '/ Restore Database',
                      subtitle: 'የተቀመጠ የመጠባበቂያ ፋይል ይመልሱ / Restore database from saved file',
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
                  color: context.cardBg,
                  borderRadius: KeraRadii.borderCard,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.directions_car_rounded,
                      titleAm: 'ስለ ኬራ መከታተያ',
                      titleEn: '/ About Kera Tracker',
                      subtitle: 'v2.4.0 Build 142 • Addis Ababa',
                      onTap: () {
                        context.showSnackBar(
                          'Kera Spare Parts Tracker • v2.4.0 (Build 142)',
                        );
                      },
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.support_agent_rounded,
                      titleAm: 'የደንበኛ እገዛ እና ድጋፍ',
                      titleEn: '/ Customer Support',
                      subtitle: 'Telegram እና የስልክ ድጋፍ (8100) / Direct Phone & Telegram (8100)',
                      onTap: () {
                        context.showSnackBar(
                          context.tr('ድጋፍ: 8100 ወይም @KeraSupportBot', 'Support: 8100 or @KeraSupportBot'),
                        );
                      },
                    ),
                    Divider(height: 1, color: context.borderColor),
                    _buildSettingsRow(
                      icon: Icons.policy_rounded,
                      titleAm: 'የግላዊነት ፖሊሲ እና ውሎች',
                      titleEn: '/ Privacy Policy & Terms',
                      subtitle: 'የአጠቃቀም ደንቦች እና ፖሊሲ / Privacy Policy & Terms of Service',
                      onTap: () {
                        context.showSnackBar(
                          context.tr('የግላዊነት ፖሊሲ በቅርቡ ይዘመናል', 'Privacy policy updating soon'),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KeraSpacing.lg),

              // Section: የፈተና መሳሪያዎች (Sample Parts Generator)
              if (AppConstants.enableDemoGenerator)
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(Icons.speed_rounded, color: context.isDark ? KeraColors.tealAccent : KeraColors.primaryNavy),
                  title: Text(
                    context.tr('የሙከራ ዕቃዎች ማመንጫ', 'Generate Sample Parts'),
                    style: KeraTypography.titleSmall(color: context.textPrimaryColor),
                  ),
                  subtitle: Text(
                    context.tr('10, 25 ወይም 50 ናሙና ዕቃዎችን ይፍጠሩ', 'Generate 10, 25, or 50 demo parts'),
                    style: KeraTypography.labelSmall(color: context.textMutedColor),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_rounded, color: KeraColors.brandOrange),
                      title: Text(context.tr('የናሙና ዕቃዎች ማመንጫ ክፈት', 'Open Sample Parts Generator')),
                      subtitle: Text(context.tr('CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY', 'CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => SamplePartsDialog.show(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: KeraColors.error),
                      title: Text(
                        context.tr('የሙከራ ዕቃዎችን አፅዳ', 'Delete All Sample Data'),
                        style: const TextStyle(color: KeraColors.error),
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
                    context.tr('ከመለያ ውጣ', 'Sign Out'),
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
        color: context.cardBg,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black26 : Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Avatar with Photo Upload
          const ProfilePhotoAvatar(radius: 28),
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
            style: KeraTypography.labelSmall(color: context.textSecondaryColor),
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

    String displaySubtitle = subtitle;
    if (subtitle.contains(' / ')) {
      final parts = subtitle.split(' / ');
      displaySubtitle = context.isAmharic ? parts[0].trim() : parts[1].trim();
    }

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
                color: iconBg ?? (context.isDark ? const Color(0xFF1E3A5F) : KeraColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? (context.isDark ? KeraColors.tealAccent : KeraColors.primaryNavy),
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
                    style: KeraTypography.titleSmall(color: context.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    style: KeraTypography.labelSmall(
                      color: context.textMutedColor,
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
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMutedColor,
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
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.logoutPendingOnlineTitle),
          content: Text(l10n.logoutPendingOnlineMessage(precheck.pendingCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(l10n.cancel),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: KeraColors.error,
                side: const BorderSide(color: KeraColors.error),
              ),
              onPressed: () => Navigator.pop(ctx, 'direct_logout'),
              child: Text(context.tr('ቀጥታ ውጣ', 'Sign Out Directly')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded),
              label: Text(l10n.syncNowAndLogout),
              onPressed: () => Navigator.pop(ctx, 'sync_and_logout'),
            ),
          ],
        ),
      );

      if (choice == 'direct_logout' && context.mounted) {
        await ref.read(authControllerProvider.notifier).logout();
        return;
      }

      if (choice == 'sync_and_logout' && context.mounted) {
        context.showSnackBar(l10n.syncStatusSyncing);
        final result = await ref
            .read(authControllerProvider.notifier)
            .performSyncAndLogout();

        if (context.mounted && result.isFailure) {
          // If sync fails (e.g. token expired, server unreachable), offer direct sign out so user is never trapped!
          final proceedDirectly = await showDialog<bool>(
            context: context,
            builder: (failCtx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: KeraColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.tr('ማመሳሰል አልተሳካም', 'Sync Failed'))),
                ],
              ),
              content: Text(
                context.tr(
                  'ማመሳሰል አልተሳካም: ${result.failureOrNull?.message ?? ""}\n\nአሁን ቀጥታ ከአካውንት መውጣት ይፈልጋሉ?',
                  'Sync failed: ${result.failureOrNull?.message ?? ""}\n\nDo you want to sign out directly anyway?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(failCtx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(failCtx, true),
                  child: Text(context.tr('ቀጥታ ውጣ', 'Sign Out Directly')),
                ),
              ],
            ),
          );

          if (proceedDirectly == true && context.mounted) {
            await ref.read(authControllerProvider.notifier).logout();
          } else if (context.mounted) {
            context.showSnackBar(
              l10n.syncFailedLogoutCancelled(
                result.failureOrNull?.message ?? 'Sync failed',
              ),
              isError: true,
            );
          }
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
