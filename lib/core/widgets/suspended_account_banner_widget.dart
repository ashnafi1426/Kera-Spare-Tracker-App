import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/app_config_provider.dart';
import '../theme/app_theme.dart';

/// Prominent notification widget displayed when the owner's account has been suspended.
/// Informs the user that their local data is safe, displays any reason, and provides support contacts.
class SuspendedAccountBannerWidget extends ConsumerWidget {
  const SuspendedAccountBannerWidget({super.key});

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _openTelegram(String handle) async {
    final clean = handle.replaceAll('@', '');
    final uri = Uri.parse('https://t.me/$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    if (user == null || !user.isSuspended) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigNotifierProvider).value?.config;
    final supportPhone = config?.supportContact.phone ?? '+251911000000';
    final supportTelegram =
        config?.supportContact.telegram ?? '@KeraSpareSupport';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.block_rounded,
                color: AppTheme.errorColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.accountSuspendedTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.accountSuspendedMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
          ),
          if (user.suspendedReason != null &&
              user.suspendedReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.suspensionReasonLabel(user.suspendedReason!),
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.contactSupportLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _makeCall(supportPhone),
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text(l10n.callSupport),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openTelegram(supportTelegram),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(l10n.telegramSupport),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF0088CC),
                  side: const BorderSide(color: Color(0xFF0088CC)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
