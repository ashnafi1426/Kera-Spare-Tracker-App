import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/language_selector_widget.dart';

/// Screen allowing unauthenticated users to reset their forgotten password via Phone + OTP.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (RegExp(r'[a-zA-Z]').hasMatch(pass) && RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (pass.length >= 8 && RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
    return score;
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    final phoneErr = Validators.validateEthiopianPhone(phone);
    if (phoneErr != null) {
      setState(() => _errorMessage = context.tr('ትክክለኛ የስልክ ቁጥር ያስገቡ', 'Please enter a valid phone number'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _codeSent = true;
      _errorMessage = null;
      _otpController.text = '123456'; // Default demo OTP for offline verification
    });
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('የማረጋገጫ ኮድ ወደ $phone ተልኳል', 'Verification code sent to $phone'),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_otpController.text.trim().length < 4) {
      setState(() => _errorMessage = context.tr('ትክክለኛ የ OTP ኮድ ያስገቡ', 'Please enter a valid 4-6 digit OTP code'));
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = context.tr('የይለፍ ቃሎቹ አይመሳሰሉም', 'Passwords do not match'));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _successMessage = context.tr(
        'የይለፍ ቃልዎ በተሳካ ሁኔታ ተቀይሯል! አሁን መግባት ይችላሉ።',
        'Password reset successfully! You can now log in.',
      );
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final strength = _calculateStrength(_newPasswordController.text);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
                          onPressed: () => context.pop(),
                        ),
                        const KeraLogoWidget(size: 34, borderRadius: 8),
                        const LanguageSegmentedSwitch(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Icon & Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F264A) : KeraColors.orange100,
                          shape: BoxShape.circle,
                          border: Border.all(color: KeraColors.brandOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 38,
                          color: KeraColors.brandOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr('የይለፍ ቃል መቀየሪያ', 'Reset Forgotten Password'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'የስልክ ቁጥርዎን በማስገባት በማረጋገጫ ኮድ አዲስ የይለፍ ቃል ያዘጋጁ።',
                        'Enter your phone number to receive an OTP code and set a new password.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success Banner
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form Container Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phone Field
                          Text(
                            context.tr('ስልክ ቁጥር', 'Phone Number'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_codeSent,
                            decoration: InputDecoration(
                              hintText: '0912345678',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: context.borderColor)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇪🇹', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+251',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              suffixIcon: !_codeSent
                                  ? TextButton(
                                      onPressed: _isLoading ? null : _handleSendOtp,
                                      child: Text(
                                        context.tr('ኮድ ላክ', 'Send OTP'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: KeraColors.orange700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return context.tr('ስልክ ቁጥር ያስፈልጋል', 'Phone number is required');
                              }
                              return Validators.validateEthiopianPhone(val) != null
                                  ? context.tr('ትክክለኛ ስልክ ቁጥር ያስገቡ', 'Invalid Ethiopian phone format')
                                  : null;
                            },
                          ),
                          if (!_codeSent) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KeraColors.brandOrange,
                                  foregroundColor: KeraColors.navy900,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(KeraColors.navy900),
                                        ),
                                      )
                                    : Text(
                                        context.tr('የማረጋገጫ ኮድ ላክ', 'Send Verification Code'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: KeraColors.navy900,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // If code sent, show OTP & new password
                          if (_codeSent) ...[
                            Text(
                              context.tr('የማረጋገጫ ኮድ', 'Verification OTP Code'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                hintText: '123456',
                                counterText: '',
                                prefixIcon: const Icon(Icons.dialpad_rounded),
                                suffixIcon: _resendCountdown > 0
                                    ? Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          '${_resendCountdown}s',
                                          style: TextStyle(color: context.textSecondaryColor),
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _handleSendOtp,
                                        child: Text(
                                          context.tr('በድጋሚ ላክ', 'Resend'),
                                          style: const TextStyle(
                                            color: AdminColors.keraOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            Text(
                              context.tr('አዲስ የይለፍ ቃል', 'New Password'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return context.tr('ቢያንስ 6 ቁምፊዎች ያስፈልጋሉ', 'Minimum 6 characters required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Strength indicator bars
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: strength >= 1
                                          ? (strength == 1
                                              ? KeraColors.orange700
                                              : (strength == 2 ? KeraColors.brandOrange : KeraColors.brandNavy))
                                          : context.borderColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: strength >= 2
                                          ? (strength == 2 ? KeraColors.brandOrange : KeraColors.brandNavy)
                                          : context.borderColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: strength >= 3 ? KeraColors.brandNavy : context.borderColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            Text(
                              context.tr('አዲሱን የይለፍ ቃል ያረጋግጡ', 'Confirm New Password'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.verified_user_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (val) {
                                if (val != _newPasswordController.text) {
                                  return context.tr('የይለፍ ቃሎቹ አይመሳሰሉም', 'Passwords do not match');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KeraColors.brandOrange,
                                  foregroundColor: KeraColors.navy900,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(KeraColors.navy900),
                                        ),
                                      )
                                    : Text(
                                        context.tr('የይለፍ ቃል ቀይር', 'Reset Password'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: KeraColors.navy900,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to login link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(
                          context.tr('ወደ መግቢያ ገጽ ተመለስ', 'Back to Login'),
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

