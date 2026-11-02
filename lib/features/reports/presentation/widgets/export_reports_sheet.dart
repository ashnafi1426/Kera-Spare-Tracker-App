import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';

/// Modal bottom sheet for filtering and exporting reports.
///
/// Follows Google Stitch Screen 6 (Filters & Export Reports — ማጣሪያ እና ሪፖርት ማውጫ).
class ExportReportsSheet extends StatefulWidget {
  const ExportReportsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportReportsSheet(),
    );
  }

  @override
  State<ExportReportsSheet> createState() => _ExportReportsSheetState();
}

class _ExportReportsSheetState extends State<ExportReportsSheet> {
  int _selectedReportType = 0; // 0: Sales, 1: P&L, 2: Inventory, 3: Best Sellers
  int _selectedDateRange = 3; // 0: Today, 1: Yesterday, 2: Week, 3: Month, 4: Past 30
  int _selectedFormat = 0; // 0: PDF, 1: Excel, 2: CSV
  bool _isGenerating = false;

  void _reset() {
    setState(() {
      _selectedReportType = 0;
      _selectedDateRange = 3;
      _selectedFormat = 0;
    });
  }

  Future<void> _handleExport() async {
    setState(() => _isGenerating = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isGenerating = false);
    Navigator.pop(context);

    final formatName = ['PDF', 'Excel (.xlsx)', 'CSV'][_selectedFormat];
    final typeName = [
      'የሽያጭ ማጠቃለያ (Sales)',
      'የትርፍ እና ኪሳራ (P&L)',
      'የክምችት ግምት (Inventory)',
      'ከፍተኛ ተፈላጊ (Best Sellers)'
    ][_selectedReportType];

    context.showSnackBar(
      '$typeName $formatName ሪፖርት በተሳካ ሁኔታ ተዘጋጅቷል / Export Generated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KeraColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list_rounded,
                              size: 20, color: KeraColors.primaryNavy),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ማጣሪያ እና ሪፖርት ማውጫ',
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Kera Hub • Custom Data Filters & Downloads',
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'ዳግም አስጀምር',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.actionBlue,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable options
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Report Type
                _buildSectionHeader('1. የሪፖርት ዓይነት / Report Type'),
                const SizedBox(height: 8),
                _buildTypeTile(
                  index: 0,
                  icon: Icons.point_of_sale_rounded,
                  title: 'የሽያጭ ማጠቃለያ (Sales Summary)',
                  subtitle: 'Daily & monthly revenue and cashier ledger',
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 1,
                  icon: Icons.trending_up_rounded,
                  title: 'የትርፍ እና ኪሳራ መግለጫ (Profit & Loss P&L)',
                  subtitle: 'Revenue, COGS, gross margins, and net profits',
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 2,
                  icon: Icons.warehouse_rounded,
                  title: 'የክምችት ግምት እና ጤንነት (Inventory Valuation)',
                  subtitle: 'Total stock capital, healthy SKUs, and reorder alerts',
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 3,
                  icon: Icons.leaderboard_rounded,
                  title: 'ከፍተኛ ተፈላጊ ዕቃዎች (Best-Selling Products)',
                  subtitle: 'Top 10 moving spare parts and category breakdown',
                ),

                const SizedBox(height: 18),

                // 2. Date Range
                _buildSectionHeader('2. የቀን ክልል / Date Range'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRangeChip(0, 'ዛሬ (Today)'),
                    _buildRangeChip(1, 'ትናንት (Yesterday)'),
                    _buildRangeChip(2, 'በዚህ ሳምንት (Week)'),
                    _buildRangeChip(3, 'በዚህ ወር (This Month)'),
                    _buildRangeChip(4, 'ባለፉት 30 ቀናት (Past 30)'),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. Export File Format
                _buildSectionHeader('3. የፋይል ቅርጸት / Export Format'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormatCard(
                        index: 0,
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'PDF Report',
                        desc: 'Print & Share ready',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFormatCard(
                        index: 1,
                        icon: Icons.table_chart_rounded,
                        title: 'Excel (.xlsx)',
                        desc: 'Ledger spreadsheets',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFormatCard(
                        index: 2,
                        icon: Icons.insert_drive_file_outlined,
                        title: 'CSV Data',
                        desc: 'Raw SQLite tables',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. Destination Shortcuts
                _buildSectionHeader('4. ቀጥታ መላኪያ / Destination Shortcuts'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDestButton(Icons.save_alt_rounded, 'በስልክ አስቀምጥ\nDownloads'),
                      _buildDestButton(Icons.near_me_rounded, 'ቴሌግራም\nTelegram'),
                      _buildDestButton(Icons.chat_bubble_outline_rounded, 'ዋትስአፕ\nWhatsApp'),
                      _buildDestButton(Icons.print_rounded, 'ደረሰኝ አትም\nPOS Print'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom CTA Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: const Border(
                top: BorderSide(color: KeraColors.outlineBorder),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _handleExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KeraColors.primaryNavyDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isGenerating
                      ? 'ሪፖርት በመዘጋጀት ላይ...'
                      : 'ሪፖርት አውርድ / Generate Report',
                  style: KeraTypography.labelLarge(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: KeraTypography.labelMedium(color: KeraColors.primaryNavy)
          .copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTypeTile({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedReportType == index;
    return InkWell(
      onTap: () => setState(() => _selectedReportType = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? KeraColors.actionBlue.withValues(alpha: 0.08)
              : KeraColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? KeraColors.actionBlue : KeraColors.outlineBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? KeraColors.actionBlue : KeraColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KeraTypography.labelMedium().copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? KeraColors.actionBlue : KeraColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: KeraTypography.bodySmall(color: KeraColors.textSecondary)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: KeraColors.actionBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(int index, String label) {
    final isSelected = _selectedDateRange == index;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: KeraTypography.labelSmall(
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      selectedColor: KeraColors.actionBlue,
      backgroundColor: KeraColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? KeraColors.actionBlue : KeraColors.outlineBorder,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedDateRange = index);
      },
    );
  }

  Widget _buildFormatCard({
    required int index,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isSelected = _selectedFormat == index;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KeraColors.actionBlue.withValues(alpha: 0.08)
              : KeraColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? KeraColors.actionBlue : KeraColors.outlineBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? KeraColors.actionBlue : KeraColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: KeraTypography.labelSmall().copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? KeraColors.actionBlue : KeraColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              desc,
              style: KeraTypography.labelSmall(color: KeraColors.textSecondary)
                  .copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        context.showSnackBar('$label shortcut ready');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: KeraColors.actionBlue),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KeraTypography.labelSmall(color: KeraColors.textSecondary)
                  .copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

