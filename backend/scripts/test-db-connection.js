import prisma from '../src/config/db.js';

async function main() {
  try {
    const res = await prisma.$queryRaw`SELECT 1 as val`;
    console.log('DB SUCCESS:', res);
    const users = await prisma.user.findMany({ take: 3, select: { id: true, businessName: true, phoneNumber: true } });
    console.log('Sample users count:', users.length);
    if (users.length > 0) {
      console.log('Sample user:', users[0]);
    }
  } catch (e) {
    console.error('DB ERROR:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();

