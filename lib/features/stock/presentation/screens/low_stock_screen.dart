import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../parts/domain/models/part_item.dart';
import '../dialogs/update_stock_dialog.dart';
import '../providers/stock_providers.dart';

/// Screen listing all spare parts that are currently at or below their low stock threshold.
class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final lowStockAsync = ref.watch(lowStockPartsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lowStockListTitle),
      ),
      body: lowStockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (parts) {
          if (parts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noLowStockItems,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: parts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final part = parts[index];
              return _LowStockPartCard(part: part);
            },
          );
        },
      ),
    );
  }
}

class _LowStockPartCard extends StatelessWidget {
  final PartItem part;

  const _LowStockPartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    final hasPhoto =
        part.photoLocalPath != null && File(part.photoLocalPath!).existsSync();
    final threshold = part.lowStockLevel ?? 5.0;
    final isOutOfStock = part.cachedQuantity <= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.error.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/parts/${part.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail / Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Image.file(
                        File(part.photoLocalPath!),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.warning_amber_rounded,
                        color: isOutOfStock ? colorScheme.error : Colors.orange,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),

              // Title and Attributes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (part.partNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        part.partNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? colorScheme.errorContainer.withValues(alpha: 0.5)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${part.cachedQuantity.toStringAsFixed(0)} / ${threshold.toStringAsFixed(0)} ${part.unit ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOutOfStock
                                  ? colorScheme.error
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Action Button: Update Stock
              IconButton.filledTonal(
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                tooltip: l10n.updateStock,
                onPressed: () => UpdateStockDialog.show(context, part),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
