import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError } from '../utils/errors.js';

export async function listParts(ownerId, { search, brandId, categoryId, locationId, limit = 50, offset = 0 } = {}) {
  const where = {
    ownerId, // STRICT: Filtered by authenticated owner
    deletedAt: null,
  };

  if (search) {
    where.OR = [
      { name: { contains: search } },
      { partNumber: { contains: search } },
    ];
  }

  if (brandId) where.brandId = brandId;
  if (categoryId) where.categoryId = categoryId;
  if (locationId) where.locationId = locationId;

  const [total, parts] = await Promise.all([
    prisma.sparePart.count({ where }),
    prisma.sparePart.findMany({
      where,
      include: {
        brand: { select: { id: true, name: true, isGlobal: true } },
        category: { select: { id: true, name: true } },
        location: { select: { id: true, name: true } },
      },
      orderBy: { updatedAt: 'desc' },
      take: Number(limit),
      skip: Number(offset),
    }),
  ]);

  return { total, parts };
}

export async function getPartById(ownerId, partId) {
  const part = await prisma.sparePart.findFirst({
    where: {
      id: partId,
      ownerId, // STRICT: Must match authenticated owner
      deletedAt: null,
    },
    include: {
      brand: { select: { id: true, name: true, isGlobal: true } },
      category: { select: { id: true, name: true } },
      location: { select: { id: true, name: true } },
    },
  });

  if (!part) {
    throw new NotFoundError('Spare part not found');
  }

  return part;
}

export async function createPart(ownerId, data) {
  const partId = data.id || uuidv4();

  const part = await prisma.sparePart.create({
    data: {
      id: partId,
      ownerId, // STRICT: ALWAYS set from verified JWT
      name: data.name,
      partNumber: data.partNumber || null,
      photoUrl: data.photoUrl || null,
      brandId: data.brandId || null,
      categoryId: data.categoryId || null,
      locationId: data.locationId || null,
      customLocation: data.customLocation || null,
      description: data.description || null,
      unit: data.unit || 'pcs',
      cachedQuantity: data.cachedQuantity ?? 0,
      purchasePrice: data.purchasePrice != null ? data.purchasePrice : null,
      sellingPrice: data.sellingPrice != null ? data.sellingPrice : null,
      notes: data.notes || null,
      sizeSpecs: data.sizeSpecs || null,
    },
    include: {
      brand: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
      location: { select: { id: true, name: true } },
    },
  });

  return part;
}

export async function updatePart(ownerId, partId, data) {
  // First ensure part belongs to this owner
  await getPartById(ownerId, partId);

  const updated = await prisma.sparePart.update({
    where: { id: partId },
    data: {
      ...(data.name && { name: data.name }),
      ...(data.partNumber !== undefined && { partNumber: data.partNumber }),
      ...(data.brandId !== undefined && { brandId: data.brandId }),
      ...(data.categoryId !== undefined && { categoryId: data.categoryId }),
      ...(data.locationId !== undefined && { locationId: data.locationId }),
      ...(data.customLocation !== undefined && { customLocation: data.customLocation }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.unit !== undefined && { unit: data.unit }),
      ...(data.purchasePrice !== undefined && { purchasePrice: data.purchasePrice }),
      ...(data.sellingPrice !== undefined && { sellingPrice: data.sellingPrice }),
      ...(data.notes !== undefined && { notes: data.notes }),
      ...(data.sizeSpecs !== undefined && { sizeSpecs: data.sizeSpecs }),
    },
    include: {
      brand: { select: { id: true, name: true } },
      category: { select: { id: true, name: true } },
      location: { select: { id: true, name: true } },
    },
  });

  return updated;
}

export async function deletePart(ownerId, partId) {
  // Ensure ownership before soft delete
  await getPartById(ownerId, partId);

  await prisma.sparePart.update({
    where: { id: partId },
    data: { deletedAt: new Date() },
  });

  return { message: 'Part deleted successfully' };
}

export async function updatePartPhoto(ownerId, partId, filename) {
  await getPartById(ownerId, partId);

  const photoUrl = `/api/v1/parts/${partId}/photo`;
  return prisma.sparePart.update({
    where: { id: partId },
    data: { photoUrl: filename },
  });
}
