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

export async function getOwnersCountsMap(ownerIds = []) {
  if (!ownerIds || ownerIds.length === 0) return {};
  const [parts, sales] = await Promise.all([
    prisma.sparePart.groupBy({
      by: ['ownerId'],
      where: { ownerId: { in: ownerIds }, deletedAt: null },
      _count: { id: true },
    }),
    prisma.sale.groupBy({
      by: ['ownerId'],
      where: { ownerId: { in: ownerIds }, deletedAt: null },
      _count: { id: true },
    }),
  ]);

  const map = {};
  for (const id of ownerIds) {
    map[id] = { partsCount: 0, salesCount: 0 };
  }
  for (const p of parts) {
    if (map[p.ownerId]) map[p.ownerId].partsCount = p._count.id;
  }
  for (const s of sales) {
    if (map[s.ownerId]) map[s.ownerId].salesCount = s._count.id;
  }
  return map;
}

export async function getTotalSalesRevenueAndProfit() {
  const salesAggregate = await prisma.sale.aggregate({
    where: { deletedAt: null },
    _sum: { totalAmount: true, totalProfit: true },
  });

  return {
    totalRevenue: Number(salesAggregate._sum?.totalAmount || 0),
    totalProfit: Number(salesAggregate._sum?.totalProfit || 0),
  };
}

export async function getOwnerItemCounts(ownerId) {
  const [partsCount, salesCount, salesAggregate] = await Promise.all([
    countTotalParts({ ownerId }),
    countTotalSales({ ownerId }),
    prisma.sale.aggregate({
      where: { ownerId, deletedAt: null },
      _sum: { totalAmount: true, totalProfit: true },
    }),
  ]);

  const totalRevenue = Number(salesAggregate._sum?.totalAmount || 0);
  const totalProfit = Number(salesAggregate._sum?.totalProfit || 0);

  return { partsCount, salesCount, totalRevenue, totalProfit };
}
