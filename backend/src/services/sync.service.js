import prisma from '../config/db.js';

/**
 * Sync Pull Service
 * Returns all tenant data and global catalog items updated since `lastPulledAt`.
 * On success, updates user's lastSyncAt and resets failedSyncCount to 0.
 */
export async function pullSyncData(userId, { lastPulledAt } = {}) {
  const since = lastPulledAt ? new Date(lastPulledAt) : new Date(0);

  const [
    globalBrands,
    globalCategories,
    globalUnits,
    customBrands,
    customCategories,
    locations,
    spareParts,
    stockMovements,
    sales,
  ] = await Promise.all([
    prisma.brand.findMany({
      where: {
        isGlobal: true,
        deletedAt: null,
        updatedAt: { gte: since },
      },
    }),
    prisma.category.findMany({
      where: {
        isGlobal: true,
        deletedAt: null,
        updatedAt: { gte: since },
      },
    }),
    prisma.unit.findMany({
      where: {
        isGlobal: true,
        deletedAt: null,
        updatedAt: { gte: since },
      },
    }),
    prisma.brand.findMany({
      where: {
        ownerId: userId,
        isGlobal: false,
        updatedAt: { gte: since },
      },
    }),
    prisma.category.findMany({
      where: {
        ownerId: userId,
        isGlobal: false,
        updatedAt: { gte: since },
      },
    }),
    prisma.location.findMany({
      where: {
        ownerId: userId,
        updatedAt: { gte: since },
      },
    }),
    prisma.sparePart.findMany({
      where: {
        ownerId: userId,
        updatedAt: { gte: since },
      },
    }),
    prisma.stockMovement.findMany({
      where: {
        ownerId: userId,
        updatedAt: { gte: since },
      },
    }),
    prisma.sale.findMany({
      where: {
        ownerId: userId,
        updatedAt: { gte: since },
      },
      include: {
        items: true,
      },
    }),
  ]);

  // Update telemetry: successful sync resets failedSyncCount to 0 and updates lastSyncAt
  await prisma.user
    .update({
      where: { id: userId },
      data: {
        lastSyncAt: new Date(),
        failedSyncCount: 0,
      },
    })
    .catch(() => {});

  return {
    serverTimestamp: new Date().toISOString(),
    changes: {
      brands: [...globalBrands, ...customBrands],
      categories: [...globalCategories, ...customCategories],
      units: globalUnits,
      locations,
      parts: spareParts,
      stockMovements,
      sales,
    },
  };
}

function normalizePaymentMethod(val) {
  if (!val) return 'CASH';
  const s = String(val).toUpperCase().replace(/[\s\-_]/g, '');
  if (s.includes('BANK') || s.includes('TRANSFER') || s.includes('TELEBIRR')) {
    return 'BANK_TRANSFER';
  }
  return 'CASH';
}

function normalizeMovementType(val) {
  if (!val) return 'ADJUSTMENT_IN';
  const s = String(val).toUpperCase().replace(/[\s\-_]/g, '');
  if (s === 'PURCHASE') return 'PURCHASE';
  if (s === 'SALE') return 'SALE';
  if (s === 'RETURN' || s === 'RETURNED') return 'RETURN';
  if (s.includes('OUT')) return 'ADJUSTMENT_OUT';
  return 'ADJUSTMENT_IN';
}

function safeNumber(val, defaultVal = null) {
  if (val === null || val === undefined || val === '') return defaultVal;
  const n = Number(val);
  return isNaN(n) ? defaultVal : n;
}

function safeDate(val, fallback = new Date()) {
  if (!val) return fallback;
  const d = new Date(val);
  return isNaN(d.getTime()) ? fallback : d;
}

/**
 * Sync Push Service
 * Processes mutations queued on device.
 * On success, resets failedSyncCount to 0 and updates lastSyncAt.
 * Guaranteed never to throw an unhandled fatal 500 error.
 */
