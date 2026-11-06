import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Modal bottom sheet for filtering inventory or sales.
class FilterSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onApply;
  final VoidCallback? onReset;

  const FilterSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onApply,
    this.onReset,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selectedOption,
  }) {
    String? current = selectedOption;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isSelected = opt == current;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            current = val ? opt : null;
                          });
                        },
                        selectedColor: KeraColors.orange100,
                        backgroundColor: context.scaffoldBg,
                        labelStyle: TextStyle(
                          color: isSelected ? KeraColors.orange700 : context.textSecondaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? KeraColors.orange500 : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: context.l10n.cancel,
                          onPressed: () => Navigator.pop(ctx, null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: context.l10n.confirm,
                          onPressed: () => Navigator.pop(ctx, current),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

