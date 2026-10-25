import prisma from '../../config/db.js';

export async function listAuditLogs({
  page = 1,
  limit = 50,
  adminId,
  targetUserId,
  action,
  startDate,
  endDate,
} = {}) {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
  const skip = (pageNum - 1) * limitNum;

  const where = {};

  if (adminId) where.adminId = adminId;
  if (targetUserId) where.targetUserId = targetUserId;
  if (action) where.action = action;

  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt.gte = new Date(startDate);
    if (endDate) where.createdAt.lte = new Date(endDate);
  }

  const [total, logs] = await Promise.all([
    prisma.auditLog.count({ where }),
    prisma.auditLog.findMany({
      where,
      include: {
        admin: {
          select: {
            id: true,
            businessName: true,
            phoneNumber: true,
          },
        },
        targetUser: {
          select: {
            id: true,
            businessName: true,
            phoneNumber: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limitNum,
      skip,
    }),
  ]);

  return {
    logs,
    meta: {
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
    },
  };
}
