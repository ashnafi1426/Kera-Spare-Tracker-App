import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(7000),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().min(1).default('mysql://root:14263208%40aA@localhost:3306/mobile'),
  JWT_SECRET: z.string().min(8).default('kera-spare-tracker-jwt-access-secret-2026-super-secure'),
  JWT_REFRESH_SECRET: z.string().min(8).default('kera-spare-tracker-jwt-refresh-secret-2026-super-secure'),
  ACCESS_TOKEN_MINUTES: z.coerce.number().int().positive().default(15),
  REFRESH_TOKEN_DAYS: z.coerce.number().int().positive().default(90),
  OFFLINE_MAX_DAYS: z.coerce.number().int().positive().default(90),
  JWT_ADMIN_ACCESS_EXPIRES_IN: z.string().default('10m'),
  BCRYPT_SALT_ROUNDS: z.coerce.number().int().min(4).max(16).default(10),
  CORS_ORIGIN: z.string().default('*'),
  ADMIN_CORS_ORIGIN: z.string().default('http://localhost:3000,http://localhost:5000,http://localhost:8080'),
  ADMIN_PHONE: z.string().default('+251900000000'),
  ADMIN_PASSWORD: z.string().default('AdminPassword123!'),
  ADMIN_BUSINESS_NAME: z.string().default('Kera System Admin'),
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_FILE_SIZE_MB: z.coerce.number().int().positive().default(5),
});

const parsedEnv = envSchema.parse(process.env);

export const config = {
  port: parsedEnv.PORT,
  nodeEnv: parsedEnv.NODE_ENV,
  databaseUrl: parsedEnv.DATABASE_URL,
  jwtSecret: parsedEnv.JWT_SECRET,
  jwtRefreshSecret: parsedEnv.JWT_REFRESH_SECRET,
  accessTokenMinutes: parsedEnv.ACCESS_TOKEN_MINUTES,
  refreshTokenDays: parsedEnv.REFRESH_TOKEN_DAYS,
  offlineMaxDays: parsedEnv.OFFLINE_MAX_DAYS,
  jwtAccessExpiresIn: `${parsedEnv.ACCESS_TOKEN_MINUTES}m`,
  jwtAdminAccessExpiresIn: parsedEnv.JWT_ADMIN_ACCESS_EXPIRES_IN,
  jwtRefreshExpiresIn: `${parsedEnv.REFRESH_TOKEN_DAYS}d`,
  bcryptSaltRounds: parsedEnv.BCRYPT_SALT_ROUNDS,
  corsOrigin: parsedEnv.CORS_ORIGIN.split(',').map((s) => s.trim()),
  adminCorsOrigin: parsedEnv.ADMIN_CORS_ORIGIN
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  adminPhone: parsedEnv.ADMIN_PHONE,
  adminPassword: parsedEnv.ADMIN_PASSWORD,
  adminBusinessName: parsedEnv.ADMIN_BUSINESS_NAME,
  uploadDir: parsedEnv.UPLOAD_DIR,
  maxFileSizeMb: parsedEnv.MAX_FILE_SIZE_MB,
};
