import { z } from 'zod';

export const createPartSchema = z.object({
  body: z.object({
    id: z.string().uuid().optional(),
    name: z.string().min(1, 'Part name is required').max(200),
    partNumber: z.string().max(100).optional().nullable(),
    brandId: z.string().uuid().optional().nullable(),
    categoryId: z.string().uuid().optional().nullable(),
    locationId: z.string().uuid().optional().nullable(),
    customLocation: z.string().max(100).optional().nullable(),
    description: z.string().optional().nullable(),
    unit: z.string().max(50).optional().nullable(),
    cachedQuantity: z.number().nonnegative().optional().default(0),
    purchasePrice: z.number().nonnegative().optional().nullable(),
    sellingPrice: z.number().nonnegative().optional().nullable(),
    notes: z.string().optional().nullable(),
    sizeSpecs: z.string().max(100).optional().nullable(),
  }),
});

export const updatePartSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid part ID format'),
  }),
  body: z.object({
    name: z.string().min(1).max(200).optional(),
    partNumber: z.string().max(100).optional().nullable(),
    brandId: z.string().uuid().optional().nullable(),
    categoryId: z.string().uuid().optional().nullable(),
    locationId: z.string().uuid().optional().nullable(),
    customLocation: z.string().max(100).optional().nullable(),
    description: z.string().optional().nullable(),
    unit: z.string().max(50).optional().nullable(),
    purchasePrice: z.number().nonnegative().optional().nullable(),
    sellingPrice: z.number().nonnegative().optional().nullable(),
    notes: z.string().optional().nullable(),
    sizeSpecs: z.string().max(100).optional().nullable(),
  }),
});
