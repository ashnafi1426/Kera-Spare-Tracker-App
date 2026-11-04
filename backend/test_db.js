import prisma from './src/config/db.js';

async function test() {
  try {
    console.log('Testing DB connection...');
    await prisma.$connect();
    const count = await prisma.user.count();
    console.log('DB SUCCESS! User count:', count);
    process.exit(0);
  } catch (err) {
    console.error('DB FAILED:', err.message);
    process.exit(1);
  }
}

test();

