import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { signJwt } from '../src/utils/jwt.js';
import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcryptjs';

describe('Admin Module API Endpoints & RBAC Security Tests', () => {
  let adminUser;
  let adminToken;
  let regularOwner;
  let regularOwnerToken;
  let testTargetOwner;

  const adminPhone = `+251911${Math.floor(100000 + Math.random() * 900000)}`;
  const ownerPhone = `+251922${Math.floor(100000 + Math.random() * 900000)}`;
  const targetPhone = `+251933${Math.floor(100000 + Math.random() * 900000)}`;

  beforeAll(async () => {
    // 1. Create Administrator
    const adminPassHash = await bcrypt.hash('AdminPassword123!', 10);
    adminUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: adminPhone,
        businessName: 'System Administrator',
        passwordHash: adminPassHash,
        role: 'ADMIN',
        status: 'ACTIVE',
        mustChangePassword: true,
      },
    });
    adminToken = signJwt({ id: adminUser.id, role: 'ADMIN', status: 'ACTIVE' });

    // 2. Create Regular Owner
    const ownerPassHash = await bcrypt.hash('OwnerPassword123!', 10);
    regularOwner = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: ownerPhone,
        businessName: 'Regular Spare Shop',
        passwordHash: ownerPassHash,
        role: 'OWNER',
        status: 'ACTIVE',
      },
    });
    regularOwnerToken = signJwt({ id: regularOwner.id, role: 'OWNER', status: 'ACTIVE' });

    // 3. Create Target Owner for suspension / password reset tests
    testTargetOwner = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: targetPhone,
        businessName: 'Target Spare Shop',
        passwordHash: ownerPassHash,
        role: 'OWNER',
        status: 'ACTIVE',
      },
    });
  });

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  // ==========================================
  // 1. RBAC & PERMISSIONS GATING
  // ==========================================

  it('Unauthenticated requests to admin routes get 401', async () => {
    const res = await request(app).get('/api/v1/admin/dashboard');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('Regular OWNER gets 403 FORBIDDEN on every admin route', async () => {
    const endpoints = [
      { method: 'get', path: '/api/v1/admin/dashboard' },
      { method: 'get', path: '/api/v1/admin/users' },
      { method: 'get', path: `/api/v1/admin/users/${testTargetOwner.id}` },
      { method: 'patch', path: `/api/v1/admin/users/${testTargetOwner.id}/suspend` },
      { method: 'get', path: '/api/v1/admin/brands' },
      { method: 'get', path: '/api/v1/admin/categories' },
      { method: 'get', path: '/api/v1/admin/units' },
      { method: 'get', path: '/api/v1/admin/settings/min-app-version' },
      { method: 'get', path: '/api/v1/admin/audit-logs' },
    ];

    for (const ep of endpoints) {
      const res = await request(app)
        [ep.method](ep.path)
        .set('Authorization', `Bearer ${regularOwnerToken}`);
      expect(res.status, `Expected 403 on ${ep.method.toUpperCase()} ${ep.path}`).toBe(403);
      expect(res.body.success).toBe(false);
    }
  });

  // ==========================================
  // 2. DASHBOARD ENDPOINT
  // ==========================================

  it('GET /admin/dashboard returns telemetry metrics and counts without content leakage', async () => {
    const res = await request(app)
      .get('/api/v1/admin/dashboard')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const data = res.body.data;

    expect(data).toHaveProperty('totalOwners');
    expect(data).toHaveProperty('newOwnersThisWeek');
    expect(data).toHaveProperty('activeOwners');
    expect(data).toHaveProperty('suspendedOwners');
    expect(data).toHaveProperty('inactiveOwners');
    expect(data).toHaveProperty('totalParts');
    expect(data).toHaveProperty('totalSales');
    expect(data).toHaveProperty('ownersWithSyncProblems');
    expect(data).toHaveProperty('appVersionDistribution');
    expect(Array.isArray(data.appVersionDistribution)).toBe(true);

    // Strict: No parts rows or sales rows returned
    expect(data.parts).toBeUndefined();
    expect(data.sales).toBeUndefined();
  });

  // ==========================================
  // 3. USER MANAGEMENT ENDPOINTS
  // ==========================================

  it('GET /admin/users returns paginated users list without passwordHash or tokens', async () => {
    const res = await request(app)
      .get('/api/v1/admin/users?limit=10&page=1')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.meta).toHaveProperty('total');

    for (const user of res.body.data) {
      expect(user.passwordHash).toBeUndefined();
      expect(user.password).toBeUndefined();
      expect(user.accessToken).toBeUndefined();
      expect(user.refreshToken).toBeUndefined();
    }
  });

  it('GET /admin/users/:id returns user details, counts, and recent audit logs', async () => {
    const res = await request(app)
      .get(`/api/v1/admin/users/${testTargetOwner.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.phoneNumber).toBe(testTargetOwner.phoneNumber);
    expect(res.body.data.counts).toHaveProperty('partsCount');
    expect(res.body.data.counts).toHaveProperty('salesCount');
    expect(Array.isArray(res.body.data.recentAuditLogs)).toBe(true);
    expect(res.body.data.user.passwordHash).toBeUndefined();
  });

  it('PATCH /admin/users/:id/suspend suspends owner and writes to audit log', async () => {
    const res = await request(app)
      .patch(`/api/v1/admin/users/${testTargetOwner.id}/suspend`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ reason: 'Overdue billing and policy violation' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('SUSPENDED');

    // Verify DB audit log written
    const audit = await prisma.auditLog.findFirst({
      where: {
        targetUserId: testTargetOwner.id,
        action: 'USER_SUSPENDED',
      },
      orderBy: { createdAt: 'desc' },
    });
    expect(audit).not.toBeNull();
    expect(audit.reason).toContain('Overdue billing');
  });

  it('Suspended owner cannot authenticate or access endpoints', async () => {
    // Generate fresh token with target owner ID
    const targetToken = signJwt({ id: testTargetOwner.id, role: 'OWNER', status: 'SUSPENDED' });
    const res = await request(app)
      .get('/api/v1/parts')
      .set('Authorization', `Bearer ${targetToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('PATCH /admin/users/:id/reactivate restores owner access and writes audit log', async () => {
    const res = await request(app)
      .patch(`/api/v1/admin/users/${testTargetOwner.id}/reactivate`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('ACTIVE');

    const audit = await prisma.auditLog.findFirst({
      where: {
        targetUserId: testTargetOwner.id,
        action: 'USER_REACTIVATED',
      },
      orderBy: { createdAt: 'desc' },
    });
    expect(audit).not.toBeNull();
  });

  it('POST /admin/users/:id/reset-password returns temporary password and sets mustChangePassword', async () => {
    const res = await request(app)
      .post(`/api/v1/admin/users/${testTargetOwner.id}/reset-password`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('temporaryPassword');
    const tempPass = res.body.data.temporaryPassword;
    expect(typeof tempPass).toBe('string');
    expect(tempPass.length).toBeGreaterThanOrEqual(8);

    // Verify user in DB has mustChangePassword = true
    const updatedUser = await prisma.user.findUnique({
      where: { id: testTargetOwner.id },
    });
    expect(updatedUser.mustChangePassword).toBe(true);

    // Verify audit log does NOT leak the temporary password
    const audit = await prisma.auditLog.findFirst({
      where: {
        targetUserId: testTargetOwner.id,
        action: 'PASSWORD_RESET',
      },
      orderBy: { createdAt: 'desc' },
    });
    expect(audit).not.toBeNull();
    expect(JSON.stringify(audit)).not.toContain(tempPass);
  });

  it('DELETE /admin/users/:id soft-disables account requiring exact phone confirmation', async () => {
    // 1. Wrong confirm phone fails
    const failRes = await request(app)
      .delete(`/api/v1/admin/users/${testTargetOwner.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ confirm: '+251900000000', reason: 'Closing shop' });

    expect(failRes.status).toBe(400);

    // 2. Correct phone succeeds
    const successRes = await request(app)
      .delete(`/api/v1/admin/users/${testTargetOwner.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ confirm: testTargetOwner.phoneNumber, reason: 'Closing shop' });

    expect(successRes.status).toBe(200);
    expect(successRes.body.data.disabledAt).not.toBeNull();
  });

  // ==========================================
  // 4. GLOBAL CATALOG (BRANDS, CATEGORIES, UNITS)
  // ==========================================

  it('Admin can create, list, and update global brands', async () => {
    const brandName = `Brand_${Date.now()}`;

    // Create
    const createRes = await request(app)
      .post('/api/v1/admin/brands')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: brandName });

    expect(createRes.status).toBe(201);
    const brandId = createRes.body.data.id;

    // Duplicate blocked
    const dupRes = await request(app)
      .post('/api/v1/admin/brands')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: brandName });
    expect(dupRes.status).toBe(409);

    // List
    const listRes = await request(app)
      .get('/api/v1/admin/brands')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(listRes.status).toBe(200);
    expect(listRes.body.data.some((b) => b.id === brandId)).toBe(true);

    // Update
    const updateRes = await request(app)
      .patch(`/api/v1/admin/brands/${brandId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ isActive: false });
    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data.isActive).toBe(false);
  });

  it('Admin can manage global categories and units', async () => {
    const catName = `Cat_${Date.now()}`;
    const unitName = `Unit_${Date.now()}`;

    // Category
    const catRes = await request(app)
      .post('/api/v1/admin/categories')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: catName });
    expect(catRes.status).toBe(201);

    // Unit
    const unitRes = await request(app)
      .post('/api/v1/admin/units')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: unitName });
    expect(unitRes.status).toBe(201);
  });

  // ==========================================
  // 5. APPLICATION SETTINGS
  // ==========================================

  it('Admin can GET and PUT system settings (minAppVersion, announcement, maintenance)', async () => {
    // 1. Min App Version
    const verRes = await request(app)
      .put('/api/v1/admin/settings/min-app-version')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ version: '1.2.0', enforce: true });
    expect(verRes.status).toBe(200);

    const getVerRes = await request(app)
      .get('/api/v1/admin/settings/min-app-version')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(getVerRes.status).toBe(200);
    expect(getVerRes.body.data.version).toBe('1.2.0');

    // 2. Announcement
    const annRes = await request(app)
      .put('/api/v1/admin/settings/announcement')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        active: true,
        titleAm: 'ማስታወቂያ',
        titleEn: 'Maintenance Notice',
        bodyAm: 'ስርዓቱ ዛሬ ማታ ይሻሻላል',
        bodyEn: 'System upgrade tonight',
      });
    expect(annRes.status).toBe(200);

    // 3. Maintenance Mode
    const maintRes = await request(app)
      .put('/api/v1/admin/settings/maintenance')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        enabled: true,
        messageAm: 'ስርዓቱ ለጥገና ተዘግቷል',
        messageEn: 'System under maintenance',
      });
    expect(maintRes.status).toBe(200);
    expect(maintRes.body.data.enabled).toBe(true);
  });

  // ==========================================
  // 6. AUDIT LOGS QUERYING
  // ==========================================

  it('GET /admin/audit-logs returns audit logs with filters and pagination', async () => {
    const res = await request(app)
      .get('/api/v1/admin/audit-logs?limit=10')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.meta).toHaveProperty('total');
    expect(res.body.data.length).toBeGreaterThan(0);

    const entry = res.body.data[0];
    expect(entry).toHaveProperty('action');
    expect(entry).toHaveProperty('adminId');
  });
});
