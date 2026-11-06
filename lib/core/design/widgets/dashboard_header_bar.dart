import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/kera_image_widget.dart';
import '../../widgets/kera_logo_widget.dart';
import '../tokens/kera_colors.dart';
import 'owner_header_bar.dart';

/// Fixed, rock-solid shared header component for both Owner and Admin Dashboards.
///
/// Fixes Issue 4:
/// - Fixed, predictable layout that does NOT jump or shift on content load,
///   keyboard appearance, language switch, or theme switch.
/// - Safe area padding is handled once at the top.
/// - Contains logo with light background plate in dark mode, title, subtitle,
///   sync/notification button, theme toggle, language toggle, and search capsule.
class DashboardHeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String searchHint;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final Widget? trailingAction;
  final bool showSearch;

  const DashboardHeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    this.onSearchTap,
    this.onSearchChanged,
    this.searchController,
    this.trailingAction,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final headerBg = isDark ? const Color(0xFF071322) : KeraColors.primaryNavy;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: headerBg,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Titles + Controls + Trailing Action
          SizedBox(
            height: 42,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User profile photo or logo with plate
                Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(authControllerProvider).value;
                    final photo = user?.avatarUrl;
                    if (photo != null && photo.isNotEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: KeraColors.keraOrange, width: 1.5),
                        ),
                        child: KeraAvatarWidget(
                          photoUrl: photo,
                          name: user?.businessName ?? 'User',
                          radius: 19,
                          isDark: context.isDark,
                        ),
                      );
                    }
                    return const KeraLogoWidget(
                      size: 38,
                      borderRadius: 10,
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Title and Subtitle with fixed typography metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFA5B4CB),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Theme Mode Switcher
                const OwnerThemeToggle(),
                const SizedBox(width: 6),

                // Language Switcher (EN / AM)
                const OwnerLanguageToggle(),

                // Custom Trailing Action (e.g. Notification Bell, Sync Pill)
                if (trailingAction != null) ...[
                  const SizedBox(width: 6),
                  trailingAction!,
                ],
              ],
            ),
          ),

          if (showSearch) ...[
            const SizedBox(height: 12),
            // Fixed-height Search Capsule (never shifts layout)
            SizedBox(
              height: 44,
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF102138) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E385C) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: onSearchTap != null && searchController == null
                            ? Text(
                                searchHint,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : TextField(
                                controller: searchController,
                                onChanged: onSearchChanged,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0B2A5B),
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: searchHint,
                                  hintStyle: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: KeraColors.keraOrange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

