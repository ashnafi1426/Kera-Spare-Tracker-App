import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, BadRequestError } from '../utils/errors.js';

export async function recordSale(ownerId, saleData) {
  const { receiptNumber, paymentMethod = 'CASH', customerName, customerPhone, notes, soldAt, items } = saleData;

  if (!items || items.length === 0) {
    throw new BadRequestError('A sale must have at least one line item');
  }

  // Pre-calculate line totals and profits
  let totalAmount = 0;
  let totalProfit = 0;

  const processedItems = items.map((item) => {
    const qty = Number(item.quantity);
    const unitCost = Number(item.unitCostSnapshot || 0);
    const unitPrice = Number(item.unitPriceSnapshot || 0);
    const subtotal = qty * unitPrice;
    const profit = qty * (unitPrice - unitCost);

    totalAmount += subtotal;
    totalProfit += profit;

    return {
      id: item.id || uuidv4(),
      ownerId, // STRICT: from verified JWT
      partId: item.partId || null,
      partNameSnapshot: item.partNameSnapshot,
      quantity: qty,
      unitCostSnapshot: unitCost,
      unitPriceSnapshot: unitPrice,
      subtotal,
      profit,
    };
  });

  const saleId = saleData.id || uuidv4();
  const saleTimestamp = soldAt ? new Date(soldAt) : new Date();

  // Execute entire sale and inventory deduction inside an ACID transaction
  return prisma.$transaction(async (tx) => {
    const sale = await tx.sale.create({
      data: {
        id: saleId,
        ownerId, // STRICT: ALWAYS from verified JWT
        receiptNumber,
        totalAmount,
        totalProfit,
        paymentMethod,
        customerName: customerName || null,
        customerPhone: customerPhone || null,
        notes: notes || null,
        soldAt: saleTimestamp,
        items: {
          create: processedItems,
        },
      },
      include: {
        items: true,
      },
    });

    // Auto deduct stock & record ledger movements for items linked to a partId
    for (const item of processedItems) {
      if (item.partId) {
        // Verify owner owns this part
        const part = await tx.sparePart.findFirst({
          where: { id: item.partId, ownerId, deletedAt: null },
        });

        if (part) {
          // Record ledger movement
          await tx.stockMovement.create({
            data: {
              id: uuidv4(),
              ownerId,
              partId: item.partId,
              movementType: 'SALE',
              quantity: item.quantity,
              unitCost: item.unitCostSnapshot,
              reason: `Sale ${receiptNumber}`,
              referenceId: saleId,
            },
          });

          // Atomically adjust cachedQuantity
          const currentCached = Number(part.cachedQuantity || 0);
          await tx.sparePart.update({
            where: { id: item.partId },
            data: { cachedQuantity: currentCached - item.quantity },
          });
        }
      }
    }

    return sale;
  });
}

export async function listSales(ownerId, { startDate, endDate, limit = 50, offset = 0 } = {}) {
  const where = {
    ownerId, // STRICT: Filtered by authenticated owner
    deletedAt: null,
  };

  if (startDate || endDate) {
    where.soldAt = {};
    if (startDate) where.soldAt.gte = new Date(startDate);
    if (endDate) where.soldAt.lte = new Date(endDate);
  }

  const [total, sales] = await Promise.all([
    prisma.sale.count({ where }),
    prisma.sale.findMany({
      where,
      include: {
        items: true,
      },
      orderBy: { soldAt: 'desc' },
      take: Number(limit),
      skip: Number(offset),
    }),
  ]);

  return { total, sales };
}

export async function getSaleById(ownerId, saleId) {
  const sale = await prisma.sale.findFirst({
    where: {
      id: saleId,
      ownerId, // STRICT: Must match authenticated owner
      deletedAt: null,
    },
    include: {
      items: true,
    },
  });

  if (!sale) {
    throw new NotFoundError('Sale not found');
  }

  return sale;
}
