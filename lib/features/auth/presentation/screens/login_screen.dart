import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../controllers/auth_controller.dart';

/// Screen allowing existing spare parts owners to log in with phone and password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).login(
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      onSuccess: (_) {
        context.go('/home');
      },
      onFailure: (failure) {
        setState(() => _errorMessage = failure.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageSegmentedSwitch(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.settings_suggest_rounded,
                          size: 40,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Subtitle
                  Text(
                    l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: colorScheme.error, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Phone Number Input
                  Text(
                    l10n.phoneNumber,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: l10n.phoneNumberHint,
                      prefixIcon: const Icon(Icons.phone_android_rounded),
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
                  const SizedBox(height: 20),

                  // Password Input
                  Text(
                    l10n.password,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: l10n.passwordHint,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
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
                  const SizedBox(height: 28),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppConstants.standardButtonHeight),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.login,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Switch to Register
                  TextButton(
                    onPressed: _isLoading ? null : () => context.go('/register'),
                    child: Text(
                      l10n.dontHaveAccount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
