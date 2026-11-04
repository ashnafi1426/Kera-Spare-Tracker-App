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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('የአገልግሎት ውሎች', 'Terms of Service')),
        content: SingleChildScrollView(
          child: Text(
            context.tr(
              'ኬራ ስፔር ትራከር በኢትዮጵያ ላሉ የከባድ መኪና እና አውቶሞቲቭ መለዋወጫ ነጋዴዎች የተዘጋጀ የሽያጭ እና የክምችት መቆጣጠሪያ መድረክ ነው። መረጃዎችህ በከፍተኛ ጥበቃ እና ሚስጥራዊነት ይያዛሉ።',
              'Kera Spare Tracker is an offline-first inventory and POS SaaS platform designed for automotive and heavy machinery spare parts businesses in Kera, Addis Ababa, Ethiopia. All tenant data is strictly isolated and encrypted.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('እሺ', 'Close')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('የግላዊነት ፖሊሲ', 'Privacy Policy')),
        content: SingleChildScrollView(
          child: Text(
            context.tr(
              'የእያንዳንዱ የሱቅ ባለቤት መረጃ (ዕቃዎች፣ ሽያጮች፣ ዋጋዎች እና ሪፖርቶች) ሙሉ በሙሉ የተከለለ ሲሆን ሌሎች ባለቤቶች ወይም ያልተፈቀደላቸው አካላት ማየት አይችሉም። ከመስመር ውጭ የገቡ መረጃዎች የበይነመረብ ግንኙነት ሲገኝ ብቻ በደህንነት ይመሳሰላሉ።',
              'Each owner’s data (inventory, sales, cost snapshots, and financial reports) is strictly tenant-isolated and cannot be viewed by other owners. Offline transactions sync securely when connectivity is restored.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('እሺ', 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final footerBg = isDark ? const Color(0xFF071220) : const Color(0xFF0B2A5B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFFA5B4CB);

    return Container(
      width: double.infinity,
      color: footerBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo & App Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const KeraLogoWidget(size: 28, borderRadius: 8),
              const SizedBox(width: 10),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: KeraColors.brandOrange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    color: KeraColors.brandOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'የከባድ መኪና እና ማሽነሪ መለዋወጫዎች መከታተያ',
              'Heavy Machinery & Automotive Spare Parts POS',
            ),
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
                    const Icon(Icons.support_agent_rounded, size: 14, color: KeraColors.brandOrange),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('ድጋፍ · Support', 'Support'),
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showTermsDialog(context),
                child: Text(
                  context.tr('የአገልግሎት ውሎች', 'Terms'),
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
              InkWell(
                onTap: () => _showPrivacyDialog(context),
                child: Text(
                  context.tr('ግላዊነት', 'Privacy'),
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
                  'አማርኛ',
                  style: TextStyle(
                    color: ref.watch(localeControllerProvider).languageCode == 'am'
                        ? KeraColors.brandOrange
                        : textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('  •  ', style: TextStyle(color: textMuted, fontSize: 12)),
              InkWell(
                onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                child: Text(
                  'English',
                  style: TextStyle(
                    color: ref.watch(localeControllerProvider).languageCode == 'en'
                        ? KeraColors.brandOrange
                        : textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Copyright
          Text(
            '© 2026 Kera Spare Tracker. All rights reserved. Addis Ababa, Ethiopia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
