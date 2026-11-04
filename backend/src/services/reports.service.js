import prisma from '../config/db.js';

/**
 * Calculates start and end Date objects in Africa/Addis_Ababa timezone (UTC+3).
 */
export function getDateRange(period = 'today', customStart, customEnd) {
  const now = new Date();
  // Addis Ababa is UTC+3 (180 minutes offset)
  const addisOffsetMs = 3 * 60 * 60 * 1000;
  const localNow = new Date(now.getTime() + addisOffsetMs);

  let start;
  let end;

  switch (period.toLowerCase()) {
    case 'today':
    case 'daily': {
      const year = localNow.getUTCFullYear();
      const month = localNow.getUTCMonth();
      const date = localNow.getUTCDate();
      start = new Date(Date.UTC(year, month, date, 0, 0, 0) - addisOffsetMs);
      end = new Date(Date.UTC(year, month, date, 23, 59, 59, 999) - addisOffsetMs);
      break;
    }
    case 'week':
    case 'thisweek':
    case 'weekly': {
      const year = localNow.getUTCFullYear();
      const month = localNow.getUTCMonth();
      const date = localNow.getUTCDate();
      const day = localNow.getUTCDay(); // 0 is Sunday, 1 is Monday
      const diffToMonday = day === 0 ? -6 : 1 - day;
      start = new Date(Date.UTC(year, month, date + diffToMonday, 0, 0, 0) - addisOffsetMs);
      end = new Date(Date.UTC(year, month, date + diffToMonday + 6, 23, 59, 59, 999) - addisOffsetMs);
      break;
    }
    case 'month':
    case 'thismonth':
    case 'monthly': {
      const year = localNow.getUTCFullYear();
      const month = localNow.getUTCMonth();
      start = new Date(Date.UTC(year, month, 1, 0, 0, 0) - addisOffsetMs);
      // Last day of month
      const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
      end = new Date(Date.UTC(year, month, lastDay, 23, 59, 59, 999) - addisOffsetMs);
      break;
    }
    case 'custom': {
      start = customStart ? new Date(customStart) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      end = customEnd ? new Date(customEnd) : new Date();
      break;
    }
    default: {
      const year = localNow.getUTCFullYear();
      const month = localNow.getUTCMonth();
      const date = localNow.getUTCDate();
      start = new Date(Date.UTC(year, month, date, 0, 0, 0) - addisOffsetMs);
      end = new Date(Date.UTC(year, month, date, 23, 59, 59, 999) - addisOffsetMs);
    }
  }

  return { start, end };
}

/**
 * Generates financial report summary for authenticated owner.
 */
