import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../stock/data/repositories/local_stock_repository.dart';
import '../../domain/models/sale_item_model.dart';
import '../../domain/models/sale_line_item.dart';
import '../../domain/models/sale_model.dart';
import '../../domain/repositories/sales_repository.dart';

/// Local SQLite Drift-backed implementation of [SalesRepository].
///
/// Implements atomic sales transactions with snapshot preservation:
/// - Header, line items, ledger movements, and stock decrements commit together in ONE transaction.
/// - Snapshots `part_name_snapshot`, `unit_cost`, `unit_price`, and line profit so later catalog edits never change historical figures.
/// - Appends negative `MovementType.sale` to the `stock_movements` ledger linked via `reference_id`.
/// - Enqueues every mutation to `sync_queue` for cloud sync.
class LocalSalesRepository implements SalesRepository {
  final AppDatabase db;
  final Uuid uuid;

  LocalSalesRepository({
    required this.db,
    this.uuid = const Uuid(),
  });


  @override
  Future<Result<SaleModel>> createSale({
    required String ownerId,
    required List<SaleLineItem> items,
    String? notes,
    String? paymentMethod,
    bool forceAllowNegative = false,
  }) async {
    if (items.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          message: 'Cannot save an empty sale. Please add at least one part.',
        ),
      );
    }

    for (final item in items) {
      if (item.quantity <= 0) {
        return Result.failure(
          ValidationFailure(
            message: 'Quantity for "${item.part.displayName}" must be greater than zero.',
          ),
        );
      }
      if (item.unitPrice < 0) {
        return Result.failure(
          ValidationFailure(
            message: 'Unit price for "${item.part.displayName}" cannot be negative.',
          ),
        );
      }
    }

    try {
      // Check negative stock limits for all items prior to transaction
      if (!forceAllowNegative) {
        final allowNegativeSetting =
            await db.settingsDao.getSetting(LocalStockRepository.settingAllowNegativeStock);
        final isNegativeAllowed = allowNegativeSetting == 'true';

        if (!isNegativeAllowed) {
          for (final item in items) {
            final partInDb = await db.partsDao.getPartById(item.part.id, ownerId);
            final currentStock = partInDb?.cachedQuantity ?? 0.0;
            final projected = currentStock - item.quantity;
            if (projected < 0) {
              return Result.failure(
                NegativeStockFailure(
                  message:
                      'Quantity for "${partInDb?.name ?? item.part.displayName}" exceeds available stock ($currentStock).',
                  projectedStock: projected,
                ),
              );
            }
          }
        }
      }

      final now = DateTime.now();
      final saleId = uuid.v4();
      final receiptNumber =
          'REC-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${uuid.v4().substring(0, 4).toUpperCase()}';

      final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
      final totalProfit = items.fold(0.0, (sum, i) => sum + i.lineProfit);

      final List<SaleItemModel> createdItems = [];

      await db.transaction(() async {
        // 1. Insert Sales Header
        await db.into(db.sales).insert(
              SalesCompanion.insert(
                id: Value(saleId),
                ownerId: ownerId,
                receiptNumber: Value(receiptNumber),
                soldAt: Value(now),
                subtotal: subtotal,
                discount: const Value(0.0),
                totalAmount: subtotal,
                totalProfit: totalProfit,
                paymentMethod: Value(paymentMethod),
                notes: Value(notes?.trim()),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // 2. Enqueue Sales Header to sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'sales',
          recordId: saleId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': saleId,
            'owner_id': ownerId,
            'receipt_number': receiptNumber,
            'sold_at': now.toIso8601String(),
            'subtotal': subtotal,
            'discount': 0.0,
            'total_amount': subtotal,
            'total_profit': totalProfit,
            'payment_method': paymentMethod,
            'notes': notes?.trim(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        // 3. Insert each Line Item, Ledger Movement, Stock Decrement & Sync Entries
        for (final item in items) {
          final saleItemId = uuid.v4();
          final movementId = uuid.v4();

          final partInDb = await db.partsDao.getPartById(item.part.id, ownerId);
          final currentStock = partInDb?.cachedQuantity ?? 0.0;
          final newStock = currentStock - item.quantity;
          final partNameSnapshot = item.part.displayName;

          // 3a. Insert sale_items row
          await db.into(db.saleItems).insert(
                SaleItemsCompanion.insert(
                  id: Value(saleItemId),
                  ownerId: ownerId,
                  saleId: saleId,
                  partId: item.part.id,
                  partNameSnapshot: partNameSnapshot,
                  quantity: item.quantity,
                  unitCost: item.unitCost,
                  unitPrice: item.unitPrice,
                  lineTotal: item.lineTotal,
                  lineProfit: item.lineProfit,
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          // 3b. Enqueue sale_items insert
          await db.syncQueueDao.enqueue(
            tableName: 'sale_items',
            recordId: saleItemId,
            operation: SyncOperation.insert,
            payload: jsonEncode({
              'id': saleItemId,
              'owner_id': ownerId,
              'sale_id': saleId,
              'part_id': item.part.id,
              'part_name_snapshot': partNameSnapshot,
              'quantity': item.quantity,
              'unit_cost': item.unitCost,
              'unit_price': item.unitPrice,
              'line_total': item.lineTotal,
              'line_profit': item.lineProfit,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            }),
          );

          // 3c. Insert negative stock_movements ledger entry
          await db.into(db.stockMovements).insert(
                StockMovementsCompanion.insert(
                  id: Value(movementId),
                  ownerId: ownerId,
                  partId: item.part.id,
                  type: MovementType.sale,
                  quantityChange: -item.quantity,
                  unitCost: Value(item.unitCost),
                  referenceId: Value(saleId),
                  note: Value('Sale receipt #$receiptNumber'),
                  movedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          // 3d. Enqueue stock_movements insert
          await db.syncQueueDao.enqueue(
            tableName: 'stock_movements',
            recordId: movementId,
            operation: SyncOperation.insert,
            payload: jsonEncode({
              'id': movementId,
              'owner_id': ownerId,
              'part_id': item.part.id,
              'type': MovementType.sale.name,
              'quantity_change': -item.quantity,
              'unit_cost': item.unitCost,
              'reference_id': saleId,
              'note': 'Sale receipt #$receiptNumber',
              'moved_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
            }),
          );

          // 3e. Update spare_parts cached_quantity
          await (db.update(db.spareParts)..where((t) => t.id.equals(item.part.id))).write(
            SparePartsCompanion(
              cachedQuantity: Value(newStock),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

          // 3f. Enqueue spare_parts update
          await db.syncQueueDao.enqueue(
            tableName: 'spare_parts',
            recordId: item.part.id,
            operation: SyncOperation.update,
            payload: jsonEncode({
              'cached_quantity': newStock,
              'updated_at': now.toIso8601String(),
            }),
          );

          createdItems.add(
            SaleItemModel(
              id: saleItemId,
              saleId: saleId,
              partId: item.part.id,
              partNameSnapshot: partNameSnapshot,
              quantity: item.quantity,
              unitCost: item.unitCost,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
              lineProfit: item.lineProfit,
            ),
          );
        }
      });

      return Result.success(
        SaleModel(
          id: saleId,
          ownerId: ownerId,
          receiptNumber: receiptNumber,
          soldAt: now,
          subtotal: subtotal,
          discount: 0.0,
          totalAmount: subtotal,
          totalProfit: totalProfit,
          paymentMethod: paymentMethod,
          notes: notes?.trim(),
          items: createdItems,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to record sale: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<SaleModel>> getSaleById({
    required String ownerId,
    required String saleId,
  }) async {
    try {
      final sale = await (db.select(db.sales)
            ..where((t) =>
                t.id.equals(saleId) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull()))
          .getSingleOrNull();

      if (sale == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Sale transaction not found'),
        );
      }

      final items = await (db.select(db.saleItems)
            ..where((t) =>
                t.saleId.equals(saleId) &
                t.ownerId.equals(ownerId) &
                t.deletedAt.isNull()))
          .get();

      return Result.success(
        SaleModel(
          id: sale.id,
          ownerId: sale.ownerId,
          receiptNumber: sale.receiptNumber,
          soldAt: sale.soldAt,
          subtotal: sale.subtotal,
          discount: sale.discount,
          totalAmount: sale.totalAmount,
          totalProfit: sale.totalProfit,
          paymentMethod: sale.paymentMethod,
          notes: sale.notes,
          items: items
              .map(
                (i) => SaleItemModel(
                  id: i.id,
                  saleId: i.saleId,
                  partId: i.partId,
                  partNameSnapshot: i.partNameSnapshot,
                  quantity: i.quantity,
                  unitCost: i.unitCost,
                  unitPrice: i.unitPrice,
                  lineTotal: i.lineTotal,
                  lineProfit: i.lineProfit,
                ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to fetch sale details: $e', cause: e),
      );
    }
  }

  @override
  Stream<List<SaleModel>> watchActiveSales(String ownerId) {
    return (db.select(db.sales)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.soldAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (s) => SaleModel(
                  id: s.id,
                  ownerId: s.ownerId,
                  receiptNumber: s.receiptNumber,
                  soldAt: s.soldAt,
                  subtotal: s.subtotal,
                  discount: s.discount,
                  totalAmount: s.totalAmount,
                  totalProfit: s.totalProfit,
                  paymentMethod: s.paymentMethod,
                  notes: s.notes,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<SaleModel>> watchFilteredSales({
    required String ownerId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return db.salesDao
        .watchFilteredSales(
          ownerId: ownerId,
          query: query,
          startDate: startDate,
          endDate: endDate,
        )
        .map(
          (rows) => rows
              .map(
                (s) => SaleModel(
                  id: s.id,
                  ownerId: s.ownerId,
                  receiptNumber: s.receiptNumber,
                  soldAt: s.soldAt,
                  subtotal: s.subtotal,
                  discount: s.discount,
                  totalAmount: s.totalAmount,
                  totalProfit: s.totalProfit,
                  paymentMethod: s.paymentMethod,
                  notes: s.notes,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<Result<void>> deleteSale({
    required String ownerId,
    required String saleId,
  }) async {
    try {
      await db.salesDao.softDeleteSale(saleId, ownerId);
      await db.syncQueueDao.enqueue(
        tableName: 'sales',
        recordId: saleId,
        operation: SyncOperation.delete,
        payload: jsonEncode({
          'id': saleId,
          'deleted_at': DateTime.now().toIso8601String(),
        }),
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to delete sale: $e', cause: e),
      );
    }
  }
}
