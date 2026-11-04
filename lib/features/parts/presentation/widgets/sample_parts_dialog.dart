import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../providers/inventory_providers.dart';

/// Modal dialog allowing the owner to generate 10, 25, or 50 realistic demo parts,
/// or delete all previously generated demo parts.
class SamplePartsDialog extends ConsumerStatefulWidget {
  const SamplePartsDialog({super.key});

  static Future<void> show(BuildContext context) {
    if (!AppConstants.enableDemoGenerator) return Future.value();
    return showDialog<void>(
      context: context,
      builder: (_) => const SamplePartsDialog(),
    );
  }

  @override
  ConsumerState<SamplePartsDialog> createState() => _SamplePartsDialogState();
}

class _SamplePartsDialogState extends ConsumerState<SamplePartsDialog> {
  int _selectedCount = 25;
  bool _isLoading = false;

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(inventoryListProvider.notifier);
    final success = await notifier.seedTestParts(count: _selectedCount);
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

    if (success) {
      context.showSnackBar(
        context.tr(
          '$_selectedCount የሙከራ ዕቃዎች በተሳካ ሁኔታ ተፈጥረዋል',
          'Successfully generated $_selectedCount sample parts',
        ),
      );
    } else {
      context.showSnackBar(
        context.tr('የሙከራ ዕቃዎችን ማመንጨት አልተቻለም', 'Failed to generate sample parts'),
        isError: true,
      );
    }
  }

  Future<void> _deleteDemoParts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('የሙከራ መረጃዎችን ሰርዝ?', 'Delete All Sample Data?')),
        content: Text(
          context.tr(
            'የተፈጠሩትን የሙከራ ዕቃዎች በሙሉ መሰረዝ ይፈልጋሉ? ትክክለኛ ዕቃዎችህ አይነኩም።',
            'Are you sure you want to delete all demo parts? Your real inventory will not be affected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('ተመለስ', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.statusError,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('ሁሉንም ሰርዝ', 'Delete All')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final notifier = ref.read(inventoryListProvider.notifier);
    final success = await notifier.clearTestParts();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

    if (success) {
      context.showSnackBar(
        context.tr(
          'የሙከራ ዕቃዎች በሙሉ በተሳካ ሁኔታ ተሰርዘዋል',
          'All sample demo parts deleted successfully',
        ),
      );
    } else {
      context.showSnackBar(
        context.tr('ዕቃዎችን መሰረዝ አልተቻለም', 'Failed to delete demo parts'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KeraColors.brandOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: KeraColors.brandOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('የሙከራ ዕቃዎች ማመንጫ', 'Generate Sample Parts'),
              style: KeraTypography.titleMedium().copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 140,
              child: Center(child: KeraLoadingIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'ለሱቅህ ተጨባጭ የሆኑ የከባድ መኪና መለዋወጫዎችን (CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY) በሁለት ቋንቋ ስም፣ መደብ እና ዋጋ በራስ-ሰር ይፈጥራል።',
                    'Generates realistic heavy equipment spare parts (CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY) with bilingual names, stock levels, and shelf locations.',
                  ),
                  style: KeraTypography.bodySmall().copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('የዕቃዎች ብዛት ይምረጡ:', 'Select number of parts:'),
                  style: KeraTypography.labelMedium().copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [10, 25, 50].map((count) {
                    final isSelected = _selectedCount == count;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? Colors.white : context.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: KeraColors.primaryNavy,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCount = count);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Divider(color: context.borderColor),
                const SizedBox(height: 8),
                // Delete existing demo parts option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteDemoParts,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: KeraColors.statusError),
                    label: Text(
                      context.tr('የሙከራ ዕቃዎችን ሰርዝ', 'Delete All Sample Data'),
                      style: const TextStyle(color: KeraColors.statusError, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KeraColors.statusError),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        if (!_isLoading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('ተመለስ', 'Cancel')),
          ),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: Text(context.tr('አመንጭ ($_selectedCount)', 'Generate ($_selectedCount)')),
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.brandOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
