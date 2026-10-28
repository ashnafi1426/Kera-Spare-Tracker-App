import prisma from '../src/config/db.js';

async function run() {
  if (process.env.NODE_ENV === 'production') {
    console.error('❌ SAFETY ABORT: dev-cleanup-test-data cannot be run in production mode.');
    process.exit(1);
  }

  console.log('🧹 Cleaning up automated test catalog entries (Brand_*, Category_*, Unit_*)...');

  const deletedBrands = await prisma.brand.deleteMany({
    where: {
      isGlobal: true,
      name: { startsWith: 'Brand_' },
    },
  });

  const deletedCategories = await prisma.category.deleteMany({
    where: {
      isGlobal: true,
      name: { startsWith: 'Category_' },
    },
  });

  const deletedUnits = await prisma.unit.deleteMany({
    where: {
      isGlobal: true,
      name: { startsWith: 'Unit_' },
    },
  });

  console.log(`✅ Cleaned up:
  - ${deletedBrands.count} test brands
  - ${deletedCategories.count} test categories
  - ${deletedUnits.count} test units`);

  await prisma.$disconnect();
  process.exit(0);
}

run().catch((err) => {
  console.error('❌ Error during cleanup:', err);
  process.exit(1);
});