export async function getOwnerReportSummary(ownerId, { period = 'today', startDate, endDate } = {}) {
  const { start, end } = getDateRange(period, startDate, endDate);

  const whereSale = {
    ownerId, // STRICT TENANT ISOLATION
    deletedAt: null,
    soldAt: {
      gte: start,
      lte: end,
    },
  };

  const [sales, saleItems, parts, movements] = await Promise.all([
    prisma.sale.findMany({
      where: whereSale,
      select: {
        id: true,
        totalAmount: true,
        totalProfit: true,
        soldAt: true,
        paymentMethod: true,
      },
    }),
    prisma.saleItem.findMany({
      where: {
        ownerId,
        deletedAt: null,
        sale: {
          deletedAt: null,
          soldAt: {
            gte: start,
            lte: end,
          },
        },
      },
      select: {
        partId: true,
        partNameSnapshot: true,
        quantity: true,
        unitCostSnapshot: true,
        unitPriceSnapshot: true,
        subtotal: true,
        profit: true,
      },
    }),
    prisma.sparePart.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      select: {
        id: true,
        name: true,
        cachedQuantity: true,
        purchasePrice: true,
        sellingPrice: true,
        brand: { select: { id: true, name: true } },
      },
    }),
    prisma.stockMovement.findMany({
      where: {
        ownerId,
        deletedAt: null,
        createdAt: {
          gte: start,
          lte: end,
        },
      },
      take: 20,
      orderBy: { createdAt: 'desc' },
      include: {
        part: { select: { id: true, name: true } },
      },
    }),
  ]);

  let totalRevenue = 0;
  let totalProfit = 0;
  let totalCost = 0;

  for (const item of saleItems) {
    const rev = Number(item.subtotal) || 0;
    const prof = Number(item.profit) || 0;
    const qty = Number(item.quantity) || 0;
    const unitCost = Number(item.unitCostSnapshot) || 0;
    const cost = qty * unitCost;

    totalRevenue += rev;
    totalProfit += prof;
    totalCost += cost;
  }

  // If sales has records but no items details
  if (totalRevenue === 0 && sales.length > 0) {
    for (const s of sales) {
      const rev = Number(s.totalAmount) || 0;
      const prof = Number(s.totalProfit) || 0;
      totalRevenue += rev;
      totalProfit += prof;
    }
    totalCost = Math.max(0, totalRevenue - totalProfit);
  }

  const profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
  const transactionsCount = sales.length;

  // Aggregate top selling parts
  const itemMap = new Map();
  for (const item of saleItems) {
    const key = item.partNameSnapshot;
    const existing = itemMap.get(key) || {
      partName: item.partNameSnapshot,
      partId: item.partId,
      unitsSold: 0,
      totalRevenue: 0,
      totalProfit: 0,
    };
    existing.unitsSold += Number(item.quantity) || 0;
    existing.totalRevenue += Number(item.subtotal) || 0;
    existing.totalProfit += Number(item.profit) || 0;
    itemMap.set(key, existing);
  }

  const topSellingItems = Array.from(itemMap.values())
    .sort((a, b) => b.unitsSold - a.unitsSold)
    .slice(0, 10);

  // Inventory valuation & stock levels
  let totalStockValue = 0;
  let lowStockCount = 0;
  let outOfStockCount = 0;
  const brandStockCount = new Map();

  for (const p of parts) {
    const qty = Number(p.cachedQuantity) || 0;
    const buyPrice = Number(p.purchasePrice) || 0;
    totalStockValue += qty * buyPrice;

    if (qty <= 0) {
      outOfStockCount++;
    } else if (qty <= 5) {
      lowStockCount++;
    }

    const brandName = p.brand?.name || 'Other';
    brandStockCount.set(brandName, (brandStockCount.get(brandName) || 0) + 1);
  }

  const brandBreakdown = Array.from(brandStockCount.entries()).map(([brandName, count]) => ({
    brandName,
    count,
    percentage: parts.length > 0 ? Number(((count / parts.length) * 100).toFixed(1)) : 0,
  })).sort((a, b) => b.count - a.count).slice(0, 8);

  return {
    period,
    startDate: start.toISOString(),
    endDate: end.toISOString(),
    summary: {
      totalRevenue: Number(totalRevenue.toFixed(2)),
      totalCost: Number(totalCost.toFixed(2)),
      totalProfit: Number(totalProfit.toFixed(2)),
      profitMargin: Number(profitMargin.toFixed(1)),
      transactionsCount,
      averageTicketValue: transactionsCount > 0 ? Number((totalRevenue / transactionsCount).toFixed(2)) : 0,
    },
    inventory: {
      totalPartsCount: parts.length,
      totalStockValue: Number(totalStockValue.toFixed(2)),
      lowStockCount,
      outOfStockCount,
    },
    topSellingItems,
    brandBreakdown,
    recentMovements: movements.map((m) => ({
      id: m.id,
      partName: m.part?.name || 'Unknown',
      movementType: m.movementType,
      quantity: Number(m.quantity),
      reason: m.reason,
      createdAt: m.createdAt,
    })),
  };
}

/**
 * Returns dynamic grouped chart trend points for revenue and profit.
 */
