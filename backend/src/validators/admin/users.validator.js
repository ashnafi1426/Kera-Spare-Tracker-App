import { z } from 'zod';

export const suspendUserSchema = z.object({
  body: z.object({
    reason: z
      .string({ required_error: 'Reason is required' })
      .min(3, 'Reason must be at least 3 characters long'),
  }),
});

export const updateUserSchema = z.object({
  body: z.object({
    businessName: z.string().min(2, 'Business name must be at least 2 characters').optional(),
    phoneNumber: z
      .string()
      .regex(/^\+251\d{9}$/, 'Phone number must be a valid Ethiopian phone number (e.g. +251911223344)')
      .optional(),
  }),
});

export const softDisableUserSchema = z.object({
  body: z.object({
    confirm: z
      .string({ required_error: 'Confirmation phone number is required' })
      .min(1, 'Confirmation phone number is required'),
    reason: z.string().optional(),
  }),
});
