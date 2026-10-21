import { z } from 'zod';

export const createSaleSchema = z.object({
  body: z.object({
    id: z.string().uuid().optional(),
    receiptNumber: z.string().min(1, 'Receipt number is required'),
    paymentMethod: z.enum(['CASH', 'BANK_TRANSFER', 'CREDIT']).default('CASH'),
    customerName: z.string().max(100).optional().nullable(),
    customerPhone: z.string().max(20).optional().nullable(),
    notes: z.string().optional().nullable(),
    soldAt: z.string().datetime().optional(),
    items: z
      .array(
        z.object({
          id: z.string().uuid().optional(),
          partId: z.string().uuid().optional().nullable(),
          partNameSnapshot: z.string().min(1),
          quantity: z.number().positive('Quantity must be greater than zero'),
          unitCostSnapshot: z.number().nonnegative(),
          unitPriceSnapshot: z.number().nonnegative(),
        })
      )
      .min(1, 'Sale must have at least one line item'),
  }),
});
