import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/db.js';
import { NotFoundError, ConflictError, BadRequestError } from '../../utils/errors.js';
import * as auditLogService from './auditLogService.js';

// ==========================================
// 1. GLOBAL BRANDS
// ==========================================

export async function listGlobalBrands() {
  return prisma.brand.findMany({
    where: { isGlobal: true, deletedAt: null },
    orderBy: { name: 'asc' },
  });
}

export async function createGlobalBrand({ name }, adminId, req) {
  const trimmed = name?.trim();
  if (!trimmed) throw new BadRequestError('Brand name is required');

  const existing = await prisma.brand.findFirst({
    where: { name: trimmed, isGlobal: true, deletedAt: null },
  });
  if (existing) {
    throw new ConflictError(`Global brand '${trimmed}' already exists.`);
  }

  return prisma.$transaction(async (tx) => {
    const brand = await tx.brand.create({
      data: {
        id: uuidv4(),
        ownerId: null,
        name: trimmed,
        isGlobal: true,
        isActive: true,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'BRAND_CREATED',
      newValue: { id: brand.id, name: brand.name },
      reason: `Global brand '${trimmed}' created`,
      req,
    });

    return brand;
  });
}

export async function updateGlobalBrand(id, { name, isActive }, adminId, req) {
  const brand = await prisma.brand.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!brand) throw new NotFoundError('Global brand not found');

  const updates = {};
  if (name !== undefined) {
    const trimmed = name.trim();
    if (!trimmed) throw new BadRequestError('Brand name cannot be empty');
    const existing = await prisma.brand.findFirst({
      where: { name: trimmed, isGlobal: true, deletedAt: null, NOT: { id } },
    });
    if (existing) throw new ConflictError(`Global brand '${trimmed}' already exists.`);
    updates.name = trimmed;
  }
  if (isActive !== undefined) {
    updates.isActive = Boolean(isActive);
  }

  const oldState = { name: brand.name, isActive: brand.isActive };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.brand.update({
      where: { id },
      data: updates,
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'BRAND_UPDATED',
      oldValue: oldState,
      newValue: updates,
      reason: `Global brand updated`,
      req,
    });

    return updated;
  });
}

export async function deactivateGlobalBrand(id, adminId, req) {
  const brand = await prisma.brand.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!brand) throw new NotFoundError('Global brand not found');

  return prisma.$transaction(async (tx) => {
    const updated = await tx.brand.update({
      where: { id },
      data: { isActive: false, deletedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'BRAND_DEACTIVATED',
      oldValue: { id, name: brand.name, isActive: true },
      newValue: { isActive: false, deletedAt: updated.deletedAt },
      reason: `Global brand '${brand.name}' deactivated`,
      req,
    });

    return updated;
  });
}

// ==========================================
// 2. GLOBAL CATEGORIES
// ==========================================

export async function listGlobalCategories() {
  return prisma.category.findMany({
    where: { isGlobal: true, deletedAt: null },
    orderBy: { name: 'asc' },
  });
}

export async function createGlobalCategory({ name }, adminId, req) {
  const trimmed = name?.trim();
  if (!trimmed) throw new BadRequestError('Category name is required');

  const existing = await prisma.category.findFirst({
    where: { name: trimmed, isGlobal: true, deletedAt: null },
  });
  if (existing) {
    throw new ConflictError(`Global category '${trimmed}' already exists.`);
  }

  return prisma.$transaction(async (tx) => {
    const category = await tx.category.create({
      data: {
        id: uuidv4(),
        ownerId: null,
        name: trimmed,
        isGlobal: true,
        isActive: true,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'CATEGORY_CREATED',
      newValue: { id: category.id, name: category.name },
      reason: `Global category '${trimmed}' created`,
      req,
    });

    return category;
  });
}

export async function updateGlobalCategory(id, { name, isActive }, adminId, req) {
  const category = await prisma.category.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!category) throw new NotFoundError('Global category not found');

  const updates = {};
  if (name !== undefined) {
    const trimmed = name.trim();
    if (!trimmed) throw new BadRequestError('Category name cannot be empty');
    const existing = await prisma.category.findFirst({
      where: { name: trimmed, isGlobal: true, deletedAt: null, NOT: { id } },
    });
    if (existing) throw new ConflictError(`Global category '${trimmed}' already exists.`);
    updates.name = trimmed;
  }
  if (isActive !== undefined) {
    updates.isActive = Boolean(isActive);
  }

  const oldState = { name: category.name, isActive: category.isActive };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.category.update({
      where: { id },
      data: updates,
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'CATEGORY_UPDATED',
      oldValue: oldState,
      newValue: updates,
      reason: `Global category updated`,
      req,
    });

    return updated;
  });
}

