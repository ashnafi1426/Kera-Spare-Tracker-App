import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_card.dart';
import '../../../../core/design/widgets/kera_status_badge.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/image_management_widgets.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../data/local/app_database.dart';
import '../../../stock/presentation/dialogs/update_stock_dialog.dart';
import '../../domain/models/part_item.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';

/// Stitch Screen 16: Product Details (የመለዋወጫ ዝርዝር).
///
/// Features large Hero Showcase with genuine badge and stock status pill,
/// Bento Pricing & Margin analytics card, Stock & Warehouse location card
/// with instant stock update action, technical specifications table,
/// and contextual management drawer.
class PartDetailsScreen extends ConsumerStatefulWidget {
  final String partId;

  const PartDetailsScreen({
    super.key,
    required this.partId,
  });

  @override
  ConsumerState<PartDetailsScreen> createState() => _PartDetailsScreenState();
}

class _PartDetailsScreenState extends ConsumerState<PartDetailsScreen> {
  Future<void> _confirmDelete(PartItem part) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePartConfirmTitle, style: KeraTypography.titleSmall()),
        content: Text(l10n.deletePartConfirmMessage, style: KeraTypography.bodyMedium()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.red600,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ownerId = ref.read(currentOwnerIdProvider);
      final repo = ref.read(partsRepositoryProvider);
      final result = await repo.deletePart(ownerId: ownerId, id: part.id);

      if (!mounted) return;

      if (result.isSuccess) {
        context.showSnackBar(l10n.partDeletedSuccess);
        Navigator.of(context).pop(true);
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'Error deleting part',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partAsync = ref.watch(partByIdProvider(widget.partId));
    final brandsAsync = ref.watch(brandsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final locationsAsync = ref.watch(locationsStreamProvider);

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        title: Text(
          l10n.partDetails,
          style: KeraTypography.titleMedium(color: Colors.white).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          partAsync.when(
            data: (part) => part != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: l10n.edit,
                    onPressed: () async {
                      final updated =
                          await context.push<bool>('/parts/${part.id}/edit');
                      if (updated == true && mounted) {
                        ref.invalidate(partByIdProvider(widget.partId));
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          partAsync.when(
            data: (part) => part != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    tooltip: l10n.delete,
                    onPressed: () => _confirmDelete(part),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: partAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KeraColors.actionBlue),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(), style: KeraTypography.bodyMedium()),
        ),
        data: (part) {
          if (part == null) {
            return Center(
              child: Text(
                l10n.noDataTitle,
                style: KeraTypography.titleMedium(),
              ),
            );
          }

          // Resolve display names for foreign keys
          final brandName = brandsAsync.value
              ?.where((b) => b.id == part.brandId)
              .firstOrNull
              ?.name;
          final categoryName = categoriesAsync.value
              ?.where((c) => c.id == part.categoryId)
              .firstOrNull
              ?.name;
          final locationName = locationsAsync.value
              ?.where((l) => l.id == part.locationId)
              .firstOrNull
              ?.name;

          final hasPhoto = part.photoLocalPath != null &&
              File(part.photoLocalPath!).existsSync();

          final totalStockValue = (part.sellingPrice ?? part.purchasePrice ?? 0.0) *
              part.cachedQuantity;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Hero Showcase Container (Stitch Screen 16)
              _buildHeroShowcase(part, hasPhoto, brandName, ref.watch(partImagesStreamProvider(part.id)).value ?? []),
              const SizedBox(height: 16),

              // 2. Part Name & Number Header
              Text(
                part.displayName,
                style: KeraTypography.headlineSmall(color: KeraColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (part.partNumber != null &&
                  part.partNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.numbers_rounded,
                        size: 16, color: KeraColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      part.partNumber!,
                      style: KeraTypography.titleSmall(color: KeraColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Chips for Brand & Category
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (brandName != null && brandName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withValues(alpha: 0.1),
                        borderRadius: KeraRadii.borderMicro,
                        border: Border.all(
                            color: KeraColors.actionBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car_rounded,
                              size: 14, color: KeraColors.actionBlue),
                          const SizedBox(width: 4),
                          Text(
                            brandName,
                            style: KeraTypography.labelSmall(
                                color: KeraColors.actionBlue).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (categoryName != null && categoryName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceMuted,
                        borderRadius: KeraRadii.borderMicro,
                        border: Border.all(color: KeraColors.outlineBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open_rounded,
                              size: 14, color: KeraColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            categoryName,
                            style: KeraTypography.labelSmall(
                                color: KeraColors.textSecondary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Key Price & Margin Bento Card (Stitch Screen 16)
              KeraCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Row 1: Stock Quantity Pill & Total Valuation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.quantityInStock,
                          style: KeraTypography.titleSmall(),
                        ),
                        _buildStockPill(part),
                      ],
                    ),
                    const Divider(height: 20, color: KeraColors.outlineBorder),

                    // Row 2: 3-column Pricing Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PriceColumn(
                          title: l10n.purchasePrice,
                          amount: part.purchasePrice,
                        ),
                        _PriceColumn(
                          title: l10n.sellingPrice,
                          amount: part.sellingPrice,
                          isHighlighted: true,
                          color: KeraColors.textMutedColor,
                        ),
                        _PriceColumn(
                          title: l10n.estimatedProfit,
                          amount: part.unitProfit,
                          color: KeraColors.stockInText,
                        ),
                      ],
                    ),

                    if (totalStockValue > 0) ...[
                      const Divider(height: 20, color: KeraColors.outlineBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ጠቅላላ የክምችት ዋጋ:',
                            style: KeraTypography.bodySmall(
                                color: KeraColors.textSecondary),
                          ),
                          Text(
                            '${totalStockValue.toStringAsFixed(0)} ብር',
                            style: KeraTypography.numericCompact(
                                color: KeraColors.primaryNavy).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Warehouse & Stock Actions Card
              KeraCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: KeraColors.surfaceMuted,
                          child: Icon(Icons.shelves,
                              size: 18, color: KeraColors.actionBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.storageLocation,
                                  style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary)),
                              Text(
                                [
                                  ?locationName,
                                  if (part.customLocation != null &&
                                      part.customLocation!.trim().isNotEmpty)
                                    part.customLocation!,
                                ].join(' • ').ifEmpty('ያልተገለጸ (Not specified)'),
                                style: KeraTypography.titleSmall(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons: Update Stock & Movement History
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KeraColors.orange500,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const RoundedRectangleBorder(
                                borderRadius: KeraRadii.borderButton,
                              ),
                            ),
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            label: Text(l10n.updateStock),
                            onPressed: () =>
                                UpdateStockDialog.show(context, part),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: KeraRadii.borderButton,
                            ),
                            side: const BorderSide(color: KeraColors.outlineBorder),
                          ),
                          icon: const Icon(Icons.history_rounded, size: 20),
                          label: Text(l10n.stockMovementHistory),
                          onPressed: () =>
                              context.push('/parts/${part.id}/history'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Technical Specifications & Notes
              if ((part.sizeSpecs != null && part.sizeSpecs!.trim().isNotEmpty) ||
                  (part.description != null &&
                      part.description!.trim().isNotEmpty) ||
                  (part.notes != null && part.notes!.trim().isNotEmpty)) ...[
                KeraCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ዝርዝር መረጃ (Specifications)',
                        style: KeraTypography.titleSmall().copyWith(
                          color: KeraColors.primaryNavy,
                        ),
                      ),
                      const Divider(height: 16, color: KeraColors.outlineBorder),
                      if (part.sizeSpecs != null &&
                          part.sizeSpecs!.trim().isNotEmpty) ...[
                        _buildSpecRow(
                            Icons.tune_rounded, l10n.sizeSpecs, part.sizeSpecs!),
                        const SizedBox(height: 10),
                      ],
                      if (part.description != null &&
                          part.description!.trim().isNotEmpty) ...[
                        _buildSpecRow(Icons.notes_rounded, l10n.description,
                            part.description!),
                        const SizedBox(height: 10),
                      ],
                      if (part.notes != null &&
                          part.notes!.trim().isNotEmpty) ...[
                        _buildSpecRow(Icons.edit_note_rounded, l10n.notes,
                            part.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroShowcase(PartItem part, bool hasPhoto, String? brandName, [List<InventoryImageLocal> images = const []]) {
    if (images.isNotEmpty) {
      return InventoryImageGallery(
        images: images,
        fallbackLocalPath: part.photoLocalPath,
        fallbackPhotoUrl: part.photoUrl,
        partName: part.displayName,
      );
    }
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: KeraColors.surfaceMuted,
        borderRadius: KeraRadii.borderCard,
        border: Border.all(color: KeraColors.outlineBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: KeraPartImage(
              localPath: part.photoLocalPath,
              remoteUrl: part.photoUrl,
              width: double.infinity,
              height: 220,
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
          ),
          // Floating OEM Genuine Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KeraColors.primaryNavy.withValues(alpha: 0.85),
                borderRadius: KeraRadii.borderMicro,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 14, color: KeraColors.tealAccent),
                  const SizedBox(width: 4),
                  Text(
                    'OEM GENUINE',
                    style: KeraTypography.labelSmall(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockPill(PartItem part) {
    final qtyText =
        '${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}'.trim();
    if (part.isOutOfStock || part.cachedQuantity <= 0) {
      return KeraStatusBadge.outOfStock(label: 'ያለቀ ($qtyText)');
    } else if (part.isLowStock) {
      return KeraStatusBadge.lowStock(quantity: part.cachedQuantity);
    } else {
      return KeraStatusBadge(
        label: qtyText,
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: KeraColors.stockInBg,
        textColor: KeraColors.stockInText,
      );
    }
  }

  Widget _buildSpecRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KeraColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final String title;
  final double? amount;
  final bool isHighlighted;
  final Color? color;

  const _PriceColumn({
    required this.title,
    this.amount,
    this.isHighlighted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KeraTypography.labelSmall(color: KeraColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          amount != null ? '${amount!.toStringAsFixed(2)} ብር' : '—',
          style: KeraTypography.titleSmall().copyWith(
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isHighlighted ? KeraColors.actionBlue : KeraColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
