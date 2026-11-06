import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Screen 6: Security and Active Sessions Screen adhering strictly to Stitch Screen 6.
class SecuritySessionsScreen extends ConsumerStatefulWidget {
  const SecuritySessionsScreen({super.key});

  @override
  ConsumerState<SecuritySessionsScreen> createState() =>
      _SecuritySessionsScreenState();
}

class _SecuritySessionsScreenState
    extends ConsumerState<SecuritySessionsScreen> {
  final _currentPasswordController = TextEditingController(text: 'secret1234');
  final _newPasswordController = TextEditingController(text: 'KeraTrack@2025#');
  final _confirmPasswordController =
      TextEditingController(text: 'KeraTrack@2025#');

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _biometricEnabled = true;
  bool _isUpdatingPassword = false;

  bool _device2Terminated = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength evaluation
  int _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'\d').hasMatch(pass)) score++;
    if (RegExp(r'[@#$%^&*()_+\-=\[\]{};:,.<>?]').hasMatch(pass)) score++;
    return score;
  }

  Future<void> _updatePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      context.showSnackBar('የይለፍ ቃል ቢያንስ 6 ፊደላት መሆን አለበት', isError: true);
      return;
    }
    if (newPass != confirm) {
      context.showSnackBar('አዲሶቹ የይለፍ ቃሎች አይመሳሰሉም', isError: true);
      return;
    }

    setState(() => _isUpdatingPassword = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .changePassword(currentPassword: current, newPassword: newPass);
    setState(() => _isUpdatingPassword = false);

    if (mounted) {
      if (result.isSuccess) {
        context.showSnackBar('የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል! (Password updated)');
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'የአሁኑ የይለፍ ቃል ልክ አይደለም',
          isError: true,
        );
      }
    }
  }

  void _showSignOutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: KeraRadii.borderSheet),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KeraColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: KeraColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'መውጣት ይረጋገጥ?',
                    style: KeraTypography.headlineSmall(),
                  ),
                  Text(
                    'Confirm Session Sign Out',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'እርግጠኛ ነዎት ከመለያው መውጣት ይፈልጋሉ? ያልተላኩ የአካባቢ ሽያጮች ካሉ መመሳሰላቸውን ያረጋግጡ።',
          style: KeraTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'ይቅር (Cancel)',
              style: KeraTypography.titleSmall(color: KeraColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: KeraRadii.borderButton,
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'አዎ፣ ውጣ',
              style: KeraTypography.titleSmall(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(_newPasswordController.text);

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
              'ደህንነት እና የይለፍ ቃል',
              style: KeraTypography.titleMedium(color: Colors.white),
            ),
            Text(
              'Security & Active Sessions',
              style: KeraTypography.labelSmall(
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.verified_user_rounded, color: Colors.white),
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

                  // Security Health Banner
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
                            color: KeraColors.utilityTeal.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: KeraColors.utilityTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: KeraSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'የመለያዎ ደህንነት አስተማማኝ ነው',
                                style: KeraTypography.titleMedium(),
                              ),
                              Text(
                                'Account Security Healthy',
                                style: KeraTypography.labelSmall(
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
                                  border: Border.all(
                                    color: KeraColors.borderVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: KeraColors.utilityTeal,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'የይለፍ ቃል የተጠበቀ ነው • 2-ደረጃ ማረጋገጫ በስልክ ነቅቷል',
                                        style: KeraTypography.bodySmall(
                                          color: KeraColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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

                  const SizedBox(height: KeraSpacing.lg),

                  // Section 1: Change Password Form
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_reset_rounded,
                                  color: KeraColors.actionBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'የይለፍ ቃል ለውጥ',
                                      style: KeraTypography.titleMedium(),
                                    ),
                                    Text(
                                      'Change Password',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                'ደረጃ 1/2',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Current Password
                        Text(
                          'የአሁኑ የይለፍ ቃል (Current Password) *',
                          style: KeraTypography.labelMedium(),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius: KeraRadii.borderInput,
                            ),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // New Password
                        Text(
                          'አዲስ የይለፍ ቃል (New Password) *',
                          style: KeraTypography.labelMedium(),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius: KeraRadii.borderInput,
                            ),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Password Strength Bar
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'የይለፍ ቃል ጥንካሬ (Strength):',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textSecondary,
                              ),
                            ),
                            Text(
                              strength == 3
                                  ? 'በጣም ጠንካራ (Strong 3/3)'
                                  : strength == 2
                                      ? 'መካከለኛ (Medium 2/3)'
                                      : 'ደካማ (Weak 1/3)',
                              style: KeraTypography.labelSmall(
                                color: strength == 3
                                    ? KeraColors.stockInText
                                    : strength == 2
                                        ? KeraColors.warning
                                        : KeraColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: strength >= 1
                                      ? (strength == 3
                                          ? KeraColors.stockInText
                                          : KeraColors.warning)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: strength >= 2
                                      ? (strength == 3
                                          ? KeraColors.stockInText
                                          : KeraColors.warning)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: strength >= 3
                                      ? KeraColors.stockInText
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildCriteriaChip(
                              'ቢያንስ 8 ፊደላት',
                              _newPasswordController.text.length >= 8,
                            ),
                            _buildCriteriaChip(
                              'ቁጥሮች',
                              RegExp(r'\d')
                                  .hasMatch(_newPasswordController.text),
                            ),
                            _buildCriteriaChip(
                              'ልዩ ምልክት (@#)',
                              RegExp(r'[@#$%^&*()_+\-=\[\]{};:,.<>?]')
                                  .hasMatch(_newPasswordController.text),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Confirm Password
                        Text(
                          'አዲሱን የይለፍ ቃል አረጋግጥ (Confirm Password) *',
                          style: KeraTypography.labelMedium(),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius: KeraRadii.borderInput,
                            ),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KeraColors.actionBlue,
                              side: const BorderSide(
                                color: KeraColors.actionBlue,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: KeraRadii.borderButton,
                              ),
                            ),
                            onPressed:
                                _isUpdatingPassword ? null : _updatePassword,
                            icon: _isUpdatingPassword
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.key_rounded, size: 18),
                            label: Text(
                              'የይለፍ ቃል ቀይር (Update Password)',
                              style: KeraTypography.titleSmall(
                                color: KeraColors.actionBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KeraSpacing.lg),

                  // Section 2: Active Sessions & Logged-in Devices
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.devices_rounded,
                              color: KeraColors.actionBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ገቢር ክፍለ-ጊዜዎች',
                                  style: KeraTypography.titleMedium(),
                                ),
                                Text(
                                  'Active Logged-in Devices',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ይህ መለያ በአሁኑ ሰዓት በ${_device2Terminated ? '1' : '2'} መሳሪያዎች ላይ ክፍት ነው',
                          style: KeraTypography.bodySmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Device 1: Current Device
                        Container(
                          padding: const EdgeInsets.all(KeraSpacing.md),
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: KeraColors.actionBlue.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.smartphone_rounded,
                                  color: KeraColors.utilityTeal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Text(
                                          'Samsung Galaxy A54',
                                          style: KeraTypography.titleSmall(),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: KeraColors.actionBlue
                                                .withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ይህ ስልክ (This Device)',
                                            style: KeraTypography.labelSmall(
                                              color: KeraColors.actionBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Addis Ababa, ET • Active Now',
                                      style: KeraTypography.bodySmall(
                                        color: KeraColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kera Spare Android App v2.4 • IP: 197.156.104.22',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!_device2Terminated) ...[
                          const SizedBox(height: 8),

                          // Device 2: POS Tablet
                          Container(
                            padding: const EdgeInsets.all(KeraSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: KeraColors.borderVariant),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: KeraColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.tablet_mac_rounded,
                                    color: KeraColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Galaxy Tab A9',
                                            style: KeraTypography.titleSmall(),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() =>
                                                  _device2Terminated = true);
                                              context.showSnackBar(
                                                'Galaxy Tab A9 ክፍለ-ጊዜ ተቋርጧል (Session terminated)',
                                              );
                                            },
                                            child: Text(
                                              'አስወጣ',
                                              style: KeraTypography.labelSmall(
                                                color: KeraColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Shop POS Terminal • Kera Hub #14',
                                        style: KeraTypography.bodySmall(
                                          color: KeraColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'የመጨረሻ እንቅስቃሴ፡ ዛሬ 10:15 AM',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Terminate all action
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: KeraColors.errorBg,
                              foregroundColor: KeraColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _device2Terminated = true);
                              context.showSnackBar(
                                'ከሌሎች መሳሪያዎች በሙሉ ተወጥቷል (Terminated other sessions)',
                              );
                            },
                            icon: const Icon(
                              Icons.power_settings_new_rounded,
                              size: 18,
                            ),
                            label: Text(
                              'ከሌሎች መሳሪያዎች በሙሉ ውጣ (Log Out Others)',
                              style: KeraTypography.titleSmall(
                                color: KeraColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KeraSpacing.lg),

                  // Section 3: Additional Security Controls
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: KeraColors.actionBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ተጨማሪ የደህንነት አማራጮች',
                                  style: KeraTypography.titleMedium(),
                                ),
                                Text(
                                  'Additional Security Controls',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Biometrics
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: KeraColors.primaryNavy,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'የጣት አሻራ / ባዮሜትሪክ መግቢያ',
                                    style: KeraTypography.titleSmall(),
                                  ),
                                  Text(
                                    'Biometric Fingerprint Unlock',
                                    style: KeraTypography.bodySmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _biometricEnabled,
                              onChanged: (val) =>
                                  setState(() => _biometricEnabled = val),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // POS PIN
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.pin_rounded,
                                color: KeraColors.primaryNavy,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'የደህንነት ፒን ኮድ (Quick 4-Digit POS PIN)',
                                    style: KeraTypography.titleSmall(),
                                  ),
                                  Text(
                                    'ለካሳሪዎች የፈጣን ሽያጭ ማረጋገጫ ፒን',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: KeraColors.borderVariant),
                              ),
                              child: Text(
                                'ተዘጋጅቷል',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // Two-Factor SMS
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.sms_rounded,
                                color: KeraColors.primaryNavy,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'የ2-ደረጃ ማረጋገጫ (2FA)',
                                    style: KeraTypography.titleSmall(),
                                  ),
                                  Text(
                                    '+251 91 **** 892 ላይ ነቅቷል',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.utilityTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: KeraColors.utilityTeal.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ገባሪ (ON)',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.utilityTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KeraSpacing.lg),

                  // Section 4: Sign Out / Account Exit
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(
                        color: KeraColors.error.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KeraColors.errorBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: KeraColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ከመለያዎ መውጣት ይፈልጋሉ?',
                                    style: KeraTypography.titleMedium(),
                                  ),
                                  Text(
                                    'Sign Out of Account',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: KeraColors.borderVariant),
                          ),
                          child: Text(
                            'ማስታወሻ: ከመስመር ውጭ የተመዘገቡ ያልተላኩ ዳታዎች ካሉ አስቀድመው ያመሳስሉ።',
                            style: KeraTypography.bodySmall(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KeraColors.error,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: KeraRadii.borderButton,
                              ),
                            ),
                            onPressed: _showSignOutDialog,
                            icon: const Icon(Icons.exit_to_app_rounded,
                                size: 20),
                            label: Text(
                              'ከመለያ ውጣ (Sign Out / Logout)',
                              style: KeraTypography.titleSmall(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                border: const Border(
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: KeraRadii.borderButton,
                    ),
                  ),
                  onPressed: () {
                    context.showSnackBar(
                      'የደህንነት ቅንብሮች ጸድቀዋል (Security settings confirmed)',
                    );
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    'የደህንነት ቅንብሮችን አፅድቅ (Confirm Security Settings)',
                    style: KeraTypography.titleSmall(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaChip(String label, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMet
            ? KeraColors.stockInBg
            : KeraColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMet ? KeraColors.stockInBorder : KeraColors.borderVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: isMet ? KeraColors.stockInText : KeraColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: KeraTypography.labelSmall(
              color: isMet ? KeraColors.stockInText : KeraColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

