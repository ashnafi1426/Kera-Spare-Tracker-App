import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

class ActionSheetItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Mobile contextual action bottom sheet.
class ActionSheet extends StatelessWidget {
  final String? title;
  final List<ActionSheetItem> items;

  const ActionSheet({
    super.key,
    this.title,
    required this.items,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<ActionSheetItem> items,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ActionSheet(
        title: title,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...items.map((item) {
              final color = item.isDestructive
                  ? KeraColors.orange700
                  : context.textPrimaryColor;
              return ListTile(
                leading: Icon(item.icon, color: color, size: 22),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  item.onTap();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

