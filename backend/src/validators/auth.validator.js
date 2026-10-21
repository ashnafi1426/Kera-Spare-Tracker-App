import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    phoneNumber: z
      .string()
      .min(9, 'Phone number must be at least 9 digits')
      .max(20, 'Phone number cannot exceed 20 digits'),
    businessName: z
      .string()
      .min(2, 'Business name must be at least 2 characters')
      .max(100, 'Business name cannot exceed 100 characters'),
    password: z
      .string()
      .min(6, 'Password must be at least 6 characters')
      .max(100, 'Password cannot exceed 100 characters'),
    language: z.enum(['AMHARIC', 'ENGLISH']).optional().default('AMHARIC'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    phoneNumber: z.string().min(1, 'Phone number is required'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: z.string().min(6, 'New password must be at least 6 characters'),
  }),
});