export async function getOwnerReportTrends(ownerId, { period = 'today', startDate, endDate } = {}) {
  const { start, end } = getDateRange(period, startDate, endDate);

  const sales = await prisma.sale.findMany({
    where: {
      ownerId,
      deletedAt: null,
      soldAt: {
        gte: start,
        lte: end,
      },
    },
    select: {
      id: true,
      totalAmount: true,
      totalProfit: true,
      soldAt: true,
    },
    orderBy: { soldAt: 'asc' },
  });

  const points = [];
  const addisOffsetMs = 3 * 60 * 60 * 1000;

  if (period === 'today' || period === 'daily') {
    // 8 3-hour blocks across the day: 00-03, 03-06, 06-09, 09-12, 12-15, 15-18, 18-21, 21-24
    const blocks = [
      { label: '06:00', startH: 6, endH: 9, rev: 0, prof: 0 },
      { label: '09:00', startH: 9, endH: 12, rev: 0, prof: 0 },
      { label: '12:00', startH: 12, endH: 15, rev: 0, prof: 0 },
      { label: '15:00', startH: 15, endH: 18, rev: 0, prof: 0 },
      { label: '18:00', startH: 18, endH: 21, rev: 0, prof: 0 },
      { label: '21:00', startH: 21, endH: 24, rev: 0, prof: 0 },
    ];

    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const hour = localTime.getUTCHours();
      const rev = Number(s.totalAmount) || 0;
      const prof = Number(s.totalProfit) || 0;

      for (const b of blocks) {
        if (hour >= b.startH && hour < b.endH) {
          b.rev += rev;
          b.prof += prof;
          break;
        }
      }
    }

    for (const b of blocks) {
      points.push({
        label: b.label,
        revenue: Number(b.rev.toFixed(2)),
        profit: Number(b.prof.toFixed(2)),
      });
    }
  } else if (period === 'week' || period === 'thisweek' || period === 'weekly') {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayBuckets = dayLabels.map((l) => ({ label: l, rev: 0, prof: 0 }));

    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const dayIndex = (localTime.getUTCDay() + 6) % 7; // 0=Mon, 6=Sun
      dayBuckets[dayIndex].rev += Number(s.totalAmount) || 0;
      dayBuckets[dayIndex].prof += Number(s.totalProfit) || 0;
    }

    for (const b of dayBuckets) {
      points.push({
        label: b.label,
        revenue: Number(b.rev.toFixed(2)),
        profit: Number(b.prof.toFixed(2)),
      });
    }
  } else {
    // Monthly: 4-5 weeks
    const weeks = [
      { label: 'W1', rev: 0, prof: 0 },
      { label: 'W2', rev: 0, prof: 0 },
      { label: 'W3', rev: 0, prof: 0 },
      { label: 'W4', rev: 0, prof: 0 },
      { label: 'W5', rev: 0, prof: 0 },
    ];

    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const date = localTime.getUTCDate();
      const weekIdx = Math.min(4, Math.floor((date - 1) / 7));
      weeks[weekIdx].rev += Number(s.totalAmount) || 0;
      weeks[weekIdx].prof += Number(s.totalProfit) || 0;
    }

    for (const w of weeks) {
      points.push({
        label: w.label,
        revenue: Number(w.rev.toFixed(2)),
        profit: Number(w.prof.toFixed(2)),
      });
    }
  }

  return {
    period,
    points,
  };
}

/**
 * Aggregated platform reports for Admin.
 */
