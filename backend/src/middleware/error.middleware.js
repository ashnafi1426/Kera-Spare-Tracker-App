import { AppError } from '../utils/errors.js';
import { logger } from '../config/logger.js';
import { config } from '../config/env.js';

export function errorHandler(err, req, res, next) {
  // Log all non-operational or 500 errors with stack trace
  if (!err.isOperational || err.statusCode === 500) {
    logger.error(`Unhandled Error: ${err.message}`, { stack: err.stack, path: req.path });
  }

  // Handle Multer upload errors
  if (err.name === 'MulterError') {
    return res.status(400).json({
      success: false,
      error: {
        code: 'FILE_UPLOAD_ERROR',
        message: err.message,
      },
    });
  }

  // Handle Prisma known errors
  if (err.code === 'P2002') {
    const isPhone = Array.isArray(err.meta?.target) && err.meta.target.includes('phoneNumber');
    return res.status(409).json({
      success: false,
      error: {
        code: isPhone ? 'PHONE_TAKEN' : 'DUPLICATE_ENTRY',
        message: isPhone
          ? 'A business owner with this phone number is already registered.'
          : 'A record with this unique identifier already exists.',
        details: err.meta,
      },
    });
  }

  // Operational AppError
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  }

  // Fallback 500 Internal Server Error
  const isProduction = config.nodeEnv === 'production';
  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: isProduction ? 'An unexpected internal error occurred.' : err.message,
      ...(isProduction ? {} : { stack: err.stack }),
    },
  });
}
