import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, ConflictError } from '../utils/errors.js';

export async function listLocations(ownerId) {
  return prisma.location.findMany({
    where: {
      ownerId, // STRICT: Filtered by authenticated owner
      deletedAt: null,
    },
    orderBy: { name: 'asc' },
  });
}

export async function createLocation(ownerId, { name }) {
  const trimmed = name.trim();

  const existing = await prisma.location.findFirst({
    where: {
      ownerId,
      name: trimmed,
      deletedAt: null,
    },
  });

  if (existing) {
    throw new ConflictError(`Location '${trimmed}' already exists.`);
  }

  return prisma.location.create({
    data: {
      id: uuidv4(),
      ownerId, // STRICT: ALWAYS from verified JWT
      name: trimmed,
    },
  });
}

export async function deleteLocation(ownerId, locationId) {
  const location = await prisma.location.findFirst({
    where: { id: locationId, ownerId, deletedAt: null },
  });

  if (!location) {
    throw new NotFoundError('Location not found');
  }

  await prisma.location.update({
    where: { id: locationId },
    data: { deletedAt: new Date() },
  });

  return { message: 'Location deleted' };
}
