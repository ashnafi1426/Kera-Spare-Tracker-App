import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_colors.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/phone_number_input.dart';

/// Redesigned Merchant Registration Screen matching approved Figma design (media_1794818559921_0c988908.png):
/// - Unified AuthHeader with Logo plate, KERA SPARE title, Language toggle & Support
/// - Stepper: Step 1 of 2 progress bar + [⚡ Offline ready] badge
/// - Bilingual Page Introduction: "Create your account" + "የመመዝገቢያ ፎርም"
/// - Personal information section: Full name, Phone number with +251 country selector
/// - Business information section: Business name, Password, Confirm password
/// - Deep Navy primary "Sign up →" CTA button
/// - Footer linking to existing account Login
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

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpBackend();
    });
  }

  void _warmUpBackend() {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo is ApiAuthRepository) {
        authRepo.warmUp();
      }
    } catch (_) {}
  }

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
    });

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = context.tr(
          'የይለፍ ቃሎች አይዛመዱም (Passwords do not match)',
          'Passwords do not match',
        );
      });
      return;
    }

    final l10n = context.l10n;
    setState(() => _isLoading = true);

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
            _errorMessage = l10n.authOfflineInternetRequired;
          });
          return;
        }

        if (failure.code == 'NO_INTERNET') {
          setState(() {
            _errorMessage = l10n.authNoInternet;
          });
          return;
        }

        if (failure.code == 'SERVER_UNREACHABLE' || failure is NetworkFailure) {
          setState(() {
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
    final backgroundColor = AuthColors.bgOf(isDark);
    final cardBg = AuthColors.surfaceOf(isDark);
    final borderColor = AuthColors.borderOf(isDark);
    final textPrimary = AuthColors.textPrimaryOf(isDark);
    final textSecondary = AuthColors.textSecondaryOf(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            AuthHeader(
              subtitle: 'Merchant registration',
              onBackPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
                }
              },
            ),

            // 2. Scrollable Registration Form Canvas
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),

                        // 2.1 Stepper & Offline Ready Badge Row
                        _buildStepperRow(context, isDark, textPrimary, textSecondary, borderColor),
                        const SizedBox(height: 18),

                        // 2.2 Page Introduction
                        _buildPageIntroduction(context, textPrimary, textSecondary),
                        const SizedBox(height: 20),

                        // 2.3 Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AuthColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AuthColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AuthColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AuthColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 2.4 Registration Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: AuthColors.cardShadow,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SECTION 1: Personal Information
                                _buildSectionHeader(
                                  icon: Icons.person_outline_rounded,
                                  title: 'Personal information',
                                  amharicTitle: 'የግል መረጃ',
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),
                                const SizedBox(height: 16),

                                // Full Name Field
                                AuthTextField(
                                  label: 'Full name',
                                  amharicLabel: 'ሙሉ ስም',
                                  hintText: 'Enter your full name',
                                  controller: _fullNameController,
                                  prefixIcon: Icons.person_outline_rounded,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (val) => Validators.validateRequired(
                                    val,
                                    fieldName: 'Full name',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Phone Number Field
                                PhoneNumberInput(
                                  controller: _phoneController,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 22),

                                // Section Divider
                                Divider(
                                  color: borderColor.withValues(alpha: 0.8),
                                  height: 1,
                                ),
                                const SizedBox(height: 20),

                                // SECTION 2: Business Information
                                _buildSectionHeader(
                                  icon: Icons.storefront_outlined,
                                  title: 'Business information',
                                  amharicTitle: 'የንግድ መረጃ',
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),
                                const SizedBox(height: 16),

                                // Business Name Field
                                AuthTextField(
                                  label: 'Business name',
                                  amharicLabel: 'የንግድ ስም',
                                  hintText: 'Enter your business name',
                                  controller: _businessNameController,
                                  prefixIcon: Icons.storefront_outlined,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (val) => Validators.validateRequired(
                                    val,
                                    fieldName: 'Business name',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                AuthTextField(
                                  label: 'Password',
                                  amharicLabel: 'የይለፍ ቃል',
                                  hintText: 'Create a password',
                                  controller: _passwordController,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: Validators.validatePassword,
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password Field
                                AuthTextField(
                                  label: 'Confirm password',
                                  amharicLabel: 'የይለፍ ቃል ያረጋግጡ',
                                  hintText: 'Confirm your password',
                                  controller: _confirmPasswordController,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return context.tr(
                                        'የይለፍ ቃል ማረጋገጫ ያስገቡ',
                                        'Please confirm your password',
                                      );
                                    }
                                    if (val != _passwordController.text) {
                                      return context.tr(
                                        'የይለፍ ቃሎች አይዛመዱም',
                                        'Passwords do not match',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 2.5 Primary Sign Up Button
                        AuthPrimaryButton(
                          label: 'Sign up',
                          isLoading: _isLoading,
                          onPressed: () => _handleRegister(),
                        ),
                        const SizedBox(height: 18),

                        // 2.6 Footer: Already have an account? Log in
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: textSecondary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF60A5FA) : AuthColors.primaryNavy,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperRow(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 350,
        child: Row(
          children: [
            // Step number badge: "1"
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AuthColors.primaryNavy,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Text "of 2"
            Text(
              'of 2',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 10),

            // 2-Segment Progress Bar
            Row(
              children: [
                Container(
                  width: 32,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF60A5FA) : AuthColors.primaryNavy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 32,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Offline Ready Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B2D11) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: AuthColors.accentOrange,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Offline ready',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPageIntroduction(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'የመመዝገቢያ ፎርም',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start managing your spare parts business.',
          style: TextStyle(
            fontSize: 13.5,
            color: textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String amharicTitle,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162B4A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFF60A5FA) : AuthColors.primaryNavy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                amharicTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
