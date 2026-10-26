import { cleanupExpiredTokens } from '../src/jobs/cleanupTokens.job.js';
import prisma from '../src/config/db.js';

async function run() {
  console.log('🧹 Running refresh token cleanup...');
  const count = await cleanupExpiredTokens();
  console.log(`✅ Cleaned up ${count} expired/revoked refresh tokens older than 30 days.`);
  await prisma.$disconnect();
  process.exit(0);
}

run().catch((err) => {
  console.error('❌ Error cleaning tokens:', err);
  process.exit(1);
});
