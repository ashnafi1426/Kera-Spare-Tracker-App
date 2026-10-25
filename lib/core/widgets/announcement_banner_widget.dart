import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_config_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Dismissible announcement banner shown at the top of the inventory catalog.
class AnnouncementBannerWidget extends ConsumerWidget {
  const AnnouncementBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configStateAsync = ref.watch(appConfigNotifierProvider);
    final configState = configStateAsync.value;

    if (configState == null || !configState.shouldShowAnnouncement) {
      return const SizedBox.shrink();
    }

    final announcement = configState.config.announcement;
    final locale = ref.watch(localeControllerProvider);
    final isAmharic = locale.languageCode == 'am';

    final title = isAmharic && announcement.titleAm.isNotEmpty
        ? announcement.titleAm
        : announcement.titleEn.isNotEmpty
            ? announcement.titleEn
            : announcement.titleAm;

    final body = isAmharic && announcement.bodyAm.isNotEmpty
        ? announcement.bodyAm
        : announcement.bodyEn.isNotEmpty
            ? announcement.bodyEn
            : announcement.bodyAm;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.campaign_rounded,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                if (title.isNotEmpty && body.isNotEmpty)
                  const SizedBox(height: 2),
                if (body.isNotEmpty)
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            onPressed: () {
              ref.read(appConfigNotifierProvider.notifier).dismissAnnouncement();
            },
          ),
        ],
      ),
    );
  }
}
