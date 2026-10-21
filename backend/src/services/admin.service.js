import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, BadRequestError, ConflictError } from '../utils/errors.js';

export async function listAllUsers({ limit = 50, offset = 0 } = {}) {
  const [total, users] = await Promise.all([
    prisma.user.count({ where: { deletedAt: null } }),
    prisma.user.findMany({
      where: { deletedAt: null },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        role: true,
        status: true,
        language: true,
        createdAt: true,
        _count: {
          select: {
            spareParts: { where: { deletedAt: null } },
            sales: { where: { deletedAt: null } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: Number(limit),
      skip: Number(offset),
    }),
  ]);

  return { total, users };
}

export async function updateUserStatus(userId, { status }) {
  if (!['ACTIVE', 'SUSPENDED'].includes(status)) {
    throw new BadRequestError("Invalid status. Must be 'ACTIVE' or 'SUSPENDED'.");
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  if (user.role === 'ADMIN') {
    throw new BadRequestError('Cannot change status of an Administrator account');
  }

  return prisma.user.update({
    where: { id: userId },
    data: { status },
    select: {
      id: true,
      phoneNumber: true,
      businessName: true,
      role: true,
      status: true,
    },
  });
}

export async function createGlobalBrand({ name }) {
  const trimmed = name.trim();

  const existing = await prisma.brand.findFirst({
    where: { name: trimmed, isGlobal: true, deletedAt: null },
  });

  if (existing) {
    throw new ConflictError(`Global brand '${trimmed}' already exists.`);
  }

  return prisma.brand.create({
    data: {
      id: uuidv4(),
      ownerId: null, // Global brand
      name: trimmed,
      isGlobal: true,
    },
  });
}

export async function getSystemStats() {
  const [totalOwners, totalParts, totalSales, totalStockMovements] = await Promise.all([
    prisma.user.count({ where: { role: 'OWNER', deletedAt: null } }),
    prisma.sparePart.count({ where: { deletedAt: null } }),
    prisma.sale.count({ where: { deletedAt: null } }),
    prisma.stockMovement.count({ where: { deletedAt: null } }),
  ]);

  return {
    totalOwners,
    totalParts,
    totalSales,
    totalStockMovements,
  };
}