export async function deactivateGlobalCategory(id, adminId, req) {
  const category = await prisma.category.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!category) throw new NotFoundError('Global category not found');

  return prisma.$transaction(async (tx) => {
    const updated = await tx.category.update({
      where: { id },
      data: { isActive: false, deletedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'CATEGORY_DEACTIVATED',
      oldValue: { id, name: category.name, isActive: true },
      newValue: { isActive: false, deletedAt: updated.deletedAt },
      reason: `Global category '${category.name}' deactivated`,
      req,
    });

    return updated;
  });
}

// ==========================================
// 3. GLOBAL UNITS
// ==========================================

export async function listGlobalUnits() {
  return prisma.unit.findMany({
    where: { isGlobal: true, deletedAt: null },
    orderBy: { name: 'asc' },
  });
}

export async function createGlobalUnit({ name }, adminId, req) {
  const trimmed = name?.trim();
  if (!trimmed) throw new BadRequestError('Unit name is required');

  const existing = await prisma.unit.findFirst({
    where: { name: trimmed, isGlobal: true, deletedAt: null },
  });
  if (existing) {
    throw new ConflictError(`Global unit '${trimmed}' already exists.`);
  }

  return prisma.$transaction(async (tx) => {
    const unit = await tx.unit.create({
      data: {
        id: uuidv4(),
        ownerId: null,
        name: trimmed,
        isGlobal: true,
        isActive: true,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'UNIT_CREATED',
      newValue: { id: unit.id, name: unit.name },
      reason: `Global unit '${trimmed}' created`,
      req,
    });

    return unit;
  });
}

export async function updateGlobalUnit(id, { name, isActive }, adminId, req) {
  const unit = await prisma.unit.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!unit) throw new NotFoundError('Global unit not found');

  const updates = {};
  if (name !== undefined) {
    const trimmed = name.trim();
    if (!trimmed) throw new BadRequestError('Unit name cannot be empty');
    const existing = await prisma.unit.findFirst({
      where: { name: trimmed, isGlobal: true, deletedAt: null, NOT: { id } },
    });
    if (existing) throw new ConflictError(`Global unit '${trimmed}' already exists.`);
    updates.name = trimmed;
  }
  if (isActive !== undefined) {
    updates.isActive = Boolean(isActive);
  }

  const oldState = { name: unit.name, isActive: unit.isActive };

  return prisma.$transaction(async (tx) => {
    const updated = await tx.unit.update({
      where: { id },
      data: updates,
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'UNIT_UPDATED',
      oldValue: oldState,
      newValue: updates,
      reason: `Global unit updated`,
      req,
    });

    return updated;
  });
}

export async function deactivateGlobalUnit(id, adminId, req) {
  const unit = await prisma.unit.findFirst({
    where: { id, isGlobal: true, deletedAt: null },
  });
  if (!unit) throw new NotFoundError('Global unit not found');

  return prisma.$transaction(async (tx) => {
    const updated = await tx.unit.update({
      where: { id },
      data: { isActive: false, deletedAt: new Date() },
    });

    await auditLogService.record(tx, {
      adminId,
      action: 'UNIT_DEACTIVATED',
      oldValue: { id, name: unit.name, isActive: true },
      newValue: { isActive: false, deletedAt: updated.deletedAt },
      reason: `Global unit '${unit.name}' deactivated`,
      req,
    });

    return updated;
  });
}
