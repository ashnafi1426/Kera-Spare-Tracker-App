import prisma from '../../config/db.js';

/**
 * Isolated service providing ONLY aggregated COUNTS for administrative telemetry.
 *
 * CRITICAL SEPARATION RULE:
 * This is the ONLY file in the admin module allowed to touch SparePart, StockMovement,
 * Sale, or SaleItem. It NEVER returns rows of data, prices, profit, or descriptions.
 */

export async function countTotalParts(filter = {}) {
  const where = { deletedAt: null };
  if (filter.ownerId) {
    where.ownerId = filter.ownerId;
  }
  return prisma.sparePart.count({ where });
}

export async function countTotalSales(filter = {}) {
  const where = { deletedAt: null };
  if (filter.ownerId) {
    where.ownerId = filter.ownerId;
  }
  return prisma.sale.count({ where });
}

export async function countTotalStockMovements(filter = {}) {
  const where = { deletedAt: null };
  if (filter.ownerId) {
    where.ownerId = filter.ownerId;
  }
  return prisma.stockMovement.count({ where });
}

export async function getOwnerItemCounts(ownerId) {
  const [partsCount, salesCount] = await Promise.all([
    countTotalParts({ ownerId }),
    countTotalSales({ ownerId }),
  ]);

  return { partsCount, salesCount };
}
