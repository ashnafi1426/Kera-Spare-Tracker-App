import 'package:flutter/material.dart';
import '../../tokens/admin_colors.dart';

/// Reusable deep navy header for Kera Spare Tracker Owner App screens.
/// Matches 1 Dashboard.png, 2 Inventory.png, 3 Add spare part.png,
/// 4 Record sale.png, and 5 Sales history.png.
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
    this.subtitle = 'ከራ · Kera Spare Tracker',
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomContent,
    this.bottomPadding = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
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
                          businessName.isNotEmpty ? businessName : 'ተስፋዬ እና ልጆቹ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
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
                  if (actions != null) ...actions!,
                ],
              ),

              // Title Widget below top row (e.g. "ዕቃዎች", "ሽያጭ", Back button line)
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

/// Search input capsule matching the Owner App header in mockups.
class OwnerSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final bool readOnly;
  final Widget? trailing;

  const OwnerSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.hintText = 'ዕቃ በስም ወይም በቁጥር ይፈልጉ',
    this.readOnly = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
