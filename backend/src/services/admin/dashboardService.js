import prisma from '../../config/db.js';
import { countTotalParts, countTotalSales } from './adminStatsService.js';

export async function getDashboardMetrics() {
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  const baseOwnerFilter = { role: 'OWNER', deletedAt: null };

  const [
    totalOwners,
    newOwnersThisWeek,
    activeOwners,
    suspendedOwners,
    inactiveOwners,
    ownersWithSyncProblems,
    versionGroups,
    totalParts,
    totalSales,
  ] = await Promise.all([
    prisma.user.count({ where: baseOwnerFilter }),
    prisma.user.count({
      where: {
        ...baseOwnerFilter,
        createdAt: { gte: sevenDaysAgo },
      },
    }),
    prisma.user.count({
      where: {
        ...baseOwnerFilter,
        status: 'ACTIVE',
        lastSyncAt: { gte: thirtyDaysAgo },
      },
    }),
    prisma.user.count({
      where: {
        ...baseOwnerFilter,
        status: 'SUSPENDED',
      },
    }),
    prisma.user.count({
      where: {
        ...baseOwnerFilter,
        OR: [
          { lastSyncAt: null },
          { lastSyncAt: { lt: thirtyDaysAgo } },
        ],
      },
    }),
    prisma.user.count({
      where: {
        ...baseOwnerFilter,
        OR: [
          { lastSyncAt: null },
          { lastSyncAt: { lt: sevenDaysAgo } },
          { failedSyncCount: { gt: 5 } },
        ],
      },
    }),
    prisma.user.groupBy({
      by: ['appVersion'],
      where: baseOwnerFilter,
      _count: { id: true },
    }),
    countTotalParts(),
    countTotalSales(),
  ]);

  const appVersionDistribution = versionGroups.map((g) => ({
    version: g.appVersion || 'unknown',
    count: g._count.id,
  }));

  return {
    totalOwners,
    newOwnersThisWeek,
    activeOwners,
    suspendedOwners,
    inactiveOwners,
    ownersWithSyncProblems,
    totalParts,
    totalSales,
    appVersionDistribution,
  };
}
