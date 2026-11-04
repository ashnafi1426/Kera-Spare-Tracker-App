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
  await prisma.user.update({
    where: { id: userId },
    data: {
      lastSyncAt: new Date(),
      failedSyncCount: 0,
    },
  });

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

/**
 * Sync Push Service
 * Processes mutations queued on device.
 * On success, resets failedSyncCount to 0 and updates lastSyncAt.
 * On failure, increments failedSyncCount.
 */
export async function pushSyncData(userId, batch = []) {
  try {
    const applied = [];

    await prisma.$transaction(async (tx) => {
      for (const item of batch) {
        const entity = (item.entity || '').toLowerCase().replace(/_/g, '');
        const action = (item.action || '').toLowerCase();
        const data = item.data || {};
        const recordId = item.id || data.id;

        if (!recordId) continue;

        if (entity === 'spareparts' || entity === 'sparepart' || entity === 'parts' || entity === 'part') {
          if (action === 'delete') {
            await tx.sparePart.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const partPayload = {
              name: data.name || 'Unnamed Part',
              partNumber: data.partNumber ?? data.part_number ?? null,
              photoUrl: data.photoUrl ?? data.photo_url ?? null,
              brandId: data.brandId ?? data.brand_id ?? null,
              categoryId: data.categoryId ?? data.category_id ?? null,
              locationId: data.locationId ?? data.location_id ?? null,
              customLocation: data.customLocation ?? data.custom_location ?? null,
              description: data.description ?? null,
              unit: data.unit ?? null,
              cachedQuantity: data.quantity !== undefined ? data.quantity : (data.cachedQuantity ?? data.cached_quantity ?? 0),
              purchasePrice: data.purchasePrice !== undefined ? data.purchasePrice : (data.purchase_price ?? null),
              sellingPrice: data.sellingPrice !== undefined ? data.sellingPrice : (data.selling_price ?? null),
              notes: data.notes ?? null,
              sizeSpecs: data.sizeSpecs ?? data.size_specs ?? null,
              isDemo: Boolean(data.isDemo ?? data.is_demo ?? (typeof data.notes === 'string' && data.notes.includes('[DEMO]')) ?? false),
              deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
            };

            await tx.sparePart.upsert({
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
                createdAt: data.createdAt ? new Date(data.createdAt) : new Date(),
                updatedAt: new Date(),
              },
            });
          }
          applied.push({ id: recordId, entity: 'spare_parts', status: 'applied' });
        } else if (entity === 'sales' || entity === 'sale') {
          if (action === 'delete') {
            await tx.sale.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            const salePayload = {
              receiptNumber: data.receiptNumber ?? data.receipt_number ?? `REC-${Date.now()}`,
              totalAmount: data.totalAmount ?? data.total_amount ?? 0,
              totalProfit: data.totalProfit ?? data.total_profit ?? 0,
              paymentMethod: data.paymentMethod ?? data.payment_method ?? 'CASH',
              customerName: data.customerName ?? data.customer_name ?? null,
              customerPhone: data.customerPhone ?? data.customer_phone ?? null,
              notes: data.notes ?? null,
              soldAt: data.soldAt ? new Date(data.soldAt) : (data.sold_at ? new Date(data.sold_at) : new Date()),
              deletedAt: data.deletedAt ? new Date(data.deletedAt) : null,
            };

            await tx.sale.upsert({
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
                createdAt: data.createdAt ? new Date(data.createdAt) : new Date(),
                updatedAt: new Date(),
              },
            });

            // If sale items are bundled in data.items
            if (Array.isArray(data.items)) {
              for (const itemRow of data.items) {
                const itemId = itemRow.id || `${recordId}_${itemRow.partId}`;
                await tx.saleItem.upsert({
                  where: { id: itemId },
                  update: {
                    ownerId: userId,
                    saleId: recordId,
                    partId: itemRow.partId ?? itemRow.part_id ?? null,
                    partNameSnapshot: itemRow.partNameSnapshot ?? itemRow.part_name_snapshot ?? 'Item',
                    quantity: itemRow.quantity ?? 1,
                    unitCostSnapshot: itemRow.unitCostSnapshot ?? itemRow.unit_cost_snapshot ?? 0,
                    unitPriceSnapshot: itemRow.unitPriceSnapshot ?? itemRow.unit_price_snapshot ?? 0,
                    subtotal: itemRow.subtotal ?? 0,
                    profit: itemRow.profit ?? 0,
                    updatedAt: new Date(),
                  },
                  create: {
                    id: itemId,
                    ownerId: userId,
                    saleId: recordId,
                    partId: itemRow.partId ?? itemRow.part_id ?? null,
                    partNameSnapshot: itemRow.partNameSnapshot ?? itemRow.part_name_snapshot ?? 'Item',
                    quantity: itemRow.quantity ?? 1,
                    unitCostSnapshot: itemRow.unitCostSnapshot ?? itemRow.unit_cost_snapshot ?? 0,
                    unitPriceSnapshot: itemRow.unitPriceSnapshot ?? itemRow.unit_price_snapshot ?? 0,
                    subtotal: itemRow.subtotal ?? 0,
                    profit: itemRow.profit ?? 0,
                  },
                });
              }
            }
          }
          applied.push({ id: recordId, entity: 'sales', status: 'applied' });
        } else if (entity === 'stockmovements' || entity === 'stockmovement') {
          if (action === 'delete') {
            await tx.stockMovement.updateMany({
              where: { id: recordId, ownerId: userId },
              data: { deletedAt: new Date() },
            });
          } else {
            await tx.stockMovement.upsert({
              where: { id: recordId },
              update: {
                ownerId: userId,
                partId: data.partId ?? data.part_id,
                movementType: data.movementType ?? data.movement_type ?? 'ADJUSTMENT_IN',
                quantity: data.quantity ?? 0,
                unitCost: data.unitCost ?? data.unit_cost ?? null,
                reason: data.reason ?? null,
                referenceId: data.referenceId ?? data.reference_id ?? null,
                updatedAt: new Date(),
              },
              create: {
                id: recordId,
                ownerId: userId,
                partId: data.partId ?? data.part_id,
                movementType: data.movementType ?? data.movement_type ?? 'ADJUSTMENT_IN',
                quantity: data.quantity ?? 0,
                unitCost: data.unitCost ?? data.unit_cost ?? null,
                reason: data.reason ?? null,
                referenceId: data.referenceId ?? data.reference_id ?? null,
              },
            });
          }
          applied.push({ id: recordId, entity: 'stock_movements', status: 'applied' });
        } else {
          applied.push({ id: recordId, status: 'acknowledged' });
        }
      }

      await tx.user.update({
        where: { id: userId },
        data: {
          lastSyncAt: new Date(),
          failedSyncCount: 0,
        },
      });
    });

    return {
      success: true,
      serverTimestamp: new Date().toISOString(),
      appliedCount: applied.length,
    };
  } catch (err) {
    // Record failed sync attempt
    await prisma.user
      .update({
        where: { id: userId },
        data: {
          failedSyncCount: { increment: 1 },
        },
      })
      .catch(() => {});

    throw err;
  }
}
