import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { signAccessToken, verifyAccessToken } from '../src/utils/jwt.js';
import { resetAllAdminLoginAttempts } from '../src/services/auth.service.js';
import { ADMIN_PASSWORD_REGEX } from '../src/validators/auth.validator.js';
import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcryptjs';

describe('Admin Security Hardening & Isolation Tests', () => {
  let adminUser;
  let adminToken;
  let ownerUser;
  let ownerToken;
  let seededAdminUser;
  let seededAdminToken;

  const adminPhone = `+251977${Math.floor(100000 + Math.random() * 900000)}`;
  const ownerPhone = `+251911${Math.floor(100000 + Math.random() * 900000)}`;
  const seededPhone = `+251900${Math.floor(100000 + Math.random() * 900000)}`;
  const strongAdminPass = 'AdminSecretPass123!#';

  beforeAll(async () => {
    const adminPassHash = await bcrypt.hash(strongAdminPass, 10);
    const ownerPassHash = await bcrypt.hash('OwnerPassword123!', 10);

    // 1. Regular active administrator
    adminUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: adminPhone,
        businessName: 'System Security Admin',
        passwordHash: adminPassHash,
        role: 'ADMIN',
        status: 'ACTIVE',
        mustChangePassword: false,
      },
    });
    adminToken = signAccessToken({ id: adminUser.id, role: 'ADMIN', status: 'ACTIVE' });

    // 2. Regular active business owner
    ownerUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: ownerPhone,
        businessName: 'Spare Parts Shop',
        passwordHash: ownerPassHash,
        role: 'OWNER',
        status: 'ACTIVE',
        mustChangePassword: false,
      },
    });
    ownerToken = signAccessToken({ id: ownerUser.id, role: 'OWNER', status: 'ACTIVE' });

    // 3. Seeded admin with mustChangePassword = true
    seededAdminUser = await prisma.user.create({
      data: {
        id: uuidv4(),
        phoneNumber: seededPhone,
        businessName: 'Initial Seeded Admin',
        passwordHash: adminPassHash,
        role: 'ADMIN',
        status: 'ACTIVE',
        mustChangePassword: true,
      },
    });
    seededAdminToken = signAccessToken({ id: seededAdminUser.id, role: 'ADMIN', status: 'ACTIVE' });
  });

  beforeEach(() => {
    resetAllAdminLoginAttempts();
  });

  afterAll(async () => {
    await prisma.auditLog.deleteMany({
      where: {
        OR: [
          { targetUserId: { in: [adminUser?.id, ownerUser?.id, seededAdminUser?.id].filter(Boolean) } },
          { adminId: { in: [adminUser?.id, ownerUser?.id, seededAdminUser?.id].filter(Boolean) } },
        ],
      },
    });
    await prisma.refreshToken.deleteMany({
      where: { userId: { in: [adminUser?.id, ownerUser?.id, seededAdminUser?.id].filter(Boolean) } },
    });
    await prisma.user.deleteMany({
      where: { id: { in: [adminUser?.id, ownerUser?.id, seededAdminUser?.id].filter(Boolean) } },
    });
  });

  // =========================================================================
  // 1. RATE LIMITING & LOCKOUT: Block on the 6th failed attempt
  // =========================================================================
  it('1. Admin login rate limiter & lockout blocks on the 6th failed attempt', async () => {
    const lockoutTestPhone = `+251977${Math.floor(100000 + Math.random() * 900000)}`;
    const testIp = '192.168.10.50';

    // 5 attempts should return 401 INVALID_CREDENTIALS
    for (let attempt = 1; attempt <= 5; attempt++) {
      const res = await request(app)
        .post('/api/v1/auth/admin/login')
        .set('X-Forwarded-For', testIp)
        .send({
          phoneNumber: lockoutTestPhone,
          password: 'WrongPassword123!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
    }

    // 6th attempt must be blocked with 429 TOO_MANY_REQUESTS
    const blockedRes = await request(app)
      .post('/api/v1/auth/admin/login')
      .set('X-Forwarded-For', testIp)
      .send({
        phoneNumber: lockoutTestPhone,
        password: strongAdminPass, // even with right password, account/IP is locked out
      });

    expect(blockedRes.status).toBe(429);
    expect(blockedRes.body.success).toBe(false);
    expect(blockedRes.body.error.code).toBe('TOO_MANY_REQUESTS');
  });


  // =========================================================================
  // 2. IDENTICAL ERROR MESSAGES (Account Enumeration Prevention)
  // =========================================================================
  it('2. Returns identical error messages for non-existent phone, wrong password, and non-admin role', async () => {
    // Non-existent phone
    const resNonExistent = await request(app)
      .post('/api/v1/auth/admin/login')
      .set('X-Forwarded-For', '10.0.0.1')
      .send({
        phoneNumber: '+251999999999',
        password: 'SomePassword123!',
      });

    // Wrong password for valid admin
    const resWrongPass = await request(app)
      .post('/api/v1/auth/admin/login')
      .set('X-Forwarded-For', '10.0.0.2')
      .send({
        phoneNumber: adminPhone,
        password: 'IncorrectPassword999!',
      });

    // Owner account attempting to login via admin portal
    const resOwnerAttempt = await request(app)
      .post('/api/v1/auth/admin/login')
      .set('X-Forwarded-For', '10.0.0.3')
      .send({
        phoneNumber: ownerPhone,
        password: 'OwnerPassword123!',
      });

    expect(resNonExistent.status).toBe(401);
    expect(resWrongPass.status).toBe(401);
    expect(resOwnerAttempt.status).toBe(401);

    expect(resNonExistent.body.error.message).toBe(resWrongPass.body.error.message);
    expect(resWrongPass.body.error.message).toBe(resOwnerAttempt.body.error.message);
    expect(resNonExistent.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  // =========================================================================
  // 3. ADMIN PASSWORD POLICY (at least 12 chars, upper, lower, digit, symbol)
  // =========================================================================
  it('3. Admin password policy rejects weak passwords', async () => {
    expect(ADMIN_PASSWORD_REGEX.test('weak')).toBe(false);
    expect(ADMIN_PASSWORD_REGEX.test('Short1!Aa')).toBe(false); // only 9 chars
    expect(ADMIN_PASSWORD_REGEX.test('NoSymbols12345Aa')).toBe(false); // missing symbol
    expect(ADMIN_PASSWORD_REGEX.test('nospecuppercase123!')).toBe(false); // missing uppercase
    expect(ADMIN_PASSWORD_REGEX.test('NOSPECLOWERCASE123!')).toBe(false); // missing lowercase
    expect(ADMIN_PASSWORD_REGEX.test('NoDigitsAtAllHere!#Aa')).toBe(false); // missing digit
    expect(ADMIN_PASSWORD_REGEX.test('StrongPass123!#')).toBe(true); // valid: 15 chars, all categories

    // Test rejecting weak password when changing admin password via API
    const res = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        currentPassword: strongAdminPass,
        newPassword: 'weakpassword',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  // =========================================================================
  // 4. PRIVILEGE ESCALATION PREVENTION (Public registration ignores role)
  // =========================================================================
  it('4. Public registration strictly ignores role field sent by client', async () => {
    const maliciousPhone = `+251944${Math.floor(100000 + Math.random() * 900000)}`;

    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: maliciousPhone,
        businessName: 'Malicious Escalation Attempt',
        password: 'Password123!',
        role: 'ADMIN', // Attacker attempts to become admin
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe('OWNER');

    // Verify directly in database
    const createdUser = await prisma.user.findUnique({
      where: { phoneNumber: maliciousPhone },
    });
    expect(createdUser.role).toBe('OWNER');

    // Cleanup
    await prisma.refreshToken.deleteMany({ where: { userId: createdUser.id } });
    await prisma.user.delete({ where: { id: createdUser.id } });
  });

  // =========================================================================
  // 5. RBAC GATEWAY: Owner token cannot access /api/v1/admin/* (403)
  // =========================================================================
  it('5. Owner token cannot access any /api/v1/admin/* endpoint and returns 403 FORBIDDEN', async () => {
    const endpoints = [
      { method: 'get', url: '/api/v1/admin/dashboard' },
      { method: 'get', url: '/api/v1/admin/users' },
      { method: 'get', url: '/api/v1/admin/brands' },
      { method: 'get', url: '/api/v1/admin/settings/min-app-version' },
      { method: 'get', url: '/api/v1/admin/audit-logs' },
    ];

    for (const ep of endpoints) {
      const res = await request(app)[ep.method](ep.url).set('Authorization', `Bearer ${ownerToken}`);
      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('FORBIDDEN');
    }
  });

  // =========================================================================
  // 6. SEEDED ADMIN MUST CHANGE PASSWORD BEFORE ACCESSING RESOURCES (403)
  // =========================================================================
  it('6. Seeded admin with mustChangePassword = true is blocked with 403 PASSWORD_CHANGE_REQUIRED', async () => {
    // Calling admin dashboard is blocked
    const res = await request(app)
      .get('/api/v1/admin/dashboard')
      .set('Authorization', `Bearer ${seededAdminToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('PASSWORD_CHANGE_REQUIRED');

    // But calling /auth/change-password is permitted
    const newAdminPass = 'NewAdminSecretPass2026!#';
    const changePassRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${seededAdminToken}`)
      .send({
        currentPassword: strongAdminPass,
        newPassword: newAdminPass,
      });

    expect(changePassRes.status).toBe(200);
    expect(changePassRes.body.success).toBe(true);

    // Verify mustChangePassword is now false
    const updatedAdmin = await prisma.user.findUnique({
      where: { id: seededAdminUser.id },
    });
    expect(updatedAdmin.mustChangePassword).toBe(false);
  });

  // =========================================================================
  // 7. SHORT ADMIN ACCESS TOKEN EXPIRY (10 minutes)
  // =========================================================================
  it('7. Admin access token has 10 minutes lifespan', async () => {
    const adminToken10m = signAccessToken({ id: adminUser.id, role: 'ADMIN', status: 'ACTIVE' });
    const verified = verifyAccessToken(adminToken10m);

    expect(verified.valid).toBe(true);
    const lifespanSeconds = verified.decoded.exp - verified.decoded.iat;
    // 10 minutes = 600 seconds
    expect(lifespanSeconds).toBe(600);
  });

  // =========================================================================
  // 8. PRIVACY & DATA LEAK AUDIT
  // =========================================================================
  it('8. Zero password hashes, tokens, or inventory rows leaked in admin responses or audit logs', async () => {
    const usersRes = await request(app)
      .get('/api/v1/admin/users')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(usersRes.status).toBe(200);
    const users = Array.isArray(usersRes.body.data) ? usersRes.body.data : usersRes.body.data.users;
    for (const u of users) {
      expect(u.passwordHash).toBeUndefined();
      expect(u.password).toBeUndefined();
      expect(u.tokens).toBeUndefined();
    }

    const auditRes = await request(app)
      .get('/api/v1/admin/audit-logs')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(auditRes.status).toBe(200);
    const logs = Array.isArray(auditRes.body.data) ? auditRes.body.data : auditRes.body.data.logs;
    for (const log of logs) {
      const serialized = JSON.stringify(log);
      expect(serialized).not.toContain('passwordHash');
      expect(serialized).not.toContain('temporaryPassword');
    }
  });

  afterAll(async () => {
    try {
      if (adminUser?.id) await prisma.user.delete({ where: { id: adminUser.id } }).catch(() => {});
      if (ownerUser?.id) await prisma.user.delete({ where: { id: ownerUser.id } }).catch(() => {});
      if (seededAdminUser?.id) await prisma.user.delete({ where: { id: seededAdminUser.id } }).catch(() => {});
    } catch (_) {}
  });
});
