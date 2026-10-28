import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_lock_service.dart';
import '../../../../core/utils/context_extensions.dart';

/// Reusable App Lock configuration card for Owners and Administrators.
class AppLockSettingsCard extends ConsumerWidget {
  const AppLockSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockStateProvider);
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.lock_outline_rounded,
              color: lockState.isEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              l10n.appLockTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              lockState.isEnabled ? l10n.appLockEnabled : l10n.appLockDisabled,
            ),
            value: lockState.isEnabled,
            onChanged: (val) async {
              if (val) {
                await ref.read(appLockServiceProvider).checkBiometricsSupport();
                if (context.mounted) {
                  _showSetPinDialog(context, ref);
                }
              } else {
                _showDisableAppLockDialog(context, ref);
              }
            },
          ),
          if (lockState.isEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.pin_rounded,
                color: colorScheme.secondary,
              ),
              title: Text(
                l10n.changePin,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await ref.read(appLockServiceProvider).checkBiometricsSupport();
                if (context.mounted) {
                  _showSetPinDialog(context, ref, isChanging: true);
                }
              },
            ),
            if (lockState.isBiometricsSupported) ...[
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: lockState.isBiometricsEnabled
                      ? Colors.teal
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  l10n.appLockBiometrics,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.appLockBiometricsDesc),
                value: lockState.isBiometricsEnabled,
                onChanged: (val) {
                  ref.read(appLockServiceProvider).setBiometricsEnabled(val);
                },
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.timer_outlined,
                color: Colors.indigo.shade700,
              ),
              title: Text(
                l10n.appLockTimeout,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(switch (lockState.timeout) {
                AppLockTimeout.immediately => l10n.appLockTimeoutImmediately,
                AppLockTimeout.oneMinute => l10n.appLockTimeout1Min,
                AppLockTimeout.fiveMinutes => l10n.appLockTimeout5Min,
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showTimeoutDialog(context, ref, lockState.timeout),
            ),
          ],
        ],
      ),
    );
  }

  void _showSetPinDialog(
    BuildContext context,
    WidgetRef ref, {
    bool isChanging = false,
  }) {
    final pinController1 = TextEditingController();
    final pinController2 = TextEditingController();
    String? pinError;
    final lockService = ref.read(appLockServiceProvider);
    bool enableBiometrics = lockService.state.isBiometricsSupported;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final l10n = ctx.l10n;
            final colorScheme = ctx.colorScheme;

            return AlertDialog(
              title: Text(isChanging ? l10n.changePin : l10n.setPinTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pinController1,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: l10n.enterNewPin,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController2,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: l10n.reenterPin,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (lockService.state.isBiometricsSupported) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: enableBiometrics,
                        title: Text(l10n.appLockBiometrics,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(l10n.appLockBiometricsDesc,
                            style: const TextStyle(fontSize: 12)),
                        onChanged: (v) =>
                            setDialogState(() => enableBiometrics = v),
                      ),
                    ],
                    if (pinError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          pinError!,
                          style: TextStyle(
                              color: colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin1 = pinController1.text.trim();
                    final pin2 = pinController2.text.trim();

                    if (pin1.length < 4 || pin1.length > 6) {
                      setDialogState(() {
                        pinError = l10n.pinLengthError;
                      });
                      return;
                    }
                    if (pin1 != pin2) {
                      setDialogState(() {
                        pinError = l10n.pinsDoNotMatch;
                      });
                      return;
                    }

                    final success =
                        await ref.read(appLockServiceProvider).setPin(pin1);
                    if (success) {
                      if (lockService.state.isBiometricsSupported &&
                          enableBiometrics) {
                        await ref
                            .read(appLockServiceProvider)
                            .setBiometricsEnabled(true);
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          context.showSnackBar(l10n.pinSetSuccess);
                        }
                      }
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisableAppLockDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.appLockTitle),
        content: Text(l10n.appLockDisabled),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () async {
              await ref.read(appLockServiceProvider).disableAppLock();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                context.showSnackBar(l10n.appLockDisabled);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLockTimeout currentTimeout,
  ) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.appLockTimeout),
        children: AppLockTimeout.values.map((timeout) {
          final title = switch (timeout) {
            AppLockTimeout.immediately => l10n.appLockTimeoutImmediately,
            AppLockTimeout.oneMinute => l10n.appLockTimeout1Min,
            AppLockTimeout.fiveMinutes => l10n.appLockTimeout5Min,
          };
          return SimpleDialogOption(
            onPressed: () {
              ref.read(appLockServiceProvider).setTimeout(timeout);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  timeout == currentTimeout
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: timeout == currentTimeout
                      ? context.colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
