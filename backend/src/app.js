import express from 'express';
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

const app = express();

// 1. Security Headers with Helmet
app.use(helmet());

// 2. CORS configuration with allowed-origins list from .env
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps, curl, Postman)
      if (!origin) return callback(null, true);
      if (config.corsOrigin.includes('*') || config.corsOrigin.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`Origin '${origin}' not allowed by CORS policy`), false);
    },
    credentials: true,
  })
);

// 3. Request body size limit
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// 4. Rate Limiting (100 requests per 15 minutes window)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many requests from this IP. Please try again after 15 minutes.',
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

// 7. Health Check Route (Mounted at root and /api/v1)
app.use('/', healthRoutes);
app.use('/api/v1', healthRoutes);

// 8. Main API Router
app.use('/api/v1', apiRoutes);

// 9. Catch-all 404 for undefined routes
app.use((req, res, next) => {
  next(new NotFoundError(`Resource not found at ${req.method} ${req.originalUrl}`));
});

// 10. Centralized JSON Error Handler
app.use(errorHandler);

export default app;
