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

const DEFAULT_GLOBAL_CATEGORIES = [
  'Filters',
  'Seals',
  'Engine',
  'Undercarriage',
  'Ground tools',
  'Electrical',
];

const DEFAULT_GLOBAL_UNITS = [
  'piece',
  'set',
  'liter',
  'meter',
  'kg',
];

async function main() {
  console.log('🌱 Starting database seed...');

  // 1. Seed / Update Default Admin User
  const adminPhone = process.env.ADMIN_PHONE || '+251900000000';
  const adminPassword = process.env.ADMIN_PASSWORD || 'AdminPassword123!';
  const adminBusinessName = process.env.ADMIN_BUSINESS_NAME || 'Kera System Admin';

  const existingAdmin = await prisma.user.findUnique({
    where: { phoneNumber: adminPhone },
  });

  let adminUserId;
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
        mustChangePassword: false,
      },
    });
    adminUserId = adminUser.id;
    console.log(`✅ Created Admin user: ${adminUser.phoneNumber} (${adminUser.id}) [mustChangePassword=false]`);
  } else {
    adminUserId = existingAdmin.id;
    const passwordHash = await bcrypt.hash(adminPassword, 10);
    await prisma.user.update({
      where: { id: existingAdmin.id },
      data: {
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
        passwordHash,
        mustChangePassword: false,
      },
    });
    console.log(`ℹ️ Admin user already exists and updated: ${existingAdmin.phoneNumber} (password synced)`);
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
          isActive: true,
        },
      });
      console.log(`✅ Seeded global brand: ${brand.name}`);
    } else {
      console.log(`ℹ️ Global brand already exists: ${brandName}`);
    }
  }

  // 3. Seed Default Global Categories
  for (const categoryName of DEFAULT_GLOBAL_CATEGORIES) {
    const existingCategory = await prisma.category.findFirst({
      where: {
        name: categoryName,
        isGlobal: true,
        deletedAt: null,
      },
    });

    if (!existingCategory) {
      const category = await prisma.category.create({
        data: {
          id: uuidv4(),
          ownerId: null,
          name: categoryName,
          isGlobal: true,
          isActive: true,
        },
      });
      console.log(`✅ Seeded global category: ${category.name}`);
    } else {
      console.log(`ℹ️ Global category already exists: ${categoryName}`);
    }
  }

  // 4. Seed Default Global Units
  for (const unitName of DEFAULT_GLOBAL_UNITS) {
    const existingUnit = await prisma.unit.findFirst({
      where: {
        name: unitName,
        isGlobal: true,
        deletedAt: null,
      },
    });

    if (!existingUnit) {
      const unit = await prisma.unit.create({
        data: {
          id: uuidv4(),
          ownerId: null,
          name: unitName,
          isGlobal: true,
          isActive: true,
        },
      });
      console.log(`✅ Seeded global unit: ${unit.name}`);
    } else {
      console.log(`ℹ️ Global unit already exists: ${unitName}`);
    }
  }

  // 5. Seed Default App Settings
  const defaultSettings = [
    {
      key: 'minAppVersion',
      value: { version: '1.0.0', enforce: false },
    },
    {
      key: 'maintenanceMode',
      value: { enabled: false, messageAm: '', messageEn: '' },
    },
    {
      key: 'announcement',
      value: {
        active: false,
        titleAm: '',
        titleEn: '',
        bodyAm: '',
        bodyEn: '',
        startTime: null,
        endTime: null,
      },
    },
  ];

  for (const setting of defaultSettings) {
    const existingSetting = await prisma.appSetting.findUnique({
      where: { key: setting.key },
    });

    if (!existingSetting) {
      await prisma.appSetting.create({
        data: {
          id: uuidv4(),
          key: setting.key,
          value: setting.value,
          updatedBy: adminUserId,
        },
      });
      console.log(`✅ Seeded default app setting: ${setting.key}`);
    } else {
      console.log(`ℹ️ App setting already exists: ${setting.key}`);
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
