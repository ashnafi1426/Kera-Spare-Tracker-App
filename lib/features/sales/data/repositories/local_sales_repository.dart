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
/// Implements Phase 3 Offline Sales architecture:
/// - One SQLite transaction validates locally, inserts sale + items (with unit_cost),
///   inserts negative stock_movements, reduces local quantity, and enqueues ONE sale operation.
/// - Retry-safe: The same saleId can never reduce stock twice.
/// - Sales are immutable after creation; corrections use returnSale operations.
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
    String? saleId,
    String? notes,
    String? paymentMethod,
    double discount = 0.0,
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
            message:
                'Quantity for "${item.part.displayName}" must be greater than zero.',
          ),
        );
      }
      if (item.unitPrice < 0) {
        return Result.failure(
          ValidationFailure(
            message:
                'Unit price for "${item.part.displayName}" cannot be negative.',
          ),
        );
      }
    }

    final effectiveSaleId = saleId ?? uuid.v4();

    try {
      final now = DateTime.now();

      // Check negative stock limits prior to transaction
      if (!forceAllowNegative) {
        final allowNegativeSetting = await db.settingsDao
            .getSetting(LocalStockRepository.settingAllowNegativeStock);
        final isNegativeAllowed = allowNegativeSetting == 'true';

        if (!isNegativeAllowed) {
          for (final item in items) {
            final partInDb =
                await db.partsDao.getPartById(item.part.id, ownerId);
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

      final receiptNumber =
          'REC-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${uuid.v4().substring(0, 4).toUpperCase()}';

      final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
      final totalCost =
          items.fold(0.0, (sum, i) => sum + (i.unitCost * i.quantity));
      final totalProfit = items.fold(0.0, (sum, i) => sum + i.lineProfit);

      final List<SaleItemModel> createdItems = [];

      // Execute entire operation in ONE atomic SQLite transaction
      final resultModel = await db.transaction<SaleModel>(() async {
        // Idempotency check: If sale already exists, do NOT reduce stock again!
        final existingSale = await (db.select(db.sales)
              ..where((t) => t.id.equals(effectiveSaleId)))
            .getSingleOrNull();

        if (existingSale != null) {
          // Already recorded; fetch and return idempotently
          final existingItems = await (db.select(db.saleItems)
                ..where((t) => t.saleId.equals(effectiveSaleId)))
              .get();
          return SaleModel(
            id: existingSale.id,
            ownerId: existingSale.ownerId,
            receiptNumber: existingSale.receiptNumber,
            soldAt: existingSale.soldAt,
            subtotal: existingSale.subtotal,
            discount: existingSale.discount,
            totalAmount: existingSale.totalAmount,
            totalProfit: existingSale.totalProfit,
            paymentMethod: existingSale.paymentMethod,
            notes: existingSale.notes,
            items: existingItems
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
          );
        }

        // 1. Insert Sales Header
        await db.into(db.sales).insert(
              SalesCompanion.insert(
                id: Value(effectiveSaleId),
                ownerId: ownerId,
                saleNumber: Value(receiptNumber),
                receiptNumber: Value(receiptNumber),
                soldAt: Value(now),
                saleDate: Value(now),
                subtotal: subtotal,
                discount: Value(discount),
                totalAmount: (subtotal - discount).clamp(0.0, double.infinity),
                totalCost: Value(totalCost),
                totalProfit: totalProfit - discount,
                paymentMethod: Value(paymentMethod),
                notes: Value(notes?.trim()),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        final bundledItemsPayload = <Map<String, dynamic>>[];

        // 2. Insert Sale Items, Stock Movements, & update on-hand quantities
        for (final item in items) {
          final saleItemId = uuid.v4();
          final movementId = uuid.v4();

          final partInDb = await db.partsDao.getPartById(item.part.id, ownerId);
          final currentStock = partInDb?.cachedQuantity ?? 0.0;
          final newStock = currentStock - item.quantity;
          final partNameSnapshot = item.part.displayName;

          // 2a. Insert sale_items row with unit_cost snapshot
          await db.into(db.saleItems).insert(
                SaleItemsCompanion.insert(
                  id: Value(saleItemId),
                  ownerId: ownerId,
                  saleId: effectiveSaleId,
                  partId: item.part.id,
                  sparePartId: Value(item.part.id),
                  partNameSnapshot: partNameSnapshot,
                  quantity: item.quantity,
                  unitCost: item.unitCost,
                  unitPrice: item.unitPrice,
                  lineTotal: item.lineTotal,
                  subtotal: Value(item.lineTotal),
                  lineProfit: item.lineProfit,
                  profit: Value(item.lineProfit),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          // 2b. Insert negative stock_movements ledger entry (immutable)
          await db.into(db.stockMovements).insert(
                StockMovementsCompanion.insert(
                  id: Value(movementId),
                  ownerId: ownerId,
                  partId: item.part.id,
                  sparePartId: Value(item.part.id),
                  type: MovementType.sale,
                  movementType: const Value('sale'),
                  quantityChange: -item.quantity,
                  quantityBefore: Value(currentStock),
                  quantityAfter: Value(newStock),
                  unitCost: Value(item.unitCost),
                  referenceId: Value(effectiveSaleId),
                  note: Value('Sale receipt #$receiptNumber'),
                  movedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          // 2c. Update local spare_parts cachedQuantity
          await (db.update(db.spareParts)
                ..where((t) => t.id.equals(item.part.id)))
              .write(
            SparePartsCompanion(
              cachedQuantity: Value(newStock),
              quantity: Value(newStock),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

          createdItems.add(
            SaleItemModel(
              id: saleItemId,
              saleId: effectiveSaleId,
              partId: item.part.id,
              partNameSnapshot: partNameSnapshot,
              quantity: item.quantity,
              unitCost: item.unitCost,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
              lineProfit: item.lineProfit,
            ),
          );

          bundledItemsPayload.add({
            'id': saleItemId,
            'sale_id': effectiveSaleId,
            'owner_id': ownerId,
            'part_id': item.part.id,
            'part_number': item.part.partNumber,
            'part_name_snapshot': partNameSnapshot,
            'quantity': item.quantity,
            'unit_cost': item.unitCost,
            'unit_price': item.unitPrice,
            'subtotal': item.lineTotal,
            'profit': item.lineProfit,
          });
        }

        // 3. Enqueue ONE atomic sale operation containing all header & line items
        await db.syncQueueDao.enqueueOperation(
          operationId: effectiveSaleId,
          ownerId: ownerId,
          entityType: 'sales',
          entityId: effectiveSaleId,
          operationType: 'insert',
          payload: jsonEncode({
            'id': effectiveSaleId,
            'owner_id': ownerId,
            'sale_number': receiptNumber,
            'receipt_number': receiptNumber,
            'sold_at': now.toIso8601String(),
            'sale_date': now.toIso8601String(),
            'subtotal': subtotal,
            'discount': 0.0,
            'total_amount': subtotal,
            'total_cost': totalCost,
            'total_profit': totalProfit,
            'payment_method': paymentMethod,
            'notes': notes?.trim(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'items': bundledItemsPayload,
          }),
        );

        return SaleModel(
          id: effectiveSaleId,
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
        );
      });

      return Result.success(resultModel);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to record sale: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> returnSale({
    required String ownerId,
    required String saleId,
    required String reason,
  }) async {
    try {
      final sale = await (db.select(db.sales)
            ..where((t) => t.id.equals(saleId) & t.ownerId.equals(ownerId)))
          .getSingleOrNull();

      if (sale == null) {
        return const Result.failure(
          NotFoundFailure(message: 'Sale transaction not found'),
        );
      }

      final returnRef = 'return_$saleId';
      final existingReturn = await (db.select(db.stockMovements)
            ..where((t) => t.referenceId.equals(returnRef)))
          .get();

      if (existingReturn.isNotEmpty) {
        // Return already processed
        return const Result.success(null);
      }

      final items = await (db.select(db.saleItems)
            ..where((t) => t.saleId.equals(saleId)))
          .get();

      final now = DateTime.now();

      await db.transaction(() async {
        // 1. For each item in sale, restore stock via positive return movement
        for (final item in items) {
          final movementId = uuid.v4();
          final partInDb =
              await db.partsDao.getPartById(item.partId, ownerId);
          final currentStock = partInDb?.cachedQuantity ?? 0.0;
          final restoredStock = currentStock + item.quantity;

          await db.into(db.stockMovements).insert(
                StockMovementsCompanion.insert(
                  id: Value(movementId),
                  ownerId: ownerId,
                  partId: item.partId,
                  sparePartId: Value(item.partId),
                  type: MovementType.returned,
                  movementType: const Value('return'),
                  quantityChange: item.quantity,
                  quantityBefore: Value(currentStock),
                  quantityAfter: Value(restoredStock),
                  unitCost: Value(item.unitCost),
                  referenceId: Value(returnRef),
                  note: Value('Sale Return: $reason'),
                  movedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value(SyncStatus.pending),
                ),
              );

          // Update spare part stock
          await (db.update(db.spareParts)
                ..where((t) => t.id.equals(item.partId)))
              .write(
            SparePartsCompanion(
              cachedQuantity: Value(restoredStock),
              quantity: Value(restoredStock),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );
        }

        // 2. Mark return note on sale header without changing historical amounts
        final updatedNotes = sale.notes != null
            ? '${sale.notes} | RETURNED: $reason'
            : 'RETURNED: $reason';

        await (db.update(db.sales)..where((t) => t.id.equals(saleId))).write(
          SalesCompanion(
            notes: Value(updatedNotes),
            updatedAt: Value(now),
          ),
        );

        // 3. Enqueue ONE return operation to outbox
        await db.syncQueueDao.enqueueOperation(
          operationId: uuid.v4(),
          ownerId: ownerId,
          entityType: 'sale_returns',
          entityId: saleId,
          operationType: 'insert',
          payload: jsonEncode({
            'sale_id': saleId,
            'owner_id': ownerId,
            'reason': reason,
            'returned_at': now.toIso8601String(),
          }),
        );
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to process sale return: $e', cause: e),
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
        .asyncMap((rows) async {
          if (rows.isEmpty) return <SaleModel>[];
          final saleIds = rows.map((s) => s.id).toList();
          final allItems = await (db.select(db.saleItems)
                ..where((i) => i.saleId.isIn(saleIds) & i.deletedAt.isNull()))
              .get();

          final itemsBySaleId = <String, List<SaleItemModel>>{};
          for (final i in allItems) {
            itemsBySaleId.putIfAbsent(i.saleId, () => []).add(
              SaleItemModel(
                id: i.id,
                saleId: i.saleId,
                partId: i.partId,
                partNameSnapshot: i.partNameSnapshot,
                unitPrice: i.unitPrice,
                unitCost: i.unitCost,
                quantity: i.quantity,
                lineTotal: i.lineTotal,
                lineProfit: i.lineProfit,
              ),
            );
          }

          return rows
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
                  items: itemsBySaleId[s.id] ?? const [],
                ),
              )
              .toList();
        });
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
        .asyncMap((rows) async {
          if (rows.isEmpty) return <SaleModel>[];
          final saleIds = rows.map((s) => s.id).toList();
          final allItems = await (db.select(db.saleItems)
                ..where((i) => i.saleId.isIn(saleIds) & i.deletedAt.isNull()))
              .get();

          final itemsBySaleId = <String, List<SaleItemModel>>{};
          for (final i in allItems) {
            itemsBySaleId.putIfAbsent(i.saleId, () => []).add(
              SaleItemModel(
                id: i.id,
                saleId: i.saleId,
                partId: i.partId,
                partNameSnapshot: i.partNameSnapshot,
                unitPrice: i.unitPrice,
                unitCost: i.unitCost,
                quantity: i.quantity,
                lineTotal: i.lineTotal,
                lineProfit: i.lineProfit,
              ),
            );
          }

          return rows
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
                  items: itemsBySaleId[s.id] ?? const [],
                ),
              )
              .toList();
        });
  }

  @override
  Future<Result<void>> deleteSale({
    required String ownerId,
    required String saleId,
  }) async {
    try {
      await db.salesDao.softDeleteSale(saleId, ownerId);
      await db.syncQueueDao.enqueueOperation(
        operationId: uuid.v4(),
        ownerId: ownerId,
        entityType: 'sales',
        entityId: saleId,
        operationType: 'delete',
        payload: jsonEncode({
          'id': saleId,
          'owner_id': ownerId,
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
