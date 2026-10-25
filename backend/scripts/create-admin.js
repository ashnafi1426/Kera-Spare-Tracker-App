#!/usr/bin/env node

/**
 * Protected CLI Script: Create Administrator Account
 *
 * Usage:
 *   npm run create-admin -- --phone 0911223344 --name "Operations Lead" --password "StrongPass123!#"
 * Or interactive mode:
 *   npm run create-admin
 */

import readline from 'readline';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../src/config/db.js';
import {
  ADMIN_PASSWORD_REGEX,
  normalizeEthiopianPhone,
} from '../src/validators/auth.validator.js';

const ETHIOPIAN_PHONE_REGEX = /^(\+251[79]\d{8}|0[79]\d{8}|251[79]\d{8})$/;

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--phone' && args[i + 1]) {
      options.phone = args[++i];
    } else if (args[i] === '--password' && args[i + 1]) {
      options.password = args[++i];
    } else if (args[i] === '--name' && args[i + 1]) {
      options.name = args[++i];
    }
  }
  return options;
}

function ask(rl, query) {
  return new Promise((resolve) => rl.question(query, resolve));
}

async function main() {
  console.log('\n======================================================');
  console.log('🛡️  Kera Spare Tracker - Protected Admin Creation CLI');
  console.log('======================================================\n');

  const args = parseArgs();
  let phone = args.phone;
  let name = args.name;
  let password = args.password;

  if (!phone || !password) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    if (!phone) {
      phone = await ask(rl, 'Enter Ethiopian phone number (e.g. 0911223344): ');
    }
    if (!name) {
      name = await ask(rl, 'Enter Admin full name or title (default: System Administrator): ');
    }
    if (!password) {
      password = await ask(rl, 'Enter strong Admin password (min 12 chars, upper, lower, digit, symbol): ');
    }

    rl.close();
  }

  name = (name || 'System Administrator').trim();

  // 1. Validate Phone Number
  if (!phone || !ETHIOPIAN_PHONE_REGEX.test(phone.trim())) {
    console.error('❌ Error: Invalid Ethiopian phone number format. Must start with 09, 07, or +251.');
    process.exit(1);
  }
  const normalizedPhone = normalizeEthiopianPhone(phone);

  // 2. Validate Password Policy
  if (!password || !ADMIN_PASSWORD_REGEX.test(password)) {
    console.error('❌ Error: Password violates administrative security policy.');
    console.error('   Requirements:');
    console.error('   - At least 12 characters in length');
    console.error('   - At least one uppercase letter (A-Z)');
    console.error('   - At least one lowercase letter (a-z)');
    console.error('   - At least one numeric digit (0-9)');
    console.error('   - At least one special symbol (!@#$%^&*...)');
    process.exit(1);
  }

  // 3. Check for Existing Account
  const existing = await prisma.user.findUnique({
    where: { phoneNumber: normalizedPhone },
  });

  if (existing) {
    console.error(`❌ Error: An account with phone number ${normalizedPhone} already exists (role: ${existing.role}).`);
    process.exit(1);
  }

  // 4. Create Admin Account
  const passwordHash = await bcrypt.hash(password, 10);
  const adminId = uuidv4();

  const admin = await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: {
        id: adminId,
        phoneNumber: normalizedPhone,
        businessName: name,
        passwordHash,
        role: 'ADMIN',
        status: 'ACTIVE',
        language: 'AMHARIC',
        mustChangePassword: true, // Mandatory password change on first login
      },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        role: true,
        status: true,
        mustChangePassword: true,
        createdAt: true,
      },
    });

    await tx.auditLog.create({
      data: {
        id: uuidv4(),
        adminId: null,
        targetUserId: user.id,
        action: 'ADMIN_CREATED_CLI',
        reason: 'Administrator account provisioned via protected CLI script',
        newValue: {
          phoneNumber: user.phoneNumber,
          businessName: user.businessName,
          mustChangePassword: true,
        },
      },
    });

    return user;
  });

  console.log('\n✅ Admin account created successfully!');
  console.log(`   ID:                   ${admin.id}`);
  console.log(`   Phone Number:         ${admin.phoneNumber}`);
  console.log(`   Business Name:        ${admin.businessName}`);
  console.log(`   Role:                 ${admin.role}`);
  console.log(`   Must Change Password: ${admin.mustChangePassword}`);
  console.log('\n🔒 Security Notice: The administrator must change this temporary password upon first login.\n');

  await prisma.$disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('\n❌ Fatal error executing admin creation script:', err);
  await prisma.$disconnect();
  process.exit(1);
});
