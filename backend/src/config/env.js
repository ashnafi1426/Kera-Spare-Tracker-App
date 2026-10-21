import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '7000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'mysql://root:14263208%40aA@localhost:3306/mobile',
  jwtSecret: process.env.JWT_SECRET || 'kera-spare-tracker-jwt-access-secret-2026-super-secure',
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'kera-spare-tracker-jwt-refresh-secret-2026-super-secure',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  bcryptSaltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS || '10', 10),
  corsOrigin: (process.env.CORS_ORIGIN || '*').split(',').map((s) => s.trim()),
  adminPhone: process.env.ADMIN_PHONE || '+251900000000',
  adminPassword: process.env.ADMIN_PASSWORD || 'AdminPassword123!',
  adminBusinessName: process.env.ADMIN_BUSINESS_NAME || 'Kera System Admin',
  uploadDir: process.env.UPLOAD_DIR || './uploads',
  maxFileSizeMb: parseInt(process.env.MAX_FILE_SIZE_MB || '5', 10),
};
