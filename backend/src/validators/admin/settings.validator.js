import { z } from 'zod';

export const minAppVersionSchema = z.object({
  body: z.object({
    version: z.string({ required_error: 'Version string is required' }).min(1),
    enforce: z.boolean().default(false),
  }),
});

export const announcementSchema = z.object({
  body: z.object({
    active: z.boolean({ required_error: 'Active flag is required' }),
    titleAm: z.string().optional().default(''),
    titleEn: z.string().optional().default(''),
    bodyAm: z.string().optional().default(''),
    bodyEn: z.string().optional().default(''),
    startTime: z.string().nullable().optional(),
    endTime: z.string().nullable().optional(),
  }),
});

export const maintenanceSchema = z.object({
  body: z.object({
    enabled: z.boolean({ required_error: 'Enabled flag is required' }),
    messageAm: z.string().optional().default(''),
    messageEn: z.string().optional().default(''),
  }),
});
