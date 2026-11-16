import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import 'auth_colors.dart';

/// Reusable Top Header Bar for Kera Spare Tracker Authentication screens.
/// Faithfully reproduces the Figma header:
/// - Back navigation chevron [<]
/// - Kera gear logo plaque with [KERA SPARE] title & subtitle
/// - Reactive Language Selector pill [🌐 EN / AM]
/// - Support button [🎧]
class AuthHeader extends ConsumerWidget {
  final String subtitle;
  final VoidCallback? onBackPressed;

  const AuthHeader({
    super.key,
    required this.subtitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final locale = ref.watch(localeControllerProvider);
    final isEnglish = locale.languageCode == 'en';

    final textPrimary = AuthColors.textPrimaryOf(isDark);
    final textSecondary = AuthColors.textSecondaryOf(isDark);
    final borderColor = AuthColors.borderOf(isDark);
    final surfaceColor = AuthColors.surfaceOf(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back Button + Logo + Title Column
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBackPressed ??
                      () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/login');
                        }
                      },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: textPrimary,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Logo Plaque
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.settings_suggest_rounded,
                    color: AuthColors.primaryNavy,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Application Name + Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KERA SPARE',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Language Selector Pill + Support Icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Selector Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(localeControllerProvider.notifier).toggleLocale();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 15,
                          color: textPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEnglish ? 'EN' : 'አማ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Support Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showSupportSheet(context, isDark);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.headset_mic_outlined,
                      size: 21,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSupportSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuthColors.surfaceOf(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuthColors.borderOf(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AuthColors.accentOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('የደንበኞች ድጋፍ', 'Customer Support'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AuthColors.textPrimaryOf(isDark),
                        ),
                      ),
                      Text(
                        context.tr('የቴክኒክ ወይም የመለያ እርዳታ ይፈልጋሉ?', 'Need technical or account help?'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AuthColors.textSecondaryOf(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_in_talk_rounded, color: AuthColors.primaryNavy),
                title: const Text('+251 911 000 000 / +251 977 777 777', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Kera, Addis Ababa, Ethiopia'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: AuthColors.primaryNavy),
                title: const Text('support@keraspares.com', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('24/7 Merchant Support'),
              ),
            ],
          ),
        );
      },
    );
  }
}
