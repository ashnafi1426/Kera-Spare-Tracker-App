import express from 'express';
import path from 'path';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config/env.js';
import { logger } from './config/logger.js';
import { setupSwagger } from './config/swagger.js';
import healthRoutes from './routes/health.routes.js';
import apiRoutes from './routes/index.js';
import { errorHandler } from './middleware/error.middleware.js';
import { NotFoundError } from './utils/errors.js';
import { storageService } from './services/storage.service.js';

const app = express();

// Trust reverse proxy (e.g. Nginx, load balancers, Render, Docker)
app.set('trust proxy', 1);

// 1. Security Headers with Helmet
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'blob:'],
        connectSrc: ["'self'", ...(config.corsOrigin || []), ...(config.adminCorsOrigin || [])],
      },
    },
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  })
);

// 2. CORS configuration with allowed-origins list from .env
const allowedOrigins = [
  ...(Array.isArray(config.corsOrigin) ? config.corsOrigin : [config.corsOrigin]),
  ...(Array.isArray(config.adminCorsOrigin) ? config.adminCorsOrigin : [config.adminCorsOrigin]),
];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps, curl, Postman)
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`Origin '${origin}' not allowed by CORS policy`), false);
    },
    credentials: true,
  })
);

// 3. Request body size limit (Strict 10MB limit for JSON sync batches & base64)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 4. Rate Limiting (100 requests per 15 minutes window for general routes)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000, // Generous for mobile sync and inventory pagination
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many requests. Please try again later.',
    },
  },
});
app.use('/api/', limiter);

// 5. HTTP Request Logging with Winston
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`);
  });
  next();
});

// 6. Swagger API Documentation (Non-production only)
setupSwagger(app);

// Static uploads serving (both at root and /api/v1 for reverse proxies and mobile apps)
const resolvedUploadDir = storageService.baseDir;
app.use('/uploads', express.static(resolvedUploadDir));
app.use('/api/v1/uploads', express.static(resolvedUploadDir));

// 7. Health Check Route (Mounted at root and /api/v1)
app.use('/', healthRoutes);
app.use('/api/v1', healthRoutes);

// 8. Main API Router (Mounted at /api/v1 and /api for backward & standard REST compatibility)
app.use('/api/v1', apiRoutes);
app.use('/api', apiRoutes);

// 9. Catch-all 404 for undefined routes
app.use((req, res, next) => {
  next(new NotFoundError(`Resource not found at ${req.method} ${req.originalUrl}`));
});

// 10. Centralized JSON Error Handler
app.use(errorHandler);

export default app;
