import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { signJwt } from '../src/utils/jwt.js';
import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcryptjs';

describe('Owner Reaction & Sync Integration Tests', () => {
  let ownerUser;
  let ownerToken;
  let suspendedUser;
  let suspendedToken;
  let mustChangePasswordUser;
  let mustChangePasswordToken;

  const ownerPhone = `+251911${Math.floor(100000 + Math.random() * 900000)}`;
  const suspendedPhone = `+251922${Math.floor(100000 + Math.random() * 900000)}`;
  const mustChangePhone = `+251933${Math.floor(100000 + Math.random() * 900000)}`;

  beforeAll(async () => {
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // 1. Regular Owner
    ownerUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: ownerPhone,
        businessName: 'Active Owner',
        passwordHash,
        role: 'OWNER',
        status: 'ACTIVE',
        failedSyncCount: 2,
      },
    });
    ownerToken = signJwt({ id: ownerUser.id, role: 'OWNER', status: 'ACTIVE' });

    // 2. Suspended Owner
    suspendedUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: suspendedPhone,
        businessName: 'Suspended Owner',
        passwordHash,
        role: 'OWNER',
        status: 'SUSPENDED',
        suspendedReason: 'Account past due',
      },
    });
    suspendedToken = signJwt({ id: suspendedUser.id, role: 'OWNER', status: 'SUSPENDED' });

    // 3. Must Change Password Owner
    mustChangePasswordUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: mustChangePhone,
        businessName: 'Reset Pass Owner',
        passwordHash,
        role: 'OWNER',
        status: 'ACTIVE',
        mustChangePassword: true,
      },
    });
    mustChangePasswordToken = signJwt({
      id: mustChangePasswordUser.id,
      role: 'OWNER',
      status: 'ACTIVE',
    });
  });

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  it('1. GET /api/v1/app-config returns public configuration without authentication', async () => {
    const res = await request(app).get('/api/v1/app-config');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('minAppVersion');
    expect(res.body.data).toHaveProperty('maintenanceMode');
    expect(res.body.data).toHaveProperty('announcement');
  });

  it('2. X-App-Version header updates appVersion in user record', async () => {
    const testVersion = '2.4.1';
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-App-Version', testVersion);

    expect(res.status).toBe(200);

    // Give async update brief tick to write
    await new Promise((r) => setTimeout(r, 200));

    const updated = await prisma.user.findUnique({
      where: { id: ownerUser.id },
    });
    expect(updated.appVersion).toBe(testVersion);
  });

  it('3. GET /api/v1/sync/pull includes global brands, categories, and units', async () => {
    const res = await request(app)
      .get('/api/v1/sync/pull')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const changes = res.body.data.changes;

    expect(changes).toHaveProperty('brands');
    expect(changes).toHaveProperty('categories');
    expect(changes).toHaveProperty('units');

    // Global catalog items are present
    expect(changes.brands.some((b) => b.isGlobal === true)).toBe(true);
    expect(changes.categories.some((c) => c.isGlobal === true)).toBe(true);
    expect(changes.units.some((u) => u.isGlobal === true)).toBe(true);

    // Verify lastSyncAt updated and failedSyncCount reset to 0
    const userAfterSync = await prisma.user.findUnique({
      where: { id: ownerUser.id },
    });
    expect(userAfterSync.lastSyncAt).not.toBeNull();
    expect(userAfterSync.failedSyncCount).toBe(0);
  });

  it('4. Suspended owner gets 403 ACCOUNT_SUSPENDED with reason on sync and api calls', async () => {
    const res = await request(app)
      .get('/api/v1/sync/pull')
      .set('Authorization', `Bearer ${suspendedToken}`);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
    expect(res.body.error.details?.reason).toBe('Account past due');
  });

  it('5. User with mustChangePassword = true is blocked from other endpoints with 403 PASSWORD_CHANGE_REQUIRED', async () => {
    // 1. Blocked from parts
    const partsRes = await request(app)
      .get('/api/v1/parts')
      .set('Authorization', `Bearer ${mustChangePasswordToken}`);
    expect(partsRes.status).toBe(403);
    expect(partsRes.body.error.code).toBe('PASSWORD_CHANGE_REQUIRED');

    // 2. Blocked from sync
    const syncRes = await request(app)
      .get('/api/v1/sync/pull')
      .set('Authorization', `Bearer ${mustChangePasswordToken}`);
    expect(syncRes.status).toBe(403);
    expect(syncRes.body.error.code).toBe('PASSWORD_CHANGE_REQUIRED');

    // 3. Allowed to call /auth/me
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${mustChangePasswordToken}`);
    expect(meRes.status).toBe(200);

    // 4. Allowed to change password
    const changeRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${mustChangePasswordToken}`)
      .send({
        currentPassword: 'Password123!',
        newPassword: 'BrandNewPassword123!',
      });
    expect(changeRes.status).toBe(200);

    // 5. mustChangePassword is now false in DB
    const refreshed = await prisma.user.findUnique({
      where: { id: mustChangePasswordUser.id },
    });
    expect(refreshed.mustChangePassword).toBe(false);
  });
});
