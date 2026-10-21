import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, BadRequestError } from '../utils/errors.js';

export async function addStockMovement(ownerId, { partId, movementType, quantity, unitCost, reason, referenceId }) {
  // Verify part ownership
  const part = await prisma.sparePart.findFirst({
    where: { id: partId, ownerId, deletedAt: null },
  });

  if (!part) {
    throw new NotFoundError('Spare part not found');
  }

  const numQty = Number(quantity);
  if (isNaN(numQty) || numQty <= 0) {
    throw new BadRequestError('Quantity must be a positive number');
  }

  // Calculate delta based on movement type
  let delta = 0;
  if (movementType === 'PURCHASE' || movementType === 'ADJUSTMENT_IN' || movementType === 'RETURN') {
    delta = numQty;
  } else if (movementType === 'SALE' || movementType === 'ADJUSTMENT_OUT') {
    delta = -numQty;
  } else {
    throw new BadRequestError(`Invalid movement type: ${movementType}`);
  }

  const currentCached = Number(part.cachedQuantity || 0);
  const newCached = currentCached + delta;

  // Execute in atomic transaction
  return prisma.$transaction(async (tx) => {
    const movement = await tx.stockMovement.create({
      data: {
        id: uuidv4(),
        ownerId, // STRICT: ALWAYS from verified JWT
        partId,
        movementType,
        quantity: numQty,
        unitCost: unitCost != null ? Number(unitCost) : null,
        reason: reason || null,
        referenceId: referenceId || null,
      },
    });

    await tx.sparePart.update({
      where: { id: partId },
      data: { cachedQuantity: newCached },
    });

    return { movement, newCachedQuantity: newCached };
  });
}

export async function listStockMovements(ownerId, { partId, limit = 50, offset = 0 } = {}) {
  const where = {
    ownerId, // STRICT: Filtered by owner
    deletedAt: null,
  };

  if (partId) {
    where.partId = partId;
  }

  const [total, movements] = await Promise.all([
    prisma.stockMovement.count({ where }),
    prisma.stockMovement.findMany({
      where,
      include: {
        part: { select: { id: true, name: true, partNumber: true, unit: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: Number(limit),
      skip: Number(offset),
    }),
  ]);

  return { total, movements };
}