export async function getAdminReportsSummary({ period = 'month' } = {}) {
  const { start, end } = getDateRange(period);

  const [sales, ownersCount, partsCount, topItems] = await Promise.all([
    prisma.sale.findMany({
      where: {
        deletedAt: null,
        soldAt: {
          gte: start,
          lte: end,
        },
      },
      select: {
        id: true,
        totalAmount: true,
        totalProfit: true,
        soldAt: true,
      },
      orderBy: { soldAt: 'asc' },
    }),
    prisma.user.count({
      where: { role: 'OWNER', deletedAt: null },
    }),
    prisma.sparePart.count({
      where: { deletedAt: null },
    }),
    prisma.saleItem.groupBy({
      by: ['partId'],
      where: {
        deletedAt: null,
        sale: {
          deletedAt: null,
          soldAt: { gte: start, lte: end },
        },
      },
      _sum: { quantity: true, subtotal: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: 5,
    }),
  ]);

  let totalRevenue = 0;
  let totalProfit = 0;
  for (const s of sales) {
    totalRevenue += Number(s.totalAmount) || 0;
    totalProfit += Number(s.totalProfit) || 0;
  }

  // Calculate points
  const points = [];
  const addisOffsetMs = 3 * 60 * 60 * 1000;
  if (period === 'today' || period === 'daily') {
    const blocks = [
      { label: '06:00', startH: 6, endH: 9, rev: 0, prof: 0 },
      { label: '09:00', startH: 9, endH: 12, rev: 0, prof: 0 },
      { label: '12:00', startH: 12, endH: 15, rev: 0, prof: 0 },
      { label: '15:00', startH: 15, endH: 18, rev: 0, prof: 0 },
      { label: '18:00', startH: 18, endH: 21, rev: 0, prof: 0 },
      { label: '21:00', startH: 21, endH: 24, rev: 0, prof: 0 },
    ];
    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const hour = localTime.getUTCHours();
      const rev = Number(s.totalAmount) || 0;
      const prof = Number(s.totalProfit) || 0;
      for (const b of blocks) {
        if (hour >= b.startH && hour < b.endH) {
          b.rev += rev;
          b.prof += prof;
          break;
        }
      }
    }
    for (const b of blocks) {
      points.push({
        label: b.label,
        revenue: Number(b.rev.toFixed(2)),
        profit: Number(b.prof.toFixed(2)),
      });
    }
  } else if (period === 'week' || period === 'thisweek' || period === 'weekly') {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayBuckets = dayLabels.map((l) => ({ label: l, rev: 0, prof: 0 }));
    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const dayIndex = (localTime.getUTCDay() + 6) % 7;
      dayBuckets[dayIndex].rev += Number(s.totalAmount) || 0;
      dayBuckets[dayIndex].prof += Number(s.totalProfit) || 0;
    }
    for (const b of dayBuckets) {
      points.push({
        label: b.label,
        revenue: Number(b.rev.toFixed(2)),
        profit: Number(b.prof.toFixed(2)),
      });
    }
  } else {
    const weeks = [
      { label: 'W1', rev: 0, prof: 0 },
      { label: 'W2', rev: 0, prof: 0 },
      { label: 'W3', rev: 0, prof: 0 },
      { label: 'W4', rev: 0, prof: 0 },
      { label: 'W5', rev: 0, prof: 0 },
    ];
    for (const s of sales) {
      const localTime = new Date(s.soldAt.getTime() + addisOffsetMs);
      const date = localTime.getUTCDate();
      const weekIdx = Math.min(4, Math.floor((date - 1) / 7));
      weeks[weekIdx].rev += Number(s.totalAmount) || 0;
      weeks[weekIdx].prof += Number(s.totalProfit) || 0;
    }
    for (const w of weeks) {
      points.push({
        label: w.label,
        revenue: Number(w.rev.toFixed(2)),
        profit: Number(w.prof.toFixed(2)),
      });
    }
  }

  // Top selling parts
  const partIds = topItems.map((i) => i.partId).filter(Boolean);
  const partMap = {};
  if (partIds.length > 0) {
    const parts = await prisma.sparePart.findMany({
      where: { id: { in: partIds } },
      select: { id: true, nameAm: true, nameEn: true, brand: true },
    });
    parts.forEach((p) => { partMap[p.id] = p; });
  }

  const topSellingItems = topItems.map((item) => {
    const p = partMap[item.partId];
    return {
      partId: item.partId,
      name: p ? `${p.nameEn || p.nameAm || 'Part'} · ${p.brand || ''}` : 'Spare Part',
      units: Number(item._sum.quantity || 0),
      totalAmount: Number(item._sum.subtotal || 0),
    };
  });

  return {
    period,
    totalRevenue: Number(totalRevenue.toFixed(2)),
    totalProfit: Number(totalProfit.toFixed(2)),
    transactionsCount: sales.length,
    activeOwnersCount: ownersCount,
    totalPartsCount: partsCount,
    points,
    topSellingItems,
  };
}