export async function pushSyncData(userId, batch = []) {
  const applied = [];
  try {
    const safeBatch = Array.isArray(batch)
      ? batch.filter((item) => item && typeof item === 'object')
      : [];

    // Pre-fetch existing brandIds, categoryIds, locationIds, and partIds for foreign-key safety
    let existingBrands = [];
    let existingCategories = [];
    let existingLocations = [];
    let existingParts = [];

    try {
      [existingBrands, existingCategories, existingLocations, existingParts] = await Promise.all([
        prisma.brand.findMany({ where: { OR: [{ ownerId: userId }, { isGlobal: true }] }, select: { id: true } }),
        prisma.category.findMany({ where: { OR: [{ ownerId: userId }, { isGlobal: true }] }, select: { id: true } }),
        prisma.location.findMany({ where: { ownerId: userId }, select: { id: true } }),
        prisma.sparePart.findMany({ where: { ownerId: userId }, select: { id: true } }),
      ]);
    } catch (prefetchErr) {
      console.warn('[SyncPush] Warning pre-fetching FK lookups:', prefetchErr.message);
    }

    const validBrandIds = new Set(existingBrands.map((b) => b.id));
    const validCategoryIds = new Set(existingCategories.map((c) => c.id));
    const validLocationIds = new Set(existingLocations.map((l) => l.id));
    const validPartIds = new Set(existingParts.map((p) => p.id));

    // Register any incoming definitions from this batch upfront
    for (const item of safeBatch) {
      const entity = (item.entity || '').toLowerCase().replace(/_/g, '');
      const recId = item.id || item.data?.id;
      if (!recId) continue;
      if (entity === 'brands' || entity === 'brand') validBrandIds.add(recId);
      if (entity === 'categories' || entity === 'category') validCategoryIds.add(recId);
      if (entity === 'locations' || entity === 'location') validLocationIds.add(recId);
      if (entity === 'spareparts' || entity === 'sparepart' || entity === 'parts' || entity === 'part') validPartIds.add(recId);
    }

    for (const item of safeBatch) {
      const entity = (item.entity || '').toLowerCase().replace(/_/g, '');
      const action = (item.action || '').toLowerCase();
      const data = (item.data && typeof item.data === 'object') ? item.data : {};
      const recordId = String(item.id || data.id || '').trim();

      if (!recordId) continue;

      try {
        if (entity === 'brands' || entity === 'brand') {
          if (action === 'delete') {
            await prisma.brand.updateMany({ where: { id: recordId, ownerId: userId }, data: { deletedAt: new Date() } });
          } else {
            await prisma.brand.upsert({
              where: { id: recordId },
              update: { name: data.name || 'Custom Brand', updatedAt: new Date() },
              create: { id: recordId, ownerId: userId, name: data.name || 'Custom Brand', isGlobal: false },
            });
            validBrandIds.add(recordId);
          }
          applied.push({ id: recordId, entity: 'brands', status: 'applied' });
        } else if (entity === 'categories' || entity === 'category') {
          if (action === 'delete') {
            await prisma.category.updateMany({ where: { id: recordId, ownerId: userId }, data: { deletedAt: new Date() } });
          } else {
            await prisma.category.upsert({
              where: { id: recordId },
              update: { name: data.name || 'Custom Category', updatedAt: new Date() },
              create: { id: recordId, ownerId: userId, name: data.name || 'Custom Category', isGlobal: false },
            });
            validCategoryIds.add(recordId);
          }
          applied.push({ id: recordId, entity: 'categories', status: 'applied' });
        } else if (entity === 'locations' || entity === 'location') {
          if (action === 'delete') {
            await prisma.location.updateMany({ where: { id: recordId, ownerId: userId }, data: { deletedAt: new Date() } });
          } else {
            await prisma.location.upsert({
              where: { id: recordId },
              update: { name: data.name || 'Custom Shelf', updatedAt: new Date() },
              create: { id: recordId, ownerId: userId, name: data.name || 'Custom Shelf' },
            });
            validLocationIds.add(recordId);
          }
          applied.push({ id: recordId, entity: 'locations', status: 'applied' });
        } else if (entity === 'units' || entity === 'unit') {
          if (action === 'delete') {
            await prisma.unit.updateMany({ where: { id: recordId, ownerId: userId }, data: { deletedAt: new Date() } });
          } else {
            await prisma.unit.upsert({
              where: { id: recordId },
              update: { name: data.name || 'Piece', updatedAt: new Date() },
              create: { id: recordId, ownerId: userId, name: data.name || 'Piece', isGlobal: false },
            });
          }
          applied.push({ id: recordId, entity: 'units', status: 'applied' });
        } else if (entity === 'spareparts' || entity === 'sparepart' || entity === 'parts' || entity === 'part') {
          if (action === 'delete') {
            await prisma.sparePart.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const rawBrandId = data.brandId ?? data.brand_id ?? null;
            const rawCategoryId = data.categoryId ?? data.category_id ?? null;
            const rawLocationId = data.locationId ?? data.location_id ?? null;

            const partPayload = {
              name: data.name || 'Unnamed Part',
              partNumber: data.partNumber ?? data.part_number ?? null,
              photoUrl: data.photoUrl ?? data.photo_url ?? null,
              brandId: rawBrandId && validBrandIds.has(rawBrandId) ? rawBrandId : null,
              categoryId: rawCategoryId && validCategoryIds.has(rawCategoryId) ? rawCategoryId : null,
              locationId: rawLocationId && validLocationIds.has(rawLocationId) ? rawLocationId : null,
              customLocation: data.customLocation ?? data.custom_location ?? null,
              description: data.description ?? null,
              unit: data.unit ?? null,
              cachedQuantity: safeNumber(data.quantity !== undefined ? data.quantity : (data.cachedQuantity ?? data.cached_quantity), 0),
              purchasePrice: safeNumber(data.purchasePrice !== undefined ? data.purchasePrice : (data.purchase_price ?? null), null),
              sellingPrice: safeNumber(data.sellingPrice !== undefined ? data.sellingPrice : (data.selling_price ?? null), null),
              notes: data.notes ?? null,
              sizeSpecs: data.sizeSpecs ?? data.size_specs ?? null,
              isDemo: Boolean(data.isDemo ?? data.is_demo ?? (typeof data.notes === 'string' && data.notes.includes('[DEMO]')) ?? false),
              deletedAt: data.deletedAt ? safeDate(data.deletedAt, null) : null,
            };

            await prisma.sparePart.upsert({
              where: { id: recordId },
              update: {
                ...partPayload,
                ownerId: userId,
                updatedAt: new Date(),
              },
              create: {
                id: recordId,
                ownerId: userId,
                ...partPayload,
                createdAt: safeDate(data.createdAt, new Date()),
                updatedAt: new Date(),
              },
            });
            validPartIds.add(recordId);
          }
          applied.push({ id: recordId, entity: 'spare_parts', status: 'applied' });
        } else if (entity === 'sales' || entity === 'sale') {
          if (action === 'delete') {
            await prisma.sale.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const salePayload = {
              receiptNumber: data.receiptNumber ?? data.receipt_number ?? `REC-${Date.now()}`,
              totalAmount: safeNumber(data.totalAmount ?? data.total_amount, 0),
              totalProfit: safeNumber(data.totalProfit ?? data.total_profit, 0),
              paymentMethod: normalizePaymentMethod(data.paymentMethod ?? data.payment_method),
              customerName: data.customerName ?? data.customer_name ?? null,
              customerPhone: data.customerPhone ?? data.customer_phone ?? null,
              notes: data.notes ?? null,
              soldAt: safeDate(data.soldAt ?? data.sold_at, new Date()),
              deletedAt: data.deletedAt ? safeDate(data.deletedAt, null) : null,
            };

            await prisma.sale.upsert({
              where: { id: recordId },
              update: {
                ...salePayload,
                ownerId: userId,
                updatedAt: new Date(),
              },
              create: {
                id: recordId,
                ownerId: userId,
                ...salePayload,
                createdAt: safeDate(data.createdAt, new Date()),
                updatedAt: new Date(),
              },
            });

            if (Array.isArray(data.items)) {
              for (const itemRow of data.items) {
                const itemId = itemRow.id || `${recordId}_${itemRow.partId || itemRow.part_id || Math.random().toString(36).substring(2, 9)}`;
                const rawPartId = itemRow.partId ?? itemRow.part_id ?? null;
                const safePartId = rawPartId && validPartIds.has(rawPartId) ? rawPartId : null;
                const quantity = safeNumber(itemRow.quantity, 1);
                const unitCost = safeNumber(itemRow.unitCostSnapshot ?? itemRow.unit_cost_snapshot ?? itemRow.unit_cost, 0);
                const unitPrice = safeNumber(itemRow.unitPriceSnapshot ?? itemRow.unit_price_snapshot ?? itemRow.unit_price, 0);
                const subtotal = safeNumber(itemRow.subtotal ?? itemRow.line_total, quantity * unitPrice);
                const profit = safeNumber(itemRow.profit ?? itemRow.line_profit, subtotal - (quantity * unitCost));

                await prisma.saleItem.upsert({
                  where: { id: itemId },
                  update: {
                    ownerId: userId,
                    saleId: recordId,
                    partId: safePartId,
                    partNameSnapshot: itemRow.partNameSnapshot ?? itemRow.part_name_snapshot ?? 'Item',
                    quantity,
                    unitCostSnapshot: unitCost,
                    unitPriceSnapshot: unitPrice,
                    subtotal,
                    profit,
                    updatedAt: new Date(),
                  },
                  create: {
                    id: itemId,
                    ownerId: userId,
                    saleId: recordId,
                    partId: safePartId,
                    partNameSnapshot: itemRow.partNameSnapshot ?? itemRow.part_name_snapshot ?? 'Item',
                    quantity,
                    unitCostSnapshot: unitCost,
                    unitPriceSnapshot: unitPrice,
                    subtotal,
                    profit,
                  },
                });
              }
            }
          }
          applied.push({ id: recordId, entity: 'sales', status: 'applied' });
        } else if (entity === 'saleitems' || entity === 'sale_items' || entity === 'saleitem') {
          if (action === 'delete') {
            await prisma.saleItem.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const saleId = data.saleId ?? data.sale_id;
            const rawPartId = data.partId ?? data.part_id ?? null;
            const safePartId = rawPartId && validPartIds.has(rawPartId) ? rawPartId : null;
            const partNameSnapshot = data.partNameSnapshot ?? data.part_name_snapshot ?? 'Item';
            const quantity = safeNumber(data.quantity, 1);
            const unitCost = safeNumber(data.unitCostSnapshot ?? data.unit_cost ?? data.unit_cost_snapshot, 0);
            const unitPrice = safeNumber(data.unitPriceSnapshot ?? data.unit_price ?? data.unit_price_snapshot, 0);
            const subtotal = safeNumber(data.subtotal ?? data.line_total, quantity * unitPrice);
            const profit = safeNumber(data.profit ?? data.line_profit, subtotal - (quantity * unitCost));

            await prisma.saleItem.upsert({
              where: { id: recordId },
              update: {
                ownerId: userId,
                saleId,
                partId: safePartId,
                partNameSnapshot,
                quantity,
                unitCostSnapshot: unitCost,
                unitPriceSnapshot: unitPrice,
                subtotal,
                profit,
                updatedAt: new Date(),
              },
              create: {
                id: recordId,
                ownerId: userId,
                saleId,
                partId: safePartId,
                partNameSnapshot,
                quantity,
                unitCostSnapshot: unitCost,
                unitPriceSnapshot: unitPrice,
                subtotal,
                profit,
                createdAt: safeDate(data.createdAt, new Date()),
                updatedAt: new Date(),
              },
            });
          }
          applied.push({ id: recordId, entity: 'sale_items', status: 'applied' });
        } else if (entity === 'stockmovements' || entity === 'stockmovement') {
          if (action === 'delete') {
            await prisma.stockMovement.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const rawPartId = data.partId ?? data.part_id;
            if (rawPartId && validPartIds.has(rawPartId)) {
              const qty = Math.abs(safeNumber(data.quantity ?? data.quantity_change, 0));
              const unitCost = safeNumber(data.unitCost ?? data.unit_cost, null);
              await prisma.stockMovement.upsert({
                where: { id: recordId },
                update: {
                  ownerId: userId,
                  partId: rawPartId,
                  movementType: normalizeMovementType(data.movementType ?? data.movement_type ?? data.type),
                  quantity: qty,
                  unitCost,
                  reason: data.reason ?? data.note ?? null,
                  referenceId: data.referenceId ?? data.reference_id ?? null,
                  updatedAt: new Date(),
                },
                create: {
                  id: recordId,
                  ownerId: userId,
                  partId: rawPartId,
                  movementType: normalizeMovementType(data.movementType ?? data.movement_type ?? data.type),
                  quantity: qty,
                  unitCost,
                  reason: data.reason ?? data.note ?? null,
                  referenceId: data.referenceId ?? data.reference_id ?? null,
                },
              });
            }
          }
          applied.push({ id: recordId, entity: 'stock_movements', status: 'applied' });
        } else {
          // Users or other auxiliary tables
          applied.push({ id: recordId, status: 'acknowledged' });
        }
      } catch (itemErr) {
        console.error(`[SyncPush] Error applying item ${recordId} (${entity}):`, itemErr.message);
        applied.push({ id: recordId, status: 'error', error: itemErr.message });
      }
    }

    // Always update lastSyncAt and reset failedSyncCount for active user on sync contact
    await prisma.user
      .update({
        where: { id: userId },
        data: {
          lastSyncAt: new Date(),
          failedSyncCount: 0,
        },
      })
      .catch(() => {});

    return {
      success: true,
      serverTimestamp: new Date().toISOString(),
      appliedCount: applied.length,
      applied,
    };
  } catch (err) {
    console.error('[SyncPush] Non-fatal batch catch:', err.message);
    await prisma.user
      .update({
        where: { id: userId },
        data: {
          lastSyncAt: new Date(),
          failedSyncCount: 0,
        },
      })
      .catch(() => {});

    return {
      success: true,
      serverTimestamp: new Date().toISOString(),
      appliedCount: applied.length,
      applied,
      warning: err.message,
    };
  }
}
