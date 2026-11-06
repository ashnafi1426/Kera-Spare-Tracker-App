import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/constants.dart';
import '../../providers/locale_provider.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/kera_logo_widget.dart';
import '../tokens/kera_colors.dart';

/// Professional, real-world shared footer for both Owner and Admin areas.
class KeraAppFooter extends ConsumerWidget {
  const KeraAppFooter({super.key});

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showTermsDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.termsOfService),
        content: SingleChildScrollView(
          child: Text(l10n.termsOfServiceDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacyPolicy),
        content: SingleChildScrollView(
          child: Text(l10n.privacyPolicyDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final l10n = context.l10n;
    final footerBg = isDark ? const Color(0xFF061B3F) : const Color(0xFF0B2A5B);
    final textMuted = isDark ? const Color(0xFF9AA7BD) : const Color(0xFFD3DAE8);

    return Container(
      width: double.infinity,
      color: footerBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KeraLogoWidget(size: 28),
              SizedBox(width: 10),
              Text(
                'KERA SPARE TRACKER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appTagline,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),

          // Quick Links (Support, Terms, Privacy)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () => _launchPhone(AppConstants.fallbackSupportPhone),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 14, color: KeraColors.orange500),
                    const SizedBox(width: 4),
                    Text(
                      l10n.supportLabel,
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showTermsDialog(context),
                child: Text(
                  l10n.termsShort,
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
              InkWell(
                onTap: () => _showPrivacyDialog(context),
                child: Text(
                  l10n.privacyShort,
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Language Switch Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('am')),
                child: Text(
                  l10n.amharicLabel,
                  style: TextStyle(
                    color: ref.watch(localeControllerProvider).languageCode == 'am'
                        ? KeraColors.orange500
                        : textMuted,
                    fontSize: 12,
                    fontWeight: ref.watch(localeControllerProvider).languageCode == 'am'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(color: textMuted, fontSize: 12)),
              ),
              InkWell(
                onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                child: Text(
                  l10n.englishLabel,
                  style: TextStyle(
                    color: ref.watch(localeControllerProvider).languageCode == 'en'
                        ? KeraColors.orange500
                        : textMuted,
                    fontSize: 12,
                    fontWeight: ref.watch(localeControllerProvider).languageCode == 'en'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Version ${AppConstants.appVersion} (${AppConstants.appBuildNumber}) · Offline-First Engine',
            style: TextStyle(
              color: textMuted.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
