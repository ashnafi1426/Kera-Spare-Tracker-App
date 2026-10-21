import { PrismaClient, UserRole, UserStatus, UserLanguage } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

const DEFAULT_GLOBAL_BRANDS = [
  'CAT',
  'Doosan',
  'Develon',
  'CTP',
  'IPD',
  'Hitachi',
  'SANY',
];

async function main() {
  console.log('🌱 Starting database seed...');

  // 1. Seed Default Admin User
  const adminPhone = process.env.ADMIN_PHONE || '+251900000000';
  const adminPassword = process.env.ADMIN_PASSWORD || 'AdminPassword123!';
  const adminBusinessName = process.env.ADMIN_BUSINESS_NAME || 'Kera System Admin';

  const existingAdmin = await prisma.user.findUnique({
    where: { phoneNumber: adminPhone },
  });

  if (!existingAdmin) {
    const passwordHash = await bcrypt.hash(adminPassword, 10);
    const adminUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: adminPhone,
        businessName: adminBusinessName,
        passwordHash,
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
        language: UserLanguage.AMHARIC,
      },
    });
    console.log(`✅ Created Admin user: ${adminUser.phoneNumber} (${adminUser.id})`);
  } else {
    console.log(`ℹ️ Admin user already exists: ${existingAdmin.phoneNumber}`);
  }

  // 2. Seed Default Global Brands
  for (const brandName of DEFAULT_GLOBAL_BRANDS) {
    const existingBrand = await prisma.brand.findFirst({
      where: {
        name: brandName,
        isGlobal: true,
        deletedAt: null,
      },
    });

    if (!existingBrand) {
      const brand = await prisma.brand.create({
        data: {
          id: uuidv4(),
          ownerId: null,
          name: brandName,
          isGlobal: true,
        },
      });
      console.log(`✅ Seeded global brand: ${brand.name}`);
    } else {
      console.log(`ℹ️ Global brand already exists: ${brandName}`);
    }
  }

  console.log('✨ Database seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
