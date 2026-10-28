import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../controllers/auth_controller.dart';

/// Unobtrusive banner shown when tokens have expired or been revoked.
/// App remains fully operational offline; tapping the banner allows re-authentication.
class NeedsLoginBanner extends ConsumerWidget {
  const NeedsLoginBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsLogin = ref.watch(needsLoginProvider);
    if (!needsLogin) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = context.theme;

    return Container(
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.sync_disabled_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.authNeedsLoginBanner,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.amber.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => context.push('/login'),
              child: Text(
                l10n.authNeedsLoginAction,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-blocking warning banner shown when the device has been offline
/// for longer than the server-mandated limit (Rule 7).
class OfflineMaxDaysBanner extends ConsumerWidget {
  const OfflineMaxDaysBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExceeded = ref.watch(offlineMaxDaysExceededProvider);
    final isExceeded = asyncExceeded.value ?? false;
    if (!isExceeded) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = context.theme;

    return Container(
      width: double.infinity,
      color: Colors.deepOrange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.authOfflineMaxDaysWarning(90),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner displayed when the server has marked the owner's account as suspended.
/// Sync is paused, but all local data remains completely accessible and exportable.
class AccountSuspendedBanner extends ConsumerWidget {
  const AccountSuspendedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuspended = ref.watch(accountSuspendedProvider);
    if (!isSuspended) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = context.theme;

    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.block_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.accountSuspendedMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown when the user's password was changed on another device.
class PasswordChangedBanner extends ConsumerWidget {
  const PasswordChangedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVal = ref.watch(passwordChangedRemotelyProvider);
    final isChanged = asyncVal.value ?? false;
    if (!isChanged) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = context.theme;

    return Container(
      width: double.infinity,
      color: Colors.deepOrange.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.passwordChangedRemotelyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => context.push('/login'),
              child: Text(
                l10n.authNeedsLoginAction,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
