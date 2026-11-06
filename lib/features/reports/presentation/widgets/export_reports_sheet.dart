import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/database_provider.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';

/// Modal bottom sheet for filtering and exporting reports.
///
/// Follows Google Stitch Screen 6 (Filters & Export Reports — ማጣሪያ እና ሪፖርት ማውጫ).
class ExportReportsSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ExportReportsSheet> createState() => _ExportReportsSheetState();
}

class _ExportReportsSheetState extends ConsumerState<ExportReportsSheet> {
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

  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    switch (_selectedDateRange) {
      case 0: // Today
        return (
          DateTime(now.year, now.month, now.day, 0, 0, 0),
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case 1: // Yesterday
        final y = now.subtract(const Duration(days: 1));
        return (
          DateTime(y.year, y.month, y.day, 0, 0, 0),
          DateTime(y.year, y.month, y.day, 23, 59, 59, 999),
        );
      case 2: // Week
        final offset = now.weekday - 1;
        final mon = now.subtract(Duration(days: offset));
        return (
          DateTime(mon.year, mon.month, mon.day, 0, 0, 0),
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case 3: // Month
        return (
          DateTime(now.year, now.month, 1, 0, 0, 0),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case 4: // Past 30
      default:
        return (
          now.subtract(const Duration(days: 30)),
          now,
        );
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isGenerating = true);
    try {
      final ownerId = ref.read(currentOwnerIdProvider);
      final db = ref.read(appDatabaseProvider);
      final (start, end) = _resolveDateRange();
      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final typeName = [
        'sales_summary',
        'profit_loss',
        'inventory_valuation',
        'best_sellers',
      ][_selectedReportType];

      final isHtml = _selectedFormat == 0;
      final ext = isHtml ? 'html' : (_selectedFormat == 1 ? 'csv' : 'csv');
      final fileName = 'kera_${typeName}_$timeStamp.$ext';
      final file = File('${tempDir.path}/$fileName');

      String content = '';

      if (_selectedReportType == 0) {
        // Sales Summary
        final sales = await db.salesDao.getSalesByDateRange(
          ownerId: ownerId,
          startDate: start,
          endDate: end,
        );
        if (isHtml) {
          content = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Kera Spare Tracker - Sales Summary</title>
<style>
body { font-family: sans-serif; margin: 20px; color: #0B2A5B; }
h1 { color: #0B2A5B; border-bottom: 2px solid #F7931E; padding-bottom: 8px; }
table { width: 100%; border-collapse: collapse; margin-top: 16px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #0B2A5B; color: white; }
tr:nth-child(even) { background-color: #f9f9f9; }
</style>
</head>
<body>
<h1>Kera Spare Tracker - Sales Summary</h1>
<p>Period: ${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}</p>
<p>Total Records: ${sales.length}</p>
<table>
<tr><th>Sale ID</th><th>Date</th><th>Amount (ETB)</th><th>Profit (ETB)</th><th>Payment Method</th></tr>
${sales.map((s) => '<tr><td>${s.id.length > 8 ? s.id.substring(0, 8) : s.id}</td><td>${DateFormat.yMd().add_jm().format(s.soldAt)}</td><td>${s.totalAmount}</td><td>${s.totalProfit}</td><td>${s.paymentMethod ?? "CASH"}</td></tr>').join('\n')}
</table>
</body>
</html>''';
        } else {
          content = '\uFEFFSale ID,Date,Amount (ETB),Profit (ETB),Payment Method\n';
          for (final s in sales) {
            content += '"${s.id}","${DateFormat.yMd().add_jm().format(s.soldAt)}",${s.totalAmount},${s.totalProfit},"${s.paymentMethod ?? "CASH"}"\n';
          }
        }
      } else if (_selectedReportType == 1) {
        // Profit & Loss
        final summary = await db.salesDao.getSalesSummary(
          ownerId: ownerId,
          startDate: start,
          endDate: end,
        );
        final totalCost = (summary.totalRevenue - summary.totalProfit).clamp(0.0, double.infinity);
        final margin = summary.totalRevenue > 0
            ? ((summary.totalProfit / summary.totalRevenue) * 100).toStringAsFixed(1)
            : '0.0';

        if (isHtml) {
          content = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Kera Spare Tracker - Profit & Loss</title>
<style>
body { font-family: sans-serif; margin: 20px; color: #0B2A5B; }
h1 { color: #0B2A5B; border-bottom: 2px solid #F7931E; padding-bottom: 8px; }
table { width: 60%; border-collapse: collapse; margin-top: 16px; }
th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
th { background-color: #0B2A5B; color: white; }
</style>
</head>
<body>
<h1>Kera Spare Tracker - Profit &amp; Loss Statement</h1>
<p>Period: ${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}</p>
<table>
<tr><th>Metric</th><th>Amount (ETB)</th></tr>
<tr><td>Total Revenue</td><td>${summary.totalRevenue}</td></tr>
<tr><td>Total Cost (COGS)</td><td>$totalCost</td></tr>
<tr><td><b>Gross Profit</b></td><td><b>${summary.totalProfit}</b></td></tr>
<tr><td>Profit Margin</td><td>$margin%</td></tr>
<tr><td>Transaction Count</td><td>${summary.salesCount}</td></tr>
</table>
</body>
</html>''';
        } else {
          content = '\uFEFFMetric,Value\n'
              'Total Revenue,${summary.totalRevenue}\n'
              'Total Cost,$totalCost\n'
              'Gross Profit,${summary.totalProfit}\n'
              'Profit Margin,$margin%\n'
              'Transaction Count,${summary.salesCount}\n';
        }
      } else if (_selectedReportType == 2) {
        // Inventory Valuation
        final parts = await db.partsDao.getActiveParts(ownerId);
        if (isHtml) {
          content = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Kera Spare Tracker - Inventory Valuation</title>
<style>
body { font-family: sans-serif; margin: 20px; color: #0B2A5B; }
h1 { color: #0B2A5B; border-bottom: 2px solid #F7931E; padding-bottom: 8px; }
table { width: 100%; border-collapse: collapse; margin-top: 16px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #0B2A5B; color: white; }
tr:nth-child(even) { background-color: #f9f9f9; }
</style>
</head>
<body>
<h1>Kera Spare Tracker - Inventory Valuation</h1>
<p>Total Items: ${parts.length}</p>
<table>
<tr><th>Part Name</th><th>Part Number</th><th>Quantity</th><th>Unit Buy</th><th>Unit Sell</th><th>Total Stock Value</th></tr>
${parts.map((p) => '<tr><td>${p.name ?? ""}</td><td>${p.partNumber ?? "-"}</td><td>${p.cachedQuantity ?? 0}</td><td>${p.purchasePrice ?? 0}</td><td>${p.sellingPrice ?? 0}</td><td>${(p.cachedQuantity ?? 0) * (p.purchasePrice ?? 0)}</td></tr>').join('\n')}
</table>
</body>
</html>''';
        } else {
          content = '\uFEFFPart Name,Part Number,Quantity,Unit Cost,Unit Sell,Total Value\n';
          for (final p in parts) {
            content += '"${p.name ?? ""}","${p.partNumber ?? "-"}",${p.cachedQuantity ?? 0},${p.purchasePrice ?? 0},${p.sellingPrice ?? 0},${(p.cachedQuantity ?? 0) * (p.purchasePrice ?? 0)}\n';
          }
        }
      } else {
        // Best Sellers
        final topParts = await db.salesDao.getTopSellingParts(
          ownerId: ownerId,
          startDate: start,
          endDate: end,
          limit: 25,
        );
        if (isHtml) {
          content = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Kera Spare Tracker - Best Sellers</title>
<style>
body { font-family: sans-serif; margin: 20px; color: #0B2A5B; }
h1 { color: #0B2A5B; border-bottom: 2px solid #F7931E; padding-bottom: 8px; }
table { width: 100%; border-collapse: collapse; margin-top: 16px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #0B2A5B; color: white; }
tr:nth-child(even) { background-color: #f9f9f9; }
</style>
</head>
<body>
<h1>Kera Spare Tracker - Best Selling Parts</h1>
<p>Period: ${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}</p>
<table>
<tr><th>Rank</th><th>Part Name</th><th>Units Sold</th><th>Total Revenue (ETB)</th></tr>
${topParts.asMap().entries.map((e) => '<tr><td>#${e.key + 1}</td><td>${e.value.partName}</td><td>${e.value.quantitySold}</td><td>${e.value.totalRevenue}</td></tr>').join('\n')}
</table>
</body>
</html>''';
        } else {
          content = '\uFEFFRank,Part Name,Units Sold,Total Revenue\n';
          for (var i = 0; i < topParts.length; i++) {
            final t = topParts[i];
            content += '#${i + 1},"${t.partName}",${t.quantitySold},${t.totalRevenue}\n';
          }
        }
      }

      await file.writeAsString(content);

      if (!mounted) return;
      setState(() => _isGenerating = false);
      Navigator.pop(context);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Kera Spare Tracker - Report Export',
          text: 'Kera Spare Tracker - Report Export ($fileName)',
        ),
      );

      if (mounted) {
        context.showSnackBar(
          context.tr('ሪፖርቱ በተሳካ ሁኔታ ተዘጋጅቷል', 'Report generated and exported successfully'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        context.showSnackBar(
          context.tr('ሪፖርቱን ማዘጋጀት አልተቻለም', 'Failed to generate report: $e'),
          isError: true,
        );
      }
    }
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
                              context.tr('ማጣሪያ እና ሪፖርት ማውጫ', 'Filters & Export Reports'),
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        context.tr(
                          'ብጁ ማጣሪያዎች እና ማውረጃዎች',
                          'Custom Data Filters & Downloads',
                        ),
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
                    context.tr('ዳግም አስጀምር', 'Reset'),
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
                _buildSectionHeader(context.tr('1. የሪፖርት ዓይነት', '1. Report Type')),
                const SizedBox(height: 8),
                _buildTypeTile(
                  index: 0,
                  icon: Icons.point_of_sale_rounded,
                  title: context.tr('የሽያጭ ማጠቃለያ', 'Sales Summary'),
                  subtitle: context.tr(
                    'የዕለት እና የወር ገቢ እንዲሁም የገንዘብ ተቀባይ መዝገብ',
                    'Daily & monthly revenue and cashier ledger',
                  ),
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 1,
                  icon: Icons.trending_up_rounded,
                  title: context.tr('የትርፍ እና ኪሳራ መግለጫ', 'Profit & Loss (P&L)'),
                  subtitle: context.tr(
                    'ጠቅላላ ገቢ፣ የወጣባቸው ዋጋ እና የተጣራ ትርፍ',
                    'Revenue, COGS, gross margins, and net profits',
                  ),
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 2,
                  icon: Icons.warehouse_rounded,
                  title: context.tr('የክምችት ግምት እና ጤንነት', 'Inventory Valuation'),
                  subtitle: context.tr(
                    'ጠቅላላ የክምችት ካፒታል እና አስቸኳይ ትእዛዝ ጥሪዎች',
                    'Total stock capital, healthy SKUs, and reorder alerts',
                  ),
                ),
                const SizedBox(height: 6),
                _buildTypeTile(
                  index: 3,
                  icon: Icons.leaderboard_rounded,
                  title: context.tr('ከፍተኛ ተፈላጊ ዕቃዎች', 'Best-Selling Products'),
                  subtitle: context.tr(
                    'በሽያጭ ቀዳሚ የሆኑ 10 ዕቃዎች ዝርዝር',
                    'Top 10 moving spare parts and category breakdown',
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Date Range
                _buildSectionHeader(context.tr('2. የቀን ክልል', '2. Date Range')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRangeChip(0, context.tr('ዛሬ', 'Today')),
                    _buildRangeChip(1, context.tr('ትናንት', 'Yesterday')),
                    _buildRangeChip(2, context.tr('በዚህ ሳምንት', 'This Week')),
                    _buildRangeChip(3, context.tr('በዚህ ወር', 'This Month')),
                    _buildRangeChip(4, context.tr('ባለፉት 30 ቀናት', 'Past 30 Days')),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. Export File Format
                _buildSectionHeader(context.tr('3. የፋይል ቅርጸት', '3. Export Format')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormatCard(
                        index: 0,
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'PDF Report',
                        desc: context.tr('ለህትመት ዝግጁ', 'Print & Share'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFormatCard(
                        index: 1,
                        icon: Icons.table_chart_rounded,
                        title: 'Excel (.xlsx)',
                        desc: context.tr('የስሌት ሰንጠረዥ', 'Spreadsheets'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFormatCard(
                        index: 2,
                        icon: Icons.insert_drive_file_outlined,
                        title: 'CSV Data',
                        desc: context.tr('ጥሬ ውሂብ', 'Raw SQLite tables'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. Destination Shortcuts
                _buildSectionHeader(context.tr('4. ፈጣን መላኪያ', '4. Direct Shortcuts')),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardCanvasColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDestButton(
                        Icons.save_alt_rounded,
                        context.tr('በስልክ አስቀምጥ', 'Downloads'),
                      ),
                      _buildDestButton(
                        Icons.near_me_rounded,
                        context.tr('ቴሌግራም', 'Telegram'),
                      ),
                      _buildDestButton(
                        Icons.chat_bubble_outline_rounded,
                        context.tr('ዋትስአፕ', 'WhatsApp'),
                      ),
                      _buildDestButton(
                        Icons.print_rounded,
                        context.tr('ደረሰኝ አትም', 'POS Print'),
                      ),
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
                  backgroundColor: KeraColors.brandOrange,
                  foregroundColor: KeraColors.navy900,
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
                          color: KeraColors.navy900,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isGenerating
                      ? context.tr('ሪፖርት በመዘጋጀት ላይ...', 'Generating Report...')
                      : context.tr('ሪፖርት አውርድ', 'Generate Report'),
                  style: KeraTypography.labelLarge(color: KeraColors.navy900)
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
              : context.cardCanvasColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? KeraColors.actionBlue : context.borderColor,
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
        color: isSelected ? Colors.white : context.textPrimaryColor,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      selectedColor: KeraColors.actionBlue,
      backgroundColor: context.cardCanvasColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? KeraColors.actionBlue : context.borderColor,
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
              : context.cardCanvasColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? KeraColors.actionBlue : context.borderColor,
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
