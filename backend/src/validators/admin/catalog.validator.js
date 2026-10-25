import { z } from 'zod';

export const createCatalogItemSchema = z.object({
  body: z.object({
    name: z
      .string({ required_error: 'Name is required' })
      .min(1, 'Name cannot be empty')
      .max(100, 'Name cannot exceed 100 characters'),
  }),
});

export const updateCatalogItemSchema = z.object({
  body: z.object({
    name: z.string().min(1, 'Name cannot be empty').max(100).optional(),
    isActive: z.boolean().optional(),
  }),
});
