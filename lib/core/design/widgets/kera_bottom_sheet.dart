import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';

/// Modal bottom sheet container adhering to Stitch Level 3 specifications.
/// Includes drag handle, 16px top radius, and safe-area inset preservation.
class KeraBottomSheet extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  const KeraBottomSheet({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.footer,
    this.showHandle = true,
    this.padding = KeraSpacing.sheetPadding,
  });

  /// Displays the bottom sheet with standard modal configuration.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    Widget? footer,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KeraBottomSheet(
        title: title,
        trailing: trailing,
        footer: footer,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KeraColors.surfacePure,
        borderRadius: KeraRadii.borderSheet,
        boxShadow: [KeraColors.shadowLevel3],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drag Handle
            if (showHandle)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: KeraColors.outlineBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // 2. Header (Optional)
            if (title != null || trailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: KeraTypography.headlineSmall(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ?trailing,
                  ],
                ),
              ),

            if (title != null || trailing != null)
              const Divider(height: 1, color: KeraColors.outlineBorder),

            // 3. Body Content
            Flexible(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),

            // 4. Pinned Action Footer (Optional)
            if (footer != null) ...[
              const Divider(height: 1, color: KeraColors.outlineBorder),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

