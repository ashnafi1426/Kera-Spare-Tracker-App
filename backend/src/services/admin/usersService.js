import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import prisma from '../../config/db.js';
import { NotFoundError, BadRequestError, ConflictError } from '../../utils/errors.js';
import { getOwnerItemCounts } from './adminStatsService.js';
import * as auditLogService from './auditLogService.js';

/**
 * Generate a cryptographically strong temporary password.
 */
function generateTemporaryPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%&*';
  let password = 'Temp#';
  const bytes = crypto.randomBytes(8);
  for (let i = 0; i < 8; i++) {
    password += chars[bytes[i] % chars.length];
  }
  return password + '!9';
}

export async function listUsers({
  page = 1,
  limit = 20,
  search,
  status,
  inactive,
  sortBy = 'createdAt',
  sortOrder = 'desc',
} = {}) {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const skip = (pageNum - 1) * limitNum;

  const where = {
    role: 'OWNER',
    deletedAt: null,
  };

  if (status && ['ACTIVE', 'SUSPENDED'].includes(status.toUpperCase())) {
    where.status = status.toUpperCase();
  }

  if (search && String(search).trim()) {
    const term = String(search).trim();
    where.OR = [
      { phoneNumber: { contains: term } },
      { businessName: { contains: term } },
    ];
  }

  if (inactive) {
    const days = parseInt(inactive, 10) || 30;
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    where.AND = [
      {
        OR: [
          { lastSyncAt: null },
          { lastSyncAt: { lt: cutoff } },
        ],
      },
    ];
  }

  const validSortFields = ['createdAt', 'lastSyncAt', 'businessName'];
  const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
  const orderDirection = sortOrder?.toLowerCase() === 'asc' ? 'asc' : 'desc';

  const [total, users] = await Promise.all([
    prisma.user.count({ where }),
    prisma.user.findMany({
      where,
      select: {
        id: true,
        businessName: true,
        phoneNumber: true,
        role: true,
        status: true,
        language: true,
        createdAt: true,
        lastLoginAt: true,
        lastSyncAt: true,
        failedSyncCount: true,
        appVersion: true,
        disabledAt: true,
        suspendedAt: true,
        suspendedReason: true,
      },
      orderBy: { [sortField]: orderDirection },
      take: limitNum,
      skip,
    }),
  ]);

  const formattedUsers = users.map((u) => ({
    ...u,
    phone: u.phoneNumber,
    plan: null,
    expiry: null,
  }));

  return {
    users: formattedUsers,
    meta: {
      total,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil(total / limitNum),
    },
  };
}

export async function getUserById(id) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      phoneNumber: true,
      businessName: true,
      role: true,
      status: true,
      language: true,
      lastLoginAt: true,
      lastSyncAt: true,
      failedSyncCount: true,
      appVersion: true,
      mustChangePassword: true,
      disabledAt: true,
      suspendedReason: true,
      suspendedAt: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user || user.role !== 'OWNER') {
    throw new NotFoundError('Owner account not found');
  }

  const [counts, recentAuditLogs] = await Promise.all([
    getOwnerItemCounts(id),
    prisma.auditLog.findMany({
      where: { targetUserId: id },
      orderBy: { createdAt: 'desc' },
      take: 20,
    }),
  ]);

  return {
    user: {
      ...user,
      phone: user.phoneNumber,
      plan: null,
      expiry: null,
    },
    counts,
    recentAuditLogs,
  };
}

export async function suspendUser(id, { reason }, adminId, req) {
  if (!reason || !String(reason).trim()) {
    throw new BadRequestError('Reason is required to suspend an owner account');
  }

  const target = await prisma.user.findUnique({ where: { id } });
  if (!target) throw new NotFoundError('User not found');
  if (target.role === 'ADMIN') throw new BadRequestError('Cannot suspend an Administrator account');

  const oldState = {
    status: target.status,
    suspendedReason: target.suspendedReason,
    suspendedAt: target.suspendedAt,
  };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.user.update({
      where: { id },
      data: {
        status: 'SUSPENDED',
        suspendedReason: reason.trim(),
        suspendedAt: new Date(),
      },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        status: true,
        suspendedReason: true,
        suspendedAt: true,
      },
    });

    // Revoke all active refresh tokens immediately
    await tx.refreshToken.updateMany({
      where: { userId: id, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      targetUserId: id,
      action: 'USER_SUSPENDED',
      oldValue: oldState,
      newValue: {
        status: updated.status,
        suspendedReason: updated.suspendedReason,
        suspendedAt: updated.suspendedAt,
      },
      reason: reason.trim(),
      req,
    });

    return updated;
  });
}

