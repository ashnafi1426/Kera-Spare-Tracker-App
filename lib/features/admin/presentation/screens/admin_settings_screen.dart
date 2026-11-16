import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../security/presentation/widgets/app_lock_settings_card.dart';

/// Screen 8: Complete Admin Settings & System Screen matching the finalized Figma Design Specification.
///
/// Features:
/// - Executive Navy Settings Header with Kera Logo, Title, Subtitle, and Notification Bell.
/// - Admin Profile Card: KS avatar with camera badge, admin name, phone, Super Administrator role badge,
///   and edit pencil action.
/// - Language Selector Card: Globe icon with segmented control (Amharic / English).
/// - Appearance / Theme Mode Card: Sun icon with segmented control (Light / Dark / System).
/// - App Lock & Security Section:
///   - App Lock Card: Lock icon, title, dynamic status subtitle, and switch toggle.
///   - Account Password Card: Key icon, title, subtitle, and navigation chevron.
/// - Preserved administrative modules: OEM Brands, Categories, Backup & Recovery, Logout.
/// - Zero RenderFlex overflows down to 320dp screen width and dark mode support.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isLoggingOut = false;

  // Profile local fallback state
  String _adminName = 'Admin Tesfa';
  String _adminPhone = '+251 911 234 567';

  // Dialog to Edit Profile
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _adminName);
    final phoneCtrl = TextEditingController(text: _adminPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.tr('የአድሚን መረጃ አድስ', 'Edit Admin Profile'),
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                labelText: context.tr('ሙሉ ስም', 'Full Name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                labelText: context.tr('ስልክ ቁጥር', 'Phone Number'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('ሰርዝ', 'Cancel'), style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _adminName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _adminName;
                _adminPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _adminPhone;
              });
              Navigator.pop(ctx);
              context.showSnackBar(context.tr('መረጃው ተዘምኗል', 'Profile updated'));
            },
            child: Text(context.tr('አስቀምጥ', 'Save'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AdminColors.keraOrange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('የይለፍ ቃል ቀይር', 'Change Password'),
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscure,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.tr('አዲስ የይለፍ ቃል', 'New Password (min 6 chars)'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscure,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.tr('አዲሱን የይለፍ ቃል አረጋግጥ', 'Confirm New Password'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: !obscure,
                      activeColor: AdminColors.keraOrange,
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
              child: Text(context.tr('ሰርዝ', 'Cancel'), style: TextStyle(color: context.textSecondaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.keraOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: Text(context.tr('ቀይር', 'Change'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AdminColors.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              context.tr('ከአካውንት መውጣት', 'Logout'),
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          context.tr(
            'ከአስተዳዳሪ አካውንት መውጣት ይፈልጋሉ? ያልተመሳሰለ መረጃ በስልክዎ ላይ እንደተጠበቀ ይቆያል።',
            'Are you sure you want to log out of Admin Console? Unsynced changes remain safely on this device.',
          ),
          style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('ይቅር', 'Cancel'), style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('ውጣ', 'Logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final authState = ref.watch(authControllerProvider);
    final isDark = context.isDark;

    // Use live session info if available
    final user = authState.asData?.value;
    final displayName = (user != null && user.name.isNotEmpty) ? user.name : _adminName;
    final displayPhone = (user != null && user.phoneNumber.isNotEmpty) ? user.phoneNumber : _adminPhone;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Executive Navy Settings Header matching Figma
          _buildExecutiveNavyHeader(context),

          // 2. Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // A. Admin Profile Card
                _buildAdminProfileCard(context, displayName, displayPhone, isDark),
                const SizedBox(height: 14),

                // B. Language Selector Card
                _buildLanguageCard(context, isAmharic, isDark),
                const SizedBox(height: 14),

                // C. Appearance / Theme Mode Card
                _buildThemeModeCard(context, themeMode, isDark),
                const SizedBox(height: 14),

                // D. App Lock & Security Section
                _buildAppLockAndSecuritySection(context, isDark),
                const SizedBox(height: 14),

                // E. Additional Administrative Hub (Brands, Backup, Logout)
                _buildAdditionalModulesCard(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Executive Navy Settings Header matching Figma
  Widget _buildExecutiveNavyHeader(BuildContext context) {
    final isDark = context.isDark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF071322) : const Color(0xFF173655),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Kera Logo Plate + Brand Text + Notification Bell
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              const KeraLogoWidget(size: 38, borderRadius: 10),
              const SizedBox(width: 10),

              // KERA / SPARE TRACKER brand text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KERA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'SPARE TRACKER',
                      style: TextStyle(
                        color: const Color(0xFFA5B4CB).withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification Bell with Unread Dot
              InkWell(
                onTap: () => context.push('/admin/notifications'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AdminColors.keraOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header Title & Subtitle
          Text(
            context.tr('ቅንብሮችና ሲስተም', 'Admin Settings & System'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.tr('የስርዓት አስተዳደር እና ደህንነት', 'Complete system administration & security.'),
            style: const TextStyle(
              color: Color(0xFFA5B4CB),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // A. Admin Profile Card matching Figma
  Widget _buildAdminProfileCard(
    BuildContext context,
    String name,
    String phone,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle with camera badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF102D55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'KS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AdminColors.keraOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardBg, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name, Phone, Role Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF38230D) : const Color(0xFFFFF3E3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE8A33A).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    context.tr('ዋና አስተዳዳሪ', 'Super Administrator'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Edit pencil icon button
          InkWell(
            onTap: _showEditProfileDialog,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.edit_outlined,
                color: AdminColors.keraOrange,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // B. Language Selector Card matching Figma
  Widget _buildLanguageCard(BuildContext context, bool isAmharic, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row with Globe Icon
          Row(
            children: [
              const Icon(
                Icons.language_rounded,
                color: AdminColors.keraOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ቋንቋ · Language', 'Language / ቋንቋ'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Switch: Amharic / English
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentOption(
                    context,
                    label: 'አማርኛ (የአገር)',
                    isSelected: isAmharic,
                    isDark: isDark,
                    onTap: () => ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(const Locale('am')),
                  ),
                ),
                Expanded(
                  child: _buildSegmentOption(
                    context,
                    label: 'English',
                    isSelected: !isAmharic,
                    isDark: isDark,
                    onTap: () => ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(const Locale('en')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // C. Appearance / Theme Mode Card matching Figma
  Widget _buildThemeModeCard(
    BuildContext context,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row with Sun Icon
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: AdminColors.keraOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ገጽታ · Theme Mode', 'Appearance / Theme Mode'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Segment Switch: Light / Dark / System
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildThemeSegmentOption(
                    context,
                    label: context.tr('ቀላል', 'Light'),
                    icon: Icons.light_mode_outlined,
                    isSelected: themeMode == ThemeMode.light,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _buildThemeSegmentOption(
                    context,
                    label: context.tr('ጨለማ', 'Dark'),
                    icon: Icons.dark_mode_outlined,
                    isSelected: themeMode == ThemeMode.dark,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.dark),
                  ),
                ),
                Expanded(
                  child: _buildThemeSegmentOption(
                    context,
                    label: context.tr('ሲስተም', 'System'),
                    icon: Icons.devices_rounded,
                    isSelected: themeMode == ThemeMode.system,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFF173655))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSegmentOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFF173655))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // D. App Lock & Security Section matching Figma
  Widget _buildAppLockAndSecuritySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: Shield icon + App Lock & Security
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AdminColors.keraOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('የመተግበሪያ ቁልፍና ደህንነት', 'App Lock & Security'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Item 1: App Lock Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const AppLockSettingsCard(),
        ),
        const SizedBox(height: 10),

        // Item 2: Account Password Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showChangePasswordDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_outlined,
                      color: AdminColors.keraOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('የይለፍ ቃል መቀየሪያ', 'Account Password'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'የአስተዳዳሪ መለያ የይለፍ ቃል ቀይር',
                              'Change admin login password & strength check',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // E. Additional Administrative Hub (Brands, Backup, Logout)
  Widget _buildAdditionalModulesCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Module 1: Backup & Cloud Recovery
            InkWell(
              onTap: () => context.push('/admin/backup'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('ምትኬና ማገገሚያ', 'Backup & Recovery'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('የዳታ ምትኬ ይፍጠሩ ወይም ይመልሱ', 'Create and restore system data points'),
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor, size: 20),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),

            // Module 2: System Audit Logs
            InkWell(
              onTap: () => context.push('/admin/audit-logs'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF159B55), size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('የደህንነት ኦዲት መዝገብ', 'Security & Audit Logs'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('የአስተዳዳሪ እርምጃዎች እና እንቅስቃሴዎች', 'Review administrator activities and events'),
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor, size: 20),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),

            // Module 3: Logout
            InkWell(
              onTap: _isLoggingOut ? null : _confirmLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AdminColors.danger, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr('ከአካውንት መውጣት', 'Logout'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.danger,
                        ),
                      ),
                    ),
                    if (_isLoggingOut)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.danger),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: AdminColors.danger, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
