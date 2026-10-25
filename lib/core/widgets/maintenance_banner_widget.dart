import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/app_config_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Non-blocking banner indicating system maintenance mode while local offline features stay working.
class MaintenanceBannerWidget extends ConsumerWidget {
  const MaintenanceBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configStateAsync = ref.watch(appConfigNotifierProvider);
    final configState = configStateAsync.value;

    if (configState == null || !configState.config.maintenanceMode.enabled) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final maintenance = configState.config.maintenanceMode;
    final locale = ref.watch(localeControllerProvider);
    final isAmharic = locale.languageCode == 'am';

    final customMsg = isAmharic && maintenance.messageAm.isNotEmpty
        ? maintenance.messageAm
        : maintenance.messageEn.isNotEmpty
            ? maintenance.messageEn
            : null;

    final displayMsg = customMsg ?? l10n.maintenanceBanner;

    return Container(
      width: double.infinity,
      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.build_circle_outlined,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayMsg,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB45309), // Warm amber dark
              ),
            ),
          ),
        ],
      ),
    );
  }
}
