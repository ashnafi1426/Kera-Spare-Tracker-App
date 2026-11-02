import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/sync_conflict_model.dart';
import '../providers/sync_providers.dart';

/// Screen for resolving discrepancies between local offline changes and remote server updates.
///
/// Follows Google Stitch Screen 2 (Conflict Resolution — የዳታ ግጭት መፍቻ).
class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  ConflictResolutionStrategy _selectedStrategy =
      ConflictResolutionStrategy.smartMerge;
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final conflicts = ref.watch(activeConflictsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavyDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'የዳታ ግጭት መፍቻ',
              style: KeraTypography.titleMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Conflict Resolution & Ledger Reconciliation',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
      body: conflicts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: KeraColors.stockInBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: KeraColors.stockInText,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ምንም የዳታ ግጭት የለም',
                      style: KeraTypography.titleMedium()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ሁሉም ከመስመር ውጭ እና ሰርቨር መረጃዎች በሰላም ተመሳክረዋል',
                      textAlign: TextAlign.center,
                      style: KeraTypography.bodyMedium(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                // 1. Advisory Alert Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KeraColors.warningAmberBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KeraColors.warningAmberBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sync_problem_rounded,
                          color: KeraColors.warningAmber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ማስጠንቀቂያ / Conflict Advisory',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.warningAmber,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ይህ ዕቃ በስልክዎ ከመስመር ውጭ ሲስተካከል በሰርቨሩ ላይም ሌላ ለውጥ ተደርጓል። እባክዎ የትኛው መረጃ እንደሚቀጥል ይምረጡ።',
                              style: KeraTypography.bodySmall(
                                color: Colors.brown.shade800,
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Active Conflict Card
                ...conflicts.map((conflict) => _buildConflictCard(context, conflict)),
              ],
            ),
    );
  }

  Widget _buildConflictCard(BuildContext context, SyncConflictModel conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: KeraColors.surfacePure,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KeraColors.outlineBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part Hero Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: KeraColors.surfaceCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: KeraColors.outlineBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KeraColors.primaryNavyDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.oil_barrel_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.partName,
                        style: KeraTypography.titleSmall()
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'OEM: ${conflict.oemNumber} • ${conflict.shelfLocation}',
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KeraColors.warningAmberBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: KeraColors.warningAmberBorder),
                  ),
                  child: Text(
                    '2 Diffs',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.warningAmber,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Comparison Matrix Header
                Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded,
                        size: 18, color: KeraColors.actionBlue),
                    const SizedBox(width: 6),
                    Text(
                      'የንጽጽር ዝርዝር / Comparison Matrix',
                      style: KeraTypography.labelMedium()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Discrepancy 1: Selling Price
                _buildDiffRow(
                  title: 'የመሸጫ ዋጋ / Selling Price',
                  diffLabel:
                      '${conflict.priceDiff > 0 ? "+" : ""}${conflict.priceDiff.toStringAsFixed(0)} ETB Diff',
                  localVal: CurrencyFormatter.formatEtb(conflict.localPrice),
                  localSub: conflict.localUpdatedBy,
                  serverVal: CurrencyFormatter.formatEtb(conflict.serverPrice),
                  serverSub: conflict.serverUpdatedBy,
                ),

                const SizedBox(height: 14),

                // Discrepancy 2: Stock Quantity
                _buildDiffRow(
                  title: 'የክምችት መጠን / Stock Quantity',
                  diffLabel:
                      '${conflict.stockDiff > 0 ? "+" : ""}${conflict.stockDiff.toStringAsFixed(0)} pcs Diff',
                  localVal: '${conflict.localStock.toStringAsFixed(0)} pcs',
                  localSub: 'Local POS deduction',
                  serverVal: '${conflict.serverStock.toStringAsFixed(0)} pcs',
                  serverSub: 'Before offline sync',
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // 3. Resolution Strategy Options
                Text(
                  'የመፍትሔ ውሳኔ / Resolution Decision',
                  style: KeraTypography.labelMedium()
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Option 1: Smart Merge
                _buildStrategyTile(
                  strategy: ConflictResolutionStrategy.smartMerge,
                  title: 'ብልህ ውህደት (Smart Merge) — ይመከራል',
                  desc:
                      'Keep server price (${CurrencyFormatter.formatEtb(conflict.serverPrice)}) and apply local stock deduction (${conflict.localStock.toStringAsFixed(0)} pcs).',
                  isRecommended: true,
                ),
                const SizedBox(height: 8),

                // Option 2: Keep Local
                _buildStrategyTile(
                  strategy: ConflictResolutionStrategy.clientWins,
                  title: 'የስልኩን ዳታ አስቀር (Keep Local / Client Wins)',
                  desc:
                      'Force overwrite cloud with local phone values (${CurrencyFormatter.formatEtb(conflict.localPrice)} & ${conflict.localStock.toStringAsFixed(0)} pcs).',
                ),
                const SizedBox(height: 8),

                // Option 3: Accept Server
                _buildStrategyTile(
                  strategy: ConflictResolutionStrategy.serverWins,
                  title: 'የሰርቨሩን ዳታ ተቀበል (Accept Server / Server Wins)',
                  desc:
                      'Discard local offline edits and adopt cloud values (${CurrencyFormatter.formatEtb(conflict.serverPrice)} & ${conflict.serverStock.toStringAsFixed(0)} pcs).',
                ),

                const SizedBox(height: 18),

                // Confirm CTA
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KeraColors.primaryNavyDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isResolving
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isResolving = true);
                            await Future<void>.delayed(
                                const Duration(milliseconds: 400));
                            ref
                                .read(activeConflictsProvider.notifier)
                                .resolveConflict(
                                    conflict.id, _selectedStrategy);
                            if (mounted) {
                              setState(() => _isResolving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'ግጭቱ በተሳካ ሁኔታ ተፈቷል / Conflict Resolved (${_selectedStrategy.name})',
                                  ),
                                ),
                              );
                            }
                          },
                    child: _isResolving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ውሳኔውን አረጋግጥ / Confirm Resolution',
                            style: KeraTypography.labelLarge(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow({
    required String title,
    required String diffLabel,
    required String localVal,
    required String localSub,
    required String serverVal,
    required String serverSub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KeraColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KeraColors.outlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: KeraTypography.labelSmall()
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: KeraColors.errorBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  diffLabel,
                  style: KeraTypography.labelSmall(
                    color: KeraColors.errorRed,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Local Phone Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.smartphone_rounded,
                              size: 14, color: KeraColors.actionBlue),
                          const SizedBox(width: 4),
                          Text(
                            'ስልክ (Local)',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.actionBlue,
                            ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localVal,
                        style: KeraTypography.labelMedium()
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        localSub,
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Cloud Server Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_outlined,
                              size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            'ሰርቨር (Cloud)',
                            style: KeraTypography.labelSmall(
                              color: Colors.purple,
                            ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serverVal,
                        style: KeraTypography.labelMedium()
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        serverSub,
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ).copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTile({
    required ConflictResolutionStrategy strategy,
    required String title,
    required String desc,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedStrategy == strategy;

    return InkWell(
      onTap: () => setState(() => _selectedStrategy = strategy),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? KeraColors.actionBlue
                      : KeraColors.textSecondary,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: KeraTypography.labelMedium().copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? KeraColors.actionBlue
                                : KeraColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ይመከራል',
                            style: KeraTypography.labelSmall(
                              color: Colors.green.shade800,
                            ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: KeraTypography.bodySmall(
                      color: KeraColors.textSecondary,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

