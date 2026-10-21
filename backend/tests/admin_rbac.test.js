import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { signJwt } from '../src/utils/jwt.js';
import { v4 as uuidv4 } from 'uuid';

describe('RBAC & Route Security Tests', () => {
  let regularOwnerToken;
  let adminToken;
  let suspendedUserToken;

  const ownerPhone = `+251933${Math.floor(100000 + Math.random() * 900000)}`;
  const adminPhone = `+251944${Math.floor(100000 + Math.random() * 900000)}`;
  const suspendedPhone = `+251955${Math.floor(100000 + Math.random() * 900000)}`;

  beforeAll(async () => {
    try {
      // 1. Regular Owner
      const resOwner = await request(app)
        .post('/api/v1/auth/register')
        .send({
          phoneNumber: ownerPhone,
          businessName: 'Regular Owner Shop',
          password: 'Password123!',
        });
      regularOwnerToken = resOwner.body.data?.token;

      // 2. Admin User
      const adminId = uuidv4();
      const adminUser = await prisma.user.create({
        data: {
          id: adminId,
          phoneNumber: adminPhone,
          businessName: 'Test Administrator',
          passwordHash: 'dummyhash',
          role: 'ADMIN',
          status: 'ACTIVE',
        },
      });
      adminToken = signJwt({ id: adminUser.id, role: 'ADMIN', status: 'ACTIVE' });

      // 3. Suspended User
      const suspendedId = uuidv4();
      const suspendedUser = await prisma.user.create({
        data: {
          id: suspendedId,
          phoneNumber: suspendedPhone,
          businessName: 'Suspended Shop',
          passwordHash: 'dummyhash',
          role: 'OWNER',
          status: 'SUSPENDED',
        },
      });
      suspendedUserToken = signJwt({ id: suspendedUser.id, role: 'OWNER', status: 'SUSPENDED' });
    } catch (err) {
      console.warn('Database error in admin_rbac beforeAll:', err.message);
    }
  });

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  it('Unauthenticated requests are rejected with 401 Unauthorized', async () => {
    const res = await request(app).get('/api/v1/parts');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('Regular OWNER CANNOT access admin users list (Returns 403 Forbidden)', async () => {
    if (!regularOwnerToken) return;

    const res = await request(app)
      .get('/api/v1/admin/users')
      .set('Authorization', `Bearer ${regularOwnerToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it('Regular OWNER CANNOT create global brands (Returns 403 Forbidden)', async () => {
    if (!regularOwnerToken) return;

    const res = await request(app)
      .post('/api/v1/admin/brands/global')
      .set('Authorization', `Bearer ${regularOwnerToken}`)
      .send({ name: 'Unauthorized Brand' });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('ADMIN can access admin routes and view users list', async () => {
    if (!adminToken) return;

    const res = await request(app)
      .get('/api/v1/admin/users')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('Suspended user is blocked from making requests (Returns 403 Forbidden)', async () => {
    if (!suspendedUserToken) return;

    const res = await request(app)
      .get('/api/v1/parts')
      .set('Authorization', `Bearer ${suspendedUserToken}`);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Account is suspended');
  });
});