export async function reactivateUser(id, adminId, req) {
  const target = await prisma.user.findUnique({ where: { id } });
  if (!target) throw new NotFoundError('User not found');

  const oldState = {
    status: target.status,
    suspendedReason: target.suspendedReason,
    suspendedAt: target.suspendedAt,
  };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.user.update({
      where: { id },
      data: {
        status: 'ACTIVE',
        suspendedReason: null,
        suspendedAt: null,
      },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        status: true,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      targetUserId: id,
      action: 'USER_REACTIVATED',
      oldValue: oldState,
      newValue: { status: 'ACTIVE' },
      reason: 'Reactivated by administrator',
      req,
    });

    return updated;
  });
}

export async function updateUser(id, { businessName, phoneNumber }, adminId, req) {
  const target = await prisma.user.findUnique({ where: { id } });
  if (!target) throw new NotFoundError('User not found');
  if (target.role === 'ADMIN') throw new BadRequestError('Cannot modify administrator details here');

  const updates = {};
  if (businessName) updates.businessName = businessName.trim();
  if (phoneNumber && phoneNumber !== target.phoneNumber) {
    const existing = await prisma.user.findUnique({ where: { phoneNumber } });
    if (existing && existing.id !== id) {
      throw new ConflictError('Phone number already in use by another account');
    }
    updates.phoneNumber = phoneNumber;
  }

  if (Object.keys(updates).length === 0) {
    throw new BadRequestError('No valid fields provided for update');
  }

  const oldState = {
    businessName: target.businessName,
    phoneNumber: target.phoneNumber,
  };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.user.update({
      where: { id },
      data: updates,
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        status: true,
        updatedAt: true,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      targetUserId: id,
      action: 'USER_UPDATED',
      oldValue: oldState,
      newValue: updates,
      reason: 'Account profile details updated by administrator',
      req,
    });

    return updated;
  });
}

export async function resetPassword(id, adminId, req) {
  const target = await prisma.user.findUnique({ where: { id } });
  if (!target) throw new NotFoundError('User not found');

  const temporaryPassword = generateTemporaryPassword();
  const passwordHash = await bcrypt.hash(temporaryPassword, 10);

  await prisma.$transaction(async (tx) => {
    await tx.user.update({
      where: { id },
      data: {
        passwordHash,
        mustChangePassword: true,
      },
    });

    // Revoke all refresh tokens
    await tx.refreshToken.updateMany({
      where: { userId: id, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      targetUserId: id,
      action: 'PASSWORD_RESET',
      oldValue: { mustChangePassword: target.mustChangePassword },
      newValue: { mustChangePassword: true },
      reason: 'Temporary password generated by administrator',
      req,
    });
  });

  return { temporaryPassword };
}

export async function softDisableUser(id, { confirm, reason }, adminId, req) {
  const target = await prisma.user.findUnique({ where: { id } });
  if (!target) throw new NotFoundError('User not found');
  if (target.role === 'ADMIN') throw new BadRequestError('Cannot disable an Administrator account');

  if (!confirm || String(confirm).trim() !== target.phoneNumber) {
    throw new BadRequestError(
      'Confirmation failed: the provided phone number does not match the account phone number.'
    );
  }

  const oldState = {
    status: target.status,
    disabledAt: target.disabledAt,
  };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.user.update({
      where: { id },
      data: {
        status: 'SUSPENDED',
        disabledAt: new Date(),
        suspendedReason: reason || 'Account disabled by administrator',
        suspendedAt: new Date(),
      },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        status: true,
        disabledAt: true,
      },
    });

    await tx.refreshToken.updateMany({
      where: { userId: id, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      targetUserId: id,
      action: 'USER_DISABLED',
      oldValue: oldState,
      newValue: {
        status: updated.status,
        disabledAt: updated.disabledAt,
      },
      reason: reason || 'Account disabled with owner phone confirmation',
      req,
    });

    return updated;
  });
}
