import { z } from 'zod';

const ETHIOPIAN_PHONE_REGEX = /^(\+251[79]\d{8}|0[79]\d{8}|251[79]\d{8})$/;

export function normalizeEthiopianPhone(phone) {
  let cleaned = phone.trim().replace(/[\s-]/g, '');
  if (cleaned.startsWith('09') || cleaned.startsWith('07')) {
    cleaned = `+251${cleaned.substring(1)}`;
  } else if (cleaned.startsWith('251')) {
    cleaned = `+${cleaned}`;
  }
  return cleaned;
}

export const registerSchema = z.object({
  body: z.object({
    phoneNumber: z
      .string()
      .min(1, 'Phone number is required')
      .regex(
        ETHIOPIAN_PHONE_REGEX,
        'Invalid Ethiopian phone number. Must be 09XXXXXXXX, 07XXXXXXXX, or +251XXXXXXXX.'
      )
      .transform(normalizeEthiopianPhone),
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
    phoneNumber: z
      .string()
      .min(1, 'Phone number is required')
      .regex(
        ETHIOPIAN_PHONE_REGEX,
        'Invalid Ethiopian phone number. Must be 09XXXXXXXX, 07XXXXXXXX, or +251XXXXXXXX.'
      )
      .transform(normalizeEthiopianPhone),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: z.string().min(6, 'New password must be at least 6 characters'),
  }),
});
