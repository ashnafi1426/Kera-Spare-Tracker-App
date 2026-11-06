import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../controllers/auth_controller.dart';

/// Pixel-perfect native mobile registration screen strictly matching Stitch Design Page 02.
///
/// Layout:
/// - Clean ambient background with subtle warmth and top ambient glow
/// - Top App Bar: Back arrow, Kera Logo + "Kera Spare" & "Merchant Registration", Language Switcher Pill, Support Headset
/// - Stepper & Status Bar: "1 of 2" indicator with progress track, "Offline Ready" soft-orange chip
/// - Hero Title & Warehouse Graphic Banner: Ethiopian title & subtitle with stylized 3D warehouse rack illustration
/// - Main Form Card: White rounded container with subtle border & soft elevation
///   - Section 1: Personal Information (Full Name, Phone Number with Ethiopian flag pill)
///   - Section 2: Business Information (Business Name, Password, Confirm Password with visibility toggles)
///   - Terms of Service & Privacy Policy agreement checkbox
///   - Primary CTA: Deep Navy "Create Account / መለያ ይፍጠሩ →" full-width pill button
/// - Footer: "Already have an account? Sign In" (with Orange highlight)
/// - Bottom Fluid Accent Waves in Brand Navy & Orange
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;
  bool _isOfflineError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _isOfflineError = false;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'እባክዎን በአገልግሎት መመሪያ እና ደንብ ይስማሙ (Please agree to terms)',
            style: TextStyle(fontFamily: KeraTypography.fontEthiopic),
          ),
          backgroundColor: KeraColors.orange700,
        ),
      );
      return;
    }

    final l10n = context.l10n;
    setState(() => _isLoading = true);

    // Normalize phone number: if entered as 9XXXXXXXX or 09XXXXXXXX, ensure proper format
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    final result = await ref.read(authControllerProvider.notifier).register(
          phoneNumber: phone,
          businessName: _businessNameController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      onSuccess: (_) {
        context.go('/pending-approval', extra: {
          'businessName': _businessNameController.text.trim(),
          'phoneNumber': phone,
        });
      },
      onFailure: (failure) {
        if (failure is OfflineInternetRequiredFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = l10n.authOfflineInternetRequired;
          });
          return;
        }

        if (failure.code == 'NO_INTERNET') {
          setState(() {
            _isOfflineError = true;
            _errorMessage = l10n.authNoInternet;
          });
          return;
        }

        if (failure.code == 'SERVER_UNREACHABLE' || failure is NetworkFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = failure.message;
          });
          return;
        }

        String msg;
        switch (failure.code) {
          case 'PHONE_TAKEN':
            msg = l10n.authPhoneTaken;
            break;
          case 'ACCOUNT_SUSPENDED':
            msg = l10n.authAccountSuspended;
            break;
          case 'SERVER_ERROR':
            msg = l10n.authServerError;
            break;
          default:
            msg = failure.message;
        }
        setState(() => _errorMessage = msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? KeraColors.navy900 : KeraColors.navy50,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const RadialGradient(
                        center: Alignment(0, -0.6),
                        radius: 1.2,
                        colors: [
                          KeraColors.splashRadialNavy,
                          KeraColors.navy900,
                        ],
                      )
                    : const RadialGradient(
                        center: Alignment(0, -0.7),
                        radius: 1.1,
                        colors: [
                          KeraColors.splashBgLightWarm,
                          KeraColors.splashBgLightNeutral,
                          KeraColors.navy50,
                        ],
                      ),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(context),

                // Scrollable Form Canvas
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Stepper & Offline Badge Row
                            _buildStepAndStatusRow(context),
                            const SizedBox(height: 14),

                            // 2. Hero Title & Warehouse Graphic Banner
                            _buildHeroBanner(context),
                            const SizedBox(height: 16),

                            // 3. Error Banner (if error occurred)
                            if (_errorMessage != null) ...[
                              _buildErrorBanner(context),
                              const SizedBox(height: 12),
                            ],

                            // 4. Main Form Card
                            _buildMainFormCard(context),
                            const SizedBox(height: 20),

                            // 5. Bottom Sign In Footer Link
                            _buildSignInFooter(context),
                            const SizedBox(height: 48), // Padding above bottom wave
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Decorative Accent Wave (Brand Navy & Orange)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BottomWavePainter(isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopAppBar(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : KeraColors.navy900,
              size: 24,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            tooltip: 'ወደ ኋላ / Back',
          ),

          // Brand Logo & Text Cluster
          const KeraLogoWidget(
            size: 36,
            borderRadius: 9,
            showShadow: false,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kera Spare',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : KeraColors.navy900,
                  ),
                ),
                Text(
                  l10n.merchantRegistration,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: KeraColors.textMutedColor,
                  ),
                ),
              ],
            ),
          ),

          // Language Selector Pill
          _buildLanguagePill(context),
          const SizedBox(width: 8),

          // Support Headset Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? KeraColors.navy800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? KeraColors.navy600.withValues(alpha: 0.4)
                    : KeraColors.border,
                width: 1,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.headset_mic_outlined,
                size: 20,
                color: isDark ? Colors.white : KeraColors.navy800,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('የደንበኞች ድጋፍ: +251 911 000 000 / support@keraspares.com'),
                    backgroundColor: KeraColors.navy800,
                  ),
                );
              },
              tooltip: 'ድጋፍ / Support',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(BuildContext context) {
    final isDark = context.isDark;
    final currentLocale = ref.watch(localeControllerProvider);
    final isAmharic = currentLocale.languageCode == 'am';

    return InkWell(
      onTap: () {
        ref.read(localeControllerProvider.notifier).toggleLocale();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? KeraColors.navy800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? KeraColors.navy600.withValues(alpha: 0.4)
                : KeraColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: isDark ? Colors.white : KeraColors.navy800,
            ),
            const SizedBox(width: 5),
            Text(
              isAmharic ? 'አማ/EN' : 'EN/አማ',
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stepper & Status Row
  // ---------------------------------------------------------------------------
  Widget _buildStepAndStatusRow(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Row(
      children: [
        // Step number circle badge: "1"
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: KeraColors.navy800,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text "of 2"
        Text(
          l10n.stepOfTwo('1').replaceFirst('1 ', ''), // Renders "of 2" or "ከ 2"
          style: TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
          ),
        ),

        // Responsive horizontal step indicator bar
        Expanded(
          child: Container(
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? KeraColors.navy800
                  : KeraColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: KeraColors.navy800,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Offline Ready pill chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: KeraColors.orange100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KeraColors.orange500.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 14,
                color: KeraColors.orange700,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.offlineReady,
                style: const TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: KeraColors.orange700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Banner (Title & Warehouse Graphic)
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Left Title & Subtitle
        Padding(
          padding: const EdgeInsets.only(right: 96.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.registerHeroTitle,
                style: TextStyle(
                  fontFamily: KeraTypography.fontEthiopic,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : KeraColors.navy900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.registerHeroSubtitle,
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? KeraColors.navy100.withValues(alpha: 0.9)
                      : KeraColors.textMutedColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        // Stylized Warehouse Rack Graphic
        const SizedBox(
          width: 90,
          height: 64,
          child: _WarehouseIllustration(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error Banner
  // ---------------------------------------------------------------------------
  Widget _buildErrorBanner(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KeraColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KeraColors.orange500.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: KeraColors.orange700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: KeraTypography.fontEthiopic,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KeraColors.orange700,
              ),
            ),
          ),
          if (_isOfflineError) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: KeraColors.orange700,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              onPressed: _handleRegister,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Form Card
  // ---------------------------------------------------------------------------
  Widget _buildMainFormCard(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? KeraColors.navy800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.4)
              : KeraColors.border.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : KeraColors.navy800.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // SECTION 1: Personal Information
            // =================================================================
            _buildSectionHeader(
              context,
              icon: Icons.person_rounded,
              title: l10n.personalInformation,
              subtitle: l10n.personalInfoAmharic,
            ),
            const SizedBox(height: 14),

            // Field 1: Full Name / ሙሉ ስም *
            _buildFieldLabel(context, label: l10n.fullNameLabel, isRequired: true),
            const SizedBox(height: 6),
            _buildInputField(
              context,
              controller: _fullNameController,
              hintText: l10n.enterFullNameHint,
              prefixIcon: Icons.person_outline_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.fullNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field 2: Phone Number / ስልክ ቁጥር *
            _buildFieldLabel(context, label: l10n.phoneLabel, isRequired: true),
            const SizedBox(height: 6),
            _buildPhoneInputField(context),
            const SizedBox(height: 20),

            // =================================================================
            // SECTION 2: Business Information
            // =================================================================
            _buildSectionHeader(
              context,
              icon: Icons.business_center_rounded,
              title: l10n.businessInformation,
              subtitle: l10n.businessInfoAmharic,
            ),
            const SizedBox(height: 14),

            // Field 3: Business Name / የንግድ ስም *
            _buildFieldLabel(context, label: l10n.businessNameLabel, isRequired: true),
            const SizedBox(height: 6),
            _buildInputField(
              context,
              controller: _businessNameController,
              hintText: l10n.enterBusinessNamePlaceholder,
              prefixIcon: Icons.storefront_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.businessNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field 4: Password / የይለፍ ቃል *
            _buildFieldLabel(context, label: l10n.passwordInputLabel, isRequired: true),
            const SizedBox(height: 6),
            _buildInputField(
              context,
              controller: _passwordController,
              hintText: l10n.createPasswordPlaceholder,
              prefixIcon: Icons.lock_outline_rounded,
              isObscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return l10n.passwordRequired;
                }
                if (val.length < 6) {
                  return l10n.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field 5: Confirm Password / የይለፍ ቃል ያረጋግጡ *
            _buildFieldLabel(context, label: l10n.confirmPasswordInputLabel, isRequired: true),
            const SizedBox(height: 6),
            _buildInputField(
              context,
              controller: _confirmPasswordController,
              hintText: l10n.confirmPasswordPlaceholder,
              prefixIcon: Icons.shield_outlined,
              isObscure: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              validator: (val) {
                if (val != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // =================================================================
            // Terms & Conditions Checkbox
            // =================================================================
            _buildTermsCheckbox(context),
            const SizedBox(height: 20),

            // =================================================================
            // Primary Submit CTA Button: "Create Account / መለያ ይፍጠሩ →"
            // =================================================================
            _buildCreateAccountButton(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Header with Round Icon Badge & Underline Divider
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = context.isDark;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? KeraColors.navy600.withValues(alpha: 0.35)
                    : KeraColors.navy100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : KeraColors.navy800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: KeraTypography.fontLatin,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : KeraColors.navy900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: KeraTypography.fontEthiopic,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: KeraColors.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.3)
              : KeraColors.border.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Field Label with Required Asterisk
  // ---------------------------------------------------------------------------
  Widget _buildFieldLabel(
    BuildContext context, {
    required String label,
    required bool isRequired,
  }) {
    final isDark = context.isDark;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : KeraColors.navy900,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: KeraColors.orange700,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Rounded Input Field
  // ---------------------------------------------------------------------------
  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? KeraColors.navy900.withValues(alpha: 0.5) : KeraColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.4)
              : KeraColors.border,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        validator: validator,
        style: TextStyle(
          fontFamily: KeraTypography.fontLatin,
          fontSize: 14,
          color: isDark ? Colors.white : KeraColors.navy900,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 13,
            color: KeraColors.textMutedColor,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone Input Field with Ethiopian Flag Dropdown Pill
  // ---------------------------------------------------------------------------
  Widget _buildPhoneInputField(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Row(
      children: [
        // Flag pill
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark
                ? KeraColors.navy900.withValues(alpha: 0.6)
                : KeraColors.flagContainerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? KeraColors.navy600.withValues(alpha: 0.4)
                  : KeraColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🇪🇹',
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 6),
              Text(
                '+251',
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : KeraColors.navy900,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Phone input text container
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? KeraColors.navy900.withValues(alpha: 0.5)
                  : KeraColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? KeraColors.navy600.withValues(alpha: 0.4)
                    : KeraColors.border,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                hintText: l10n.phoneInputHint,
                hintStyle: const TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: KeraColors.textMutedColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.phoneRequired;
                }
                return Validators.validateEthiopianPhone(val) != null
                    ? l10n.phoneInvalid
                    : null;
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Terms of Service & Privacy Policy Checkbox
  // ---------------------------------------------------------------------------
  Widget _buildTermsCheckbox(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _agreedToTerms
                    ? KeraColors.navy800
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _agreedToTerms
                      ? KeraColors.navy800
                      : (isDark ? KeraColors.navy100 : KeraColors.border),
                  width: 1.5,
                ),
              ),
              child: _agreedToTerms
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(
                        fontFamily: KeraTypography.fontLatin,
                        fontSize: 12,
                        color: isDark ? Colors.white : KeraColors.navy900,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: KeraColors.navy600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: KeraColors.navy600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.termsAgreementLine2,
                    style: const TextStyle(
                      fontFamily: KeraTypography.fontEthiopic,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: KeraColors.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Create Account CTA Button
  // ---------------------------------------------------------------------------
  Widget _buildCreateAccountButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.navy900,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KeraColors.navy900.withValues(alpha: 0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.createAccountAction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: KeraTypography.fontLatin,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Sign In Footer Link
  // ---------------------------------------------------------------------------
  Widget _buildSignInFooter(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Center(
      child: InkWell(
        onTap: () => context.go('/login'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: '${l10n.alreadyHaveAccountPrefix} ',
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
              ),
              children: [
                TextSpan(
                  text: l10n.signInHighlight,
                  style: const TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontWeight: FontWeight.w700,
                    color: KeraColors.orange600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Stylized Warehouse Rack Illustration (Vector Painter)
// =============================================================================
class _WarehouseIllustration extends StatelessWidget {
  const _WarehouseIllustration();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return CustomPaint(
      painter: _WarehouseRackPainter(isDark: isDark),
    );
  }
}

class _WarehouseRackPainter extends CustomPainter {
  final bool isDark;

  const _WarehouseRackPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient glow behind rack
    final glowPaint = Paint()
      ..color = isDark
          ? KeraColors.navy600.withValues(alpha: 0.15)
          : KeraColors.navy100.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(w * 0.7, h * 0.5), 28, glowPaint);

    // Rack frame (Steel uprights)
    final rackPaint = Paint()
      ..color = isDark
          ? KeraColors.navy600
          : KeraColors.navy600.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rackX = w * 0.45;
    final rackW = w * 0.5;

    // Uprights
    canvas.drawLine(Offset(rackX, h * 0.1), Offset(rackX, h * 0.9), rackPaint);
    canvas.drawLine(Offset(rackX + rackW, h * 0.1), Offset(rackX + rackW, h * 0.9), rackPaint);

    // Shelves
    canvas.drawLine(Offset(rackX, h * 0.35), Offset(rackX + rackW, h * 0.35), rackPaint);
    canvas.drawLine(Offset(rackX, h * 0.65), Offset(rackX + rackW, h * 0.65), rackPaint);
    canvas.drawLine(Offset(rackX, h * 0.9), Offset(rackX + rackW, h * 0.9), rackPaint);

    // Top shelf boxes
    final boxPaint = Paint()
      ..color = isDark ? KeraColors.navy800 : KeraColors.navy100
      ..style = PaintingStyle.fill;
    final boxBorder = Paint()
      ..color = isDark ? KeraColors.navy600 : KeraColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final box1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(rackX + 4, h * 0.15, rackW * 0.4, h * 0.18),
      const Radius.circular(2),
    );
    canvas.drawRRect(box1, boxPaint);
    canvas.drawRRect(box1, boxBorder);

    final box2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(rackX + rackW * 0.5, h * 0.15, rackW * 0.42, h * 0.18),
      const Radius.circular(2),
    );
    canvas.drawRRect(box2, boxPaint);
    canvas.drawRRect(box2, boxBorder);

    // Middle shelf boxes
    final box3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(rackX + 4, h * 0.42, rackW * 0.5, h * 0.20),
      const Radius.circular(2),
    );
    canvas.drawRRect(box3, boxPaint);
    canvas.drawRRect(box3, boxBorder);

    // Stylized Wheel / Gear in foreground (Brand Navy & Orange)
    final wheelCenter = Offset(w * 0.28, h * 0.68);
    final tirePaint = Paint()
      ..color = isDark ? Colors.white : KeraColors.navy900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(wheelCenter, 14, tirePaint);

    final hubPaint = Paint()
      ..color = KeraColors.orange500
      ..style = PaintingStyle.fill;
    canvas.drawCircle(wheelCenter, 6, hubPaint);

    final hubCenterPaint = Paint()
      ..color = isDark ? KeraColors.navy900 : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(wheelCenter, 2.5, hubCenterPaint);

    // Orange accent cart/skid under the wheel
    final skidPaint = Paint()
      ..color = KeraColors.orange500
      ..style = PaintingStyle.fill;
    final skidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.82, w * 0.35, 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(skidRect, skidPaint);
  }

  @override
  bool shouldRepaint(covariant _WarehouseRackPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// =============================================================================
// Bottom Ambient Wave Painter (Brand Navy & Orange Swooshes)
// =============================================================================
class _BottomWavePainter extends CustomPainter {
  final bool isDark;

  const _BottomWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Navy Wave
    final navyPaint = Paint()
      ..color = isDark ? KeraColors.navy800 : KeraColors.navy900
      ..style = PaintingStyle.fill;

    final navyPath = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.25, h * 0.8, w * 0.55, h * 0.3)
      ..quadraticBezierTo(w * 0.8, -h * 0.1, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(navyPath, navyPaint);

    // Orange Accent Wave
    final orangePaint = Paint()
      ..color = KeraColors.orange500
      ..style = PaintingStyle.fill;

    final orangePath = Path()
      ..moveTo(w * 0.3, h)
      ..quadraticBezierTo(w * 0.55, h * 0.4, w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.92, h * 0.75, w, h * 0.2)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(orangePath, orangePaint);
  }

  @override
  bool shouldRepaint(covariant _BottomWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
