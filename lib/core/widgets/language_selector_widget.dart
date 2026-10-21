import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/constants.dart';
import '../providers/locale_provider.dart';
import '../utils/context_extensions.dart';

/// Reusable segmented language switch widget for headers, appbars, or settings screens.
class LanguageSegmentedSwitch extends ConsumerWidget {
  const LanguageSegmentedSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeControllerProvider);
    final colorScheme = context.colorScheme;
    final isAmharic = currentLocale.languageCode == AppConstants.defaultLocaleCode;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageOptionButton(
            label: 'አማርኛ',
            isSelected: isAmharic,
            onTap: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(const Locale(AppConstants.defaultLocaleCode));
            },
          ),
          _LanguageOptionButton(
            label: 'English',
            isSelected: !isAmharic,
            onTap: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(const Locale(AppConstants.englishLocaleCode));
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable settings tile for language selection.
class LanguageSettingTile extends ConsumerWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeControllerProvider);
    final l10n = context.l10n;
    final isAmharic = currentLocale.languageCode == AppConstants.defaultLocaleCode;

    return ListTile(
      leading: const Icon(Icons.language_rounded, size: 28),
      title: Text(
        l10n.language,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(isAmharic ? l10n.amharic : l10n.english),
      trailing: const LanguageSegmentedSwitch(),
    );
  }
}
