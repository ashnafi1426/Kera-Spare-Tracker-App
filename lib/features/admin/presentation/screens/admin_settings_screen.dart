import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../security/presentation/widgets/app_lock_settings_card.dart';
import '../../../settings/presentation/widgets/profile_photo_avatar.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 8: Complete Admin Settings Screen with all 13 sections:
/// 1. Profile: admin name, phone, change profile photo
/// 2. Language: Amharic (default) / English
/// 3. Appearance: System / Light / Dark
/// 4. App Lock: PIN, biometrics, auto-lock timeouts, lockout, PBKDF2 hash, offline
/// 5. Password: Change account password with strength check & show/hide
/// 6. Brands: CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY with add/edit/toggle
/// 7. Categories & Units of measurement
/// 8. Subscription plans: Free trial, Standard, Pro (Coming soon)
/// 9. Notifications: new registrations, sync conflicts, backup results
/// 10. Sync rules: unique record IDs, conflict policy (newest edit wins)
/// 11. Backup and recovery: last backup time, back up now, restore points
/// 12. Security and activity log: session timeout, recent actions
/// 13. About: logo, version, support, Logout
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isLoggingOut = false;

  // 1. Profile state
  String _adminName = 'Admin Tesfaye';
  String _adminPhone = '+251 911 234 567';

  // 6. Brands list
  final Map<String, bool> _brandToggles = {
    'CAT': true,
    'Doosan': true,
    'Develon': true,
    'CTP': true,
    'IPD': true,
    'Hitachi': true,
    'SANY': true,
  };

  // 7. Categories & Units
  final List<String> _categories = [
    'Engine (ሞተር)',
    'Hydraulics (ሃይድሮሊክስ)',
    'Transmission (ማስተላለፊያ)',
    'Undercarriage (የስር ዕቃዎች)',
    'Electrical (ኤሌክትሪክ)',
    'Filters (ማጣሪያዎች)',
  ];

  final List<String> _units = [
    'Pcs (ቁራጭ)',
    'Sets (ስብስብ)',
    'Kg (ኪሎግራም)',
    'Liters (ሊትር)',
    'Meters (ሜትር)',
  ];

  // 9. Notifications toggles
  bool _notifyNewRegistrations = true;
  bool _notifySyncConflicts = true;
  bool _notifyBackupResult = true;

  // 10. Sync Rules state
  final String _conflictPolicy = 'newest_wins'; // 'newest_wins' or 'flag_for_review'

  // 12. Security state
  final String _sessionTimeout = '30m';

  // Dialog to Edit Profile
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _adminName);
    final phoneCtrl = TextEditingController(text: _adminPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('የአድሚን መረጃ አድስ', 'Edit Admin Profile'),
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                labelText: context.tr('ሙሉ ስም', 'Full Name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                labelText: context.tr('ስልክ ቁጥር', 'Phone Number'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ሰርዝ', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _adminName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _adminName;
                _adminPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _adminPhone;
              });
              Navigator.pop(ctx);
              context.showSnackBar(context.tr('መረጃው ተዘምኗል', 'Profile updated'));
            },
            child: Text(context.tr('አስቀምጥ', 'Save')),
          ),
        ],
      ),
    );
  }

  // Dialog to Change Password
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.password_rounded, color: AdminColors.keraOrange),
              const SizedBox(width: 8),
              Text(
                context.tr('የይለፍ ቃል ቀይር', 'Change Password'),
                style: TextStyle(color: context.textPrimaryColor),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMsg!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: currentPassCtrl,
                  obscureText: obscure,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.tr('የአሁኑ የይለፍ ቃል', 'Current Password'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscure,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.tr('አዲስ የይለፍ ቃል (ቢያንስ 6 ፊደላት)', 'New Password (min 6 chars)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscure,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.tr('አዲሱን የይለፍ ቃል አረጋግጥ', 'Confirm New Password'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: !obscure,
                      onChanged: (val) => setDlgState(() => obscure = !(val ?? false)),
                    ),
                    Text(
                      context.tr('የይለፍ ቃል አሳይ', 'Show Passwords'),
                      style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('ሰርዝ', 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.keraOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (newPassCtrl.text.length < 6) {
                  setDlgState(() => errorMsg = context.tr('የይለፍ ቃል ቢያንስ 6 ፊደላት መሆን አለበት', 'Password must be at least 6 characters'));
                  return;
                }
                if (newPassCtrl.text != confirmPassCtrl.text) {
                  setDlgState(() => errorMsg = context.tr('የይለፍ ቃሎች አይመሳሰሉም', 'Passwords do not match'));
                  return;
                }
                try {
                  final res = await ref.read(authControllerProvider.notifier).changePassword(
                    currentPassword: currentPassCtrl.text,
                    newPassword: newPassCtrl.text,
                  );
                  if (res.isSuccess) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      context.showSnackBar(context.tr('የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል', 'Password changed successfully'));
                    }
                  } else {
                    setDlgState(() => errorMsg = res.failureOrNull?.message ?? 'Failed to update');
                  }
                } catch (e) {
                  setDlgState(() => errorMsg = e.toString());
                }
              },
              child: Text(context.tr('ቀይር', 'Change')),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to Add / Edit Brand
  void _showAddBrandDialog([String? existingBrand]) {
    final controller = TextEditingController(text: existingBrand ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existingBrand == null
              ? context.tr('አዲስ ብራንድ ጨምር', 'Add OEM Brand')
              : context.tr('ብራንድ አድስ', 'Edit Brand'),
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: context.tr('የብራንድ ስም (ምሳሌ፦ Komatsu)', 'Brand name (e.g. Komatsu, Volvo)'),
            hintStyle: TextStyle(color: context.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ሰርዝ', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _brandToggles[name] = true);
                ref.read(adminRepositoryProvider).createBrand(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(existingBrand == null ? context.tr('ጨምር', 'Add') : context.tr('አስቀምጥ', 'Save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              context.tr('ከአካውንት መውጣት', 'Logout'),
              style: TextStyle(color: context.textPrimaryColor),
            ),
          ],
        ),
        content: Text(
          context.tr(
            'ከአስተዳዳሪ አካውንት መውጣት ይፈልጋሉ? ያልተመሳሰለ መረጃ በስልክዎ ላይ እንደተጠበቀ ይቆያል።',
            'Are you sure you want to log out of Admin Console? Unsynced changes remain safely on this device.',
          ),
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('ይቅር', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('ውጣ', 'Logout')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoggingOut = true);
      try {
        await ref.read(authControllerProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoggingOut = false);
          context.showSnackBar('Logout error: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeControllerProvider);
    final isAmharic = currentLocale.languageCode == 'am';
    final themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Fixed Navy Header
            _buildNavyHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                children: [
                  // 1. Profile Section
                  _buildProfileCard(),
                  const SizedBox(height: 16),

                  // 2. Language Section
                  _buildLanguageCard(isAmharic),
                  const SizedBox(height: 16),

                  // 3. Appearance Section
                  _buildThemeCard(themeMode),
                  const SizedBox(height: 16),

                  // 4. App Lock (New - PIN, Biometrics, Timeouts, Lockout)
                  _buildAppLockSection(),
                  const SizedBox(height: 16),

                  // 5. Password Section
                  _buildPasswordCard(),
                  const SizedBox(height: 16),

                  // 6. Brands Section (CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY)
                  _buildBrandsCard(),
                  const SizedBox(height: 16),

                  // 7. Categories & Units Section
                  _buildCategoriesAndUnitsCard(),
                  const SizedBox(height: 16),

                  // 8. Subscription Plans Section
                  _buildSubscriptionPlansCard(),
                  const SizedBox(height: 16),

                  // 9. Notifications Section
                  _buildNotificationsCard(),
                  const SizedBox(height: 16),

                  // 10. Sync Rules Section
                  _buildSyncRulesCard(),
                  const SizedBox(height: 16),

                  // 11. Backup & Recovery Section
                  _buildBackupRecoveryCard(),
                  const SizedBox(height: 16),

                  // 12. Security & Activity Log Section
                  _buildSecurityActivityLogCard(),
                  const SizedBox(height: 16),

                  // 13. About & Logout Section
                  _buildAboutAndLogoutCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071322) : AdminColors.headerNavy,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const KeraLogoWidget(size: 38, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ቅንብሮች · Settings', 'Admin Settings & System'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.tr('የስርዓት ቁጥጥር እና ማስተካከያዎች', 'Complete system administration & security'),
                      style: const TextStyle(
                        color: AdminColors.headerTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AdminHeaderIconButton(
                icon: Icons.notifications_outlined,
                hasBadge: true,
                onTap: () => context.push('/admin/notifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Profile Section Card
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const ProfilePhotoAvatar(radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adminName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _adminPhone,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminColors.keraOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.tr('ዋና አስተዳዳሪ', 'Super Administrator'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.keraOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AdminColors.keraOrange,
            tooltip: context.tr('አድስ', 'Edit'),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  // 2. Language Section Card
  Widget _buildLanguageCard(bool isAmharic) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, color: AdminColors.keraOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ቋንቋ · Language', 'Language / ቋንቋ'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('am')),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isAmharic
                            ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'አማርኛ (ነባሪ)',
                        style: TextStyle(
                          color: isAmharic ? Colors.white : context.textSecondaryColor,
                          fontWeight: isAmharic ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isAmharic
                            ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'English',
                        style: TextStyle(
                          color: !isAmharic ? Colors.white : context.textSecondaryColor,
                          fontWeight: !isAmharic ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
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

  // 3. Theme Mode Card
  Widget _buildThemeCard(ThemeMode themeMode) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: AdminColors.keraOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ገጽታ · Theme Mode', 'Appearance / Theme Mode'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  label: context.tr('ቀላል', 'Light'),
                  icon: Icons.light_mode_rounded,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                _buildThemeOption(
                  label: context.tr('ጨለማ', 'Dark'),
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
                _buildThemeOption(
                  label: context.tr('ሲስተም', 'System'),
                  icon: Icons.brightness_auto_rounded,
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeControllerProvider.notifier).setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : context.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. App Lock Section (PIN, Biometrics, Timeouts, Lockout)
  Widget _buildAppLockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: AdminColors.keraOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('የመተግበሪያ ቁልፍ · App Lock', 'App Lock & Security'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        const AppLockSettingsCard(),
      ],
    );
  }

  // 5. Password Section
  Widget _buildPasswordCard() {
    return Material(
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: const Icon(Icons.password_rounded, color: AdminColors.keraOrange),
        title: Text(
          context.tr('የይለፍ ቃል መቀየሪያ', 'Account Password'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          context.tr('የአስተዳዳሪ መለያ የይለፍ ቃል ቀይር', 'Change admin login password & strength check'),
          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  // 6. Brands Section (CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY)
  Widget _buildBrandsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: AdminColors.keraOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('ብራንዶች · Brands (OEM)', 'OEM Brands & Manufacturers'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.keraOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => _showAddBrandDialog(),
                child: Text(
                  context.tr('+ ጨምር', '+ Add'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in _brandToggles.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.key.substring(0, entry.key.length >= 2 ? 2 : 1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.isDark ? Colors.white : AdminColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: context.textSecondaryColor,
                        onPressed: () => _showAddBrandDialog(entry.key),
                      ),
                      Switch(
                        value: entry.value,
                        activeThumbColor: AdminColors.keraOrange,
                        activeTrackColor: const Color(0xFFFED7AA),
                        onChanged: (val) {
                          setState(() => _brandToggles[entry.key] = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (entry.key != _brandToggles.keys.last) Divider(height: 8, color: context.borderColor),
          ],
        ],
      ),
    );
  }

  // 7. Categories & Units of Measurement Section
  Widget _buildCategoriesAndUnitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, color: AdminColors.keraOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ምድቦች እና መለኪያ አሃዶች', 'Categories & Units of Measurement'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('የእቃ ምድቦች', 'Part Categories'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _categories.map((c) => Chip(
              label: Text(c, style: const TextStyle(fontSize: 11)),
              backgroundColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              side: BorderSide(color: context.borderColor),
            )).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('መለኪያ አሃዶች (Units)', 'Measurement Units'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _units.map((u) => Chip(
              label: Text(u, style: const TextStyle(fontSize: 11)),
              backgroundColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              side: BorderSide(color: context.borderColor),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // 8. Subscription Plans Section
  Widget _buildSubscriptionPlansCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.card_membership_rounded, color: AdminColors.keraOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('እቅዶች · Subscription Plans', 'Subscription Plans & Tiers'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/plans'),
                child: Text(context.tr('ዝርዝር እይ', 'View Details')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPlanBadge('Free Trial (ነጻ ሙከራ)', context.tr('ነጻ', 'Active Free')),
              const SizedBox(width: 8),
              _buildPlanBadge('Standard (መደበኛ)', context.tr('በቅርቡ', 'Coming soon')),
              const SizedBox(width: 8),
              _buildPlanBadge('Pro (ፕሪሚየም)', context.tr('በቅርቡ', 'Coming soon')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String title, String badge) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AdminColors.keraOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.keraOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 9. Notifications Section
  Widget _buildNotificationsCard() {
    return Material(
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AdminColors.keraOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('ማሳወቂያዎች · Notifications', 'Administrative Alerts & Notifications'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('አዲስ የባለቤት ምዝገባዎች', 'New owner registrations'), style: const TextStyle(fontSize: 13)),
              value: _notifyNewRegistrations,
              activeThumbColor: AdminColors.keraOrange,
              onChanged: (v) => setState(() => _notifyNewRegistrations = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('የማመሳሰል ግጭቶች (Sync conflicts)', 'Sync conflict alerts'), style: const TextStyle(fontSize: 13)),
              value: _notifySyncConflicts,
              activeThumbColor: AdminColors.keraOrange,
              onChanged: (v) => setState(() => _notifySyncConflicts = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('የምትኬ ውጤት (Backup results)', 'Backup completion result'), style: const TextStyle(fontSize: 13)),
              value: _notifyBackupResult,
              activeThumbColor: AdminColors.keraOrange,
              onChanged: (v) => setState(() => _notifyBackupResult = v),
            ),
          ],
        ),
      ),
    );
  }

  // 10. Sync Rules Section
  Widget _buildSyncRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded, color: AdminColors.keraOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('የማመሳሰል ደንቦች · Sync Rules', 'Sync Rules & Conflict Policy'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/sync'),
                child: Text(context.tr('ሞኒተር', 'Monitor')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('ልዩ የመዝገብ መለያ (UUIDv4) ድግግሞሽን ይከላከላል', 'Unique record IDs (UUIDv4) prevent duplicates'),
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.rule_rounded, size: 16, color: AdminColors.keraOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${context.tr("ግጭት ፖሊሲ", "Conflict policy")}: ${_conflictPolicy == "newest_wins" ? context.tr("የቅርብ ጊዜ ለውጥ ይቀድማል (Newest edit wins)", "Newest edit wins") : "Review"}',
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('የክምችት መጠን ልዩነት ለግምገማ ምልክት ይደረጋል', 'Quantity conflicts flagged for review'),
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 11. Backup and Recovery Section
  Widget _buildBackupRecoveryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('ምትኬ እና መልሶ ማግኛ', 'Backup & Recovery'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  foregroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => context.push('/admin/backup'),
                child: Text(context.tr('አሁን ምትኬ ውሰድ', 'Back up now'), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr("የመጨረሻ ምትኬ", "Last backup")}: ${context.tr("ዛሬ 14:30 (የተሳካ)", "Today 2:30 PM (Successful)")}',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('4 የመልሶ ማግኛ ነጥቦች (Restore points) ተዘጋጅተዋል', '4 restore points available on cloud & device'),
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // 12. Security and Activity Log Section
  Widget _buildSecurityActivityLogCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: AdminColors.keraOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('የደህንነት እና ክንውን መዝገብ', 'Security & Activity Log'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/audit'),
                child: Text(context.tr('ሁሉንም እይ', 'View all')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr("የክፍለ-ጊዜ ማብቂያ (Session timeout)", "Session timeout")}: $_sessionTimeout',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            '• ${context.tr("ባለቤት ጸደቀ: ተስፋዬ ስፔር", "Owner approved: Tesfaye Spare")} (10m ago)',
            style: TextStyle(fontSize: 11, color: context.textPrimaryColor),
          ),
          Text(
            '• ${context.tr("አዲስ ብራንድ ተጨምሯል: SANY", "New brand added: SANY")} (1h ago)',
            style: TextStyle(fontSize: 11, color: context.textPrimaryColor),
          ),
          Text(
            '• ${context.tr("የዳታቤዝ ምትኬ ተጠናቋል", "Database backup completed")} (2h ago)',
            style: TextStyle(fontSize: 11, color: context.textPrimaryColor),
          ),
        ],
      ),
    );
  }

  // 13. About & Logout Section
  Widget _buildAboutAndLogoutCard() {
    final isDark = context.isDark;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const KeraLogoWidget(size: 64, borderRadius: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Kera Admin Console · v1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'support@keraspares.com · +251 911 000 000',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Server Config Pill
        Material(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.borderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Icon(Icons.settings_ethernet_rounded, color: context.textPrimaryColor),
            title: Text(
              context.tr('ሰርቨር ማስተካከያ · Server Settings', 'Server Host & Network Config'),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textPrimaryColor),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
            onTap: () => showServerConfigDialog(context, ref),
          ),
        ),
        const SizedBox(height: 16),

        // Logout Card
        Material(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            title: Text(
              context.tr('ከአካውንት ውጣ · Logout', 'Logout / Exit Session'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFDC2626),
              ),
            ),
            subtitle: Text(
              context.tr('የአስተዳዳሪ ክፍለ-ጊዜን ዝጋ', 'Terminate current admin session'),
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
              ),
            ),
            trailing: _isLoggingOut
                ? const KeraLoadingIndicator.small(color: Color(0xFFDC2626))
                : const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626)),
            onTap: _isLoggingOut ? null : _confirmLogout,
          ),
        ),
      ],
    );
  }
}
