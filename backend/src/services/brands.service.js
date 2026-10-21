import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, ForbiddenError, ConflictError } from '../utils/errors.js';

export async function listBrands(ownerId) {
  // Global brands (ownerId: null) + Owner's custom brands
  const brands = await prisma.brand.findMany({
    where: {
      deletedAt: null,
      OR: [
        { isGlobal: true, ownerId: null },
        { ownerId },
      ],
    },
    orderBy: [{ isGlobal: 'desc' }, { name: 'asc' }],
  });

  return brands;
}

export async function createCustomBrand(ownerId, { name }) {
  const trimmed = name.trim();

  // Check duplicate
  const existing = await prisma.brand.findFirst({
    where: {
      name: trimmed,
      deletedAt: null,
      OR: [{ isGlobal: true }, { ownerId }],
    },
  });

  if (existing) {
    throw new ConflictError(`Brand '${trimmed}' already exists.`);
  }

  return prisma.brand.create({
    data: {
      id: uuidv4(),
      ownerId, // STRICT: linked to authenticated owner
      name: trimmed,
      isGlobal: false,
    },
  });
}

export async function deleteCustomBrand(ownerId, brandId) {
  const brand = await prisma.brand.findFirst({
    where: { id: brandId, deletedAt: null },
  });

  if (!brand) {
    throw new NotFoundError('Brand not found');
  }

  if (brand.isGlobal || brand.ownerId !== ownerId) {
    throw new ForbiddenError('You can only delete your own custom brands');
  }

  await prisma.brand.update({
    where: { id: brandId },
    data: { deletedAt: new Date() },
  });

  return { message: 'Custom brand deleted' };
}
