import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { NotFoundError, ConflictError } from '../utils/errors.js';

export async function listCategories(ownerId) {
  return prisma.category.findMany({
    where: {
      ownerId, // STRICT: Tenant isolated
      deletedAt: null,
    },
    orderBy: { name: 'asc' },
  });
}

export async function createCategory(ownerId, { name }) {
  const trimmed = name.trim();

  const existing = await prisma.category.findFirst({
    where: {
      ownerId,
      name: trimmed,
      deletedAt: null,
    },
  });

  if (existing) {
    throw new ConflictError(`Category '${trimmed}' already exists.`);
  }

  return prisma.category.create({
    data: {
      id: uuidv4(),
      ownerId, // STRICT: ALWAYS from verified JWT
      name: trimmed,
    },
  });
}

export async function deleteCategory(ownerId, categoryId) {
  const category = await prisma.category.findFirst({
    where: { id: categoryId, ownerId, deletedAt: null },
  });

  if (!category) {
    throw new NotFoundError('Category not found');
  }

  await prisma.category.update({
    where: { id: categoryId },
    data: { deletedAt: new Date() },
  });

  return { message: 'Category deleted' };
}
