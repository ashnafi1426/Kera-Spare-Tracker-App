import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/context_extensions.dart';
import '../tokens/admin_colors.dart';

/// Reusable deep navy header for Kera Spare Tracker Owner App screens.
/// Supports dark mode, dynamic localization, and quick language/theme controls.
class OwnerHeaderBar extends StatelessWidget {
  final String businessName;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomContent;
  final double bottomPadding;

  const OwnerHeaderBar({
    super.key,
    required this.businessName,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomContent,
    this.bottomPadding = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final headerBg = isDark ? const Color(0xFF071322) : AdminColors.headerNavy;
    const defaultSubtitle = 'Kera · Spare Tracker';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerBg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Logo + Business Name + Subtitle (or Back button)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.settings_suggest_rounded,
                          color: AdminColors.headerNavy,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          businessName.isNotEmpty
                              ? businessName
                              : 'Kera Spare Parts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle ?? defaultSubtitle,
                          style: const TextStyle(
                            color: AdminColors.headerTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const OwnerThemeToggle(),
                  const SizedBox(width: 8),
                  const OwnerLanguageToggle(),
                  ...?actions,
                ],
              ),

              // Title Widget below top row (e.g. title, search, or back button line)
              if (titleWidget != null) ...[
                const SizedBox(height: 14),
                titleWidget!,
              ],

              // Bottom Extension (e.g. Search capsule, tabs)
              if (bottomContent != null) ...[
                const SizedBox(height: 14),
                bottomContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick inline language toggle for headers.
class OwnerLanguageToggle extends ConsumerWidget {
  const OwnerLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAmharic = context.isAmharic;
    return InkWell(
      onTap: () {
        ref.read(localeControllerProvider.notifier).setLocale(
              Locale(isAmharic ? 'en' : 'am'),
            );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              isAmharic ? 'EN' : 'AM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick inline theme toggle (Dark / Light) for headers.
class OwnerThemeToggle extends ConsumerWidget {
  const OwnerThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: Colors.white,
        size: 18,
      ),
      tooltip: isDark ? 'Light Theme' : 'Dark Theme',
      onPressed: () {
        ref.read(themeModeControllerProvider.notifier).setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            );
      },
    );
  }
}

/// Reusable search capsule designed for deep navy header contexts.
class OwnerSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final bool readOnly;
  final Widget? trailing;
  final FocusNode? focusNode;

  const OwnerSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.hintText = 'Search...',
    this.readOnly = false,
    this.trailing,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ?trailing,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
