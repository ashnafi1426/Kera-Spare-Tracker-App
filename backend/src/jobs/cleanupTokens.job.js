import prisma from '../config/db.js';

/**
 * Deletes refresh tokens that have been expired or revoked for more than 30 days.
 * @returns {Promise<number>} Number of purged records
 */
export async function cleanupExpiredTokens() {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  try {
    const result = await prisma.refreshToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: thirtyDaysAgo } },
          { revokedAt: { lt: thirtyDaysAgo } },
        ],
      },
    });
    return result.count;
  } catch (err) {
    console.error('Failed to run cleanupExpiredTokens:', err);
    return 0;
  }
}

/**
 * Schedules periodic cleanup every 24 hours (and runs once at startup).
 */
export function startTokenCleanupScheduler() {
  // Run once at startup non-blockingly
  cleanupExpiredTokens().then((count) => {
    if (count > 0) {
      console.log(`[CLEANUP] Purged ${count} old refresh tokens on startup.`);
    }
  });

  // Run every 24 hours
  const intervalMs = 24 * 60 * 60 * 1000;
  const timer = setInterval(async () => {
    const count = await cleanupExpiredTokens();
    if (count > 0) {
      console.log(`[CLEANUP] Periodic job purged ${count} old refresh tokens.`);
    }
  }, intervalMs);

  // Do not hold process alive purely for this timer in test environments
  if (timer.unref) {
    timer.unref();
  }

  return timer;
}
