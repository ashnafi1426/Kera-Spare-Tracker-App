import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '7000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'mysql://root:@localhost:3306/kera_spare_tracker',
  jwtSecret: process.env.JWT_SECRET || 'kera-spare-tracker-default-jwt-secret-key-2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigin: (process.env.CORS_ORIGIN || '*').split(',').map((s) => s.trim()),
  adminPhone: process.env.ADMIN_PHONE || '+251900000000',
  adminPassword: process.env.ADMIN_PASSWORD || 'AdminPassword123!',
  adminBusinessName: process.env.ADMIN_BUSINESS_NAME || 'Kera System Admin',
  uploadDir: process.env.UPLOAD_DIR || './uploads',
  maxFileSizeMb: parseInt(process.env.MAX_FILE_SIZE_MB || '5', 10),
};
