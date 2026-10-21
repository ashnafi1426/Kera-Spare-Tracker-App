import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../stock/presentation/dialogs/update_stock_dialog.dart';
import '../../domain/models/part_item.dart';
import '../providers/metadata_providers.dart';
import '../providers/parts_providers.dart';



/// Detailed view of a spare part displaying photo, catalog attributes,
/// stock level, unit pricing, profit margin, and management actions (edit, delete).
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
        title: Text(l10n.deletePartConfirmTitle),
        content: Text(l10n.deletePartConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
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
        Navigator.of(context).pop();
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
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final partAsync = ref.watch(partByIdProvider(widget.partId));
    final brandsAsync = ref.watch(brandsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final locationsAsync = ref.watch(locationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.partDetails),
        actions: [
          partAsync.when(
            data: (part) => part != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.edit,
                    onPressed: () async {
                      final updated =
                          await context.push<bool>('/parts/${part.id}/edit');
                      if (updated == true && context.mounted) {
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
                    icon: Icon(Icons.delete_outline_rounded,
                        color: colorScheme.error),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (part) {
          if (part == null) {
            return Center(
              child: Text(
                l10n.noDataTitle,
                style: theme.textTheme.titleMedium,
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

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Large Photo Banner
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Image.file(
                        File(part.photoLocalPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noPhoto,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // 2. Part Name & Part Number Header
              Text(
                part.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (part.partNumber != null &&
                  part.partNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.tag_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      part.partNumber!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Chips for Brand & Category
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (brandName != null)
                    Chip(
                      avatar: const Icon(Icons.directions_car_rounded, size: 16),
                      label: Text(brandName),
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  if (categoryName != null)
                    Chip(
                      avatar: const Icon(Icons.folder_open_rounded, size: 16),
                      label: Text(categoryName),
                      backgroundColor: colorScheme.secondaryContainer,
                      labelStyle:
                          TextStyle(color: colorScheme.onSecondaryContainer),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Stock Level & Valuation Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.quantityInStock,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: part.cachedQuantity > 0
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : colorScheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: part.cachedQuantity > 0
                                    ? Colors.green.shade800
                                    : colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
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
                          ),
                          _PriceColumn(
                            title: l10n.estimatedProfit,
                            amount: part.unitProfit,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stock Actions: Update Stock & Movement History
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_note_rounded),
                              label: Text(l10n.updateStock),
                              onPressed: () => UpdateStockDialog.show(context, part),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            icon: const Icon(Icons.history_rounded),
                            tooltip: l10n.stockMovementHistory,
                            onPressed: () =>
                                context.push('/parts/${part.id}/history'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Storage Location
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.tertiaryContainer,
                    child: Icon(Icons.place_rounded, color: colorScheme.tertiary),
                  ),
                  title: Text(l10n.storageLocation),
                  subtitle: Text(
                    [
                      ?locationName,
                      if (part.customLocation != null &&
                          part.customLocation!.trim().isNotEmpty)
                        part.customLocation!,
                    ].join(' • ').ifEmpty('—'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Size / Specs & Description & Notes
              if (part.sizeSpecs != null &&
                  part.sizeSpecs!.trim().isNotEmpty) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(l10n.sizeSpecs),
                    subtitle: Text(part.sizeSpecs!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (part.description != null &&
                  part.description!.trim().isNotEmpty) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notes_rounded),
                    title: Text(l10n.description),
                    subtitle: Text(part.description!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (part.notes != null && part.notes!.trim().isNotEmpty) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: Text(l10n.notes),
                    subtitle: Text(part.notes!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
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
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount != null ? '${amount!.toStringAsFixed(2)} ብር' : '—',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isHighlighted ? colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
