import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
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
  bool _isOfflineError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool forceDiscardUnsynced = false}) async {
    setState(() {
      _errorMessage = null;
      _isOfflineError = false;
    });
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;


    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).login(
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          forceDiscardUnsynced: forceDiscardUnsynced,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    await result.when(
      onSuccess: (user) async {
        if (user.mustChangePassword) {
          context.go('/change-password');
        } else if (user.isAdmin) {
          context.go('/admin');
        } else {
          // Rule 6: Check if first login on phone has 0 parts; if so pull catalog
          final db = ref.read(appDatabaseProvider);
          final firstPart =
              await (db.select(db.spareParts)..limit(1)).getSingleOrNull();

          if (!mounted) return;
          if (firstPart == null) {
            context.go('/initial-sync');
          } else {
            context.go('/home');
          }
        }
      },
      onFailure: (failure) async {
        if (failure is DifferentOwnerConflictFailure) {
          // Rule 4: Different account conflict dialog
          final discardAndProceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.authDifferentOwnerConflictTitle),
              content: Text(
                '${l10n.authDifferentOwnerConflictMessage}\n(${failure.previousOwnerName})',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: context.colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.authDiscardUnsyncedAndLogin),
                ),
              ],
            ),
          );

          if (discardAndProceed == true && mounted) {
            await _handleLogin(forceDiscardUnsynced: true);
          }
          return;
        }

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

        if (failure.code == 'SERVER_UNREACHABLE' ||
            failure is NetworkFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = failure.message;
          });
          return;
        }

        String msg;
        switch (failure.code) {
          case 'INVALID_CREDENTIALS':
            msg = l10n.authWrongPassword;
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
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded),
            tooltip: 'Server Connection Settings',
            onPressed: () => _showServerConfigDialog(context),
          ),
          const Padding(
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
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
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
                          if (_isOfflineError) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.settings_ethernet_rounded, size: 20),
                              tooltip: 'Server Settings',
                              color: colorScheme.error,
                              onPressed: () => _showServerConfigDialog(context),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.retry),
                              onPressed: _handleLogin,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Online Requirement Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_outlined, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.authRequiresInternetNotice,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _phoneController.text = '0900000000';
                                _passwordController.text = 'AdminPassword123!';
                                _errorMessage = null;
                              });
                            },
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      label: const Text('Fill Admin Credentials'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

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

  Future<void> _showServerConfigDialog(BuildContext context) async {
    final serverController =
        TextEditingController(text: AppConstants.apiBaseUrl);
    String? statusMessage;
    bool isTesting = false;
    bool? testSuccess;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.dns_rounded,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Server Settings')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure API Base URL to connect over Wi-Fi, hotspot, or USB tether:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serverController,
                    decoration: InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.137.146:7000/api/v1',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setDialogState(() => serverController.clear()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Wi-Fi (.146)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://192.168.137.146:7000/api/v1';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('USB (127.0.0.1)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://127.0.0.1:7000/api/v1';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Emulator (10.0.2.2)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://10.0.2.2:7000/api/v1';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isTesting
                        ? null
                        : () async {
                            setDialogState(() {
                              isTesting = true;
                              statusMessage = null;
                              testSuccess = null;
                            });
                            try {
                              final url = serverController.text.trim();
                              final testDio = Dio(
                                BaseOptions(
                                  baseUrl: url,
                                  connectTimeout: const Duration(seconds: 3),
                                  receiveTimeout: const Duration(seconds: 3),
                                ),
                              );
                              final res = await testDio.get('/health');
                              if (res.statusCode == 200) {
                                setDialogState(() {
                                  isTesting = false;
                                  testSuccess = true;
                                  statusMessage =
                                      'Connected! Backend is reachable.';
                                });
                              } else {
                                setDialogState(() {
                                  isTesting = false;
                                  testSuccess = false;
                                  statusMessage =
                                      'Server response: ${res.statusCode}';
                                });
                              }
                            } catch (_) {
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = false;
                                statusMessage =
                                    'Connection failed. Check IP & port.';
                              });
                            }
                          },
                    icon: isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Test Connection'),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          testSuccess == true
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 16,
                          color:
                              testSuccess == true ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: testSuccess == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final target = serverController.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  if (target.isNotEmpty) {
                    AppConstants.setApiBaseUrl(target);
                    final sessionStore = ref.read(sessionStoreProvider);
                    await sessionStore.saveApiBaseUrl(target);
                    final authRepo = ref.read(authRepositoryProvider);
                    if (authRepo is ApiAuthRepository) {
                      authRepo.dio.options.baseUrl = target;
                    }
                  }
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Server URL set to: $target')),
                  );
                },
                child: const Text('Save & Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
