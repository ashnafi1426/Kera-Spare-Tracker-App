import app from './app.js';
import { config } from './config/env.js';
import { logger } from './config/logger.js';
import prisma from './config/db.js';

const PORT = config.port;

const server = app.listen(PORT, () => {
  logger.info(` Kera Spare Tracker API running on port ${PORT} [${config.nodeEnv}]`);
  logger.info(` Swagger Documentation: http://localhost:${PORT}/api-docs`);
  logger.info(` Health Check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
async function gracefulShutdown(signal) {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  server.close(async () => {
    logger.info('HTTP server closed.');
    await prisma.$disconnect();
    logger.info('Prisma database client disconnected.');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Forcefully terminating process after 10s timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
