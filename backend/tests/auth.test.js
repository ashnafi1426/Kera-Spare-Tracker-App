import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { v4 as uuidv4 } from 'uuid';

describe('Authentication & Token Lifecycle Tests', () => {
  const testPhone = `0911${Math.floor(100000 + Math.random() * 900000)}`;
  let accessToken;
  let refreshToken;
  let userId;

  const suspendedPhone = `0977${Math.floor(100000 + Math.random() * 900000)}`;

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  it('1. POST /auth/register with valid phone creates user and returns tokens', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: testPhone,
        businessName: 'Kera Genuine Motors',
        password: 'Password123!',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('user');
    expect(res.body.data.user.phoneNumber).toBe(`+251${testPhone.substring(1)}`);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');

    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
    userId = res.body.data.user.id;
  });

  it('2. POST /auth/register with duplicate phone returns 409 PHONE_TAKEN', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: testPhone,
        businessName: 'Duplicate Shop',
        password: 'Password123!',
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('PHONE_TAKEN');
  });

  it('3. POST /auth/register with invalid phone returns 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: '12345',
        businessName: 'Bad Phone Shop',
        password: 'Password123!',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('4. POST /auth/login with correct credentials returns tokens', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        phoneNumber: testPhone,
        password: 'Password123!',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');

    // Update tokens
    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
  });

  it('5. POST /auth/login with wrong password returns 401 INVALID_CREDENTIALS', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        phoneNumber: testPhone,
        password: 'WrongPassword999!',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('6. POST /auth/login with non-existent phone returns 401 INVALID_CREDENTIALS', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        phoneNumber: '0911000000',
        password: 'Password123!',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('7. GET /auth/me returns authenticated profile', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe(userId);
    expect(res.body.data.businessName).toBe('Kera Genuine Motors');
  });

  it('8. POST /auth/refresh returns new access token and rotated refresh token', async () => {
    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');

    // Update to new rotated refresh token
    const oldRefreshToken = refreshToken;
    refreshToken = res.body.data.refreshToken;
    accessToken = res.body.data.accessToken;

    // 9. Old refresh token should now be revoked
    const oldRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldRefreshToken });

    expect(oldRes.status).toBe(401);
    expect(oldRes.body.error.code).toBe('INVALID_TOKEN');
  });

  it('10. POST /auth/logout revokes the refresh token', async () => {
    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken });

    expect(logoutRes.status).toBe(200);

    // Refreshing with logged out token should fail
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(401);
    expect(refreshRes.body.error.code).toBe('INVALID_TOKEN');
  });

  it('11. Suspended account gets 403 ACCOUNT_SUSPENDED', async () => {
    // Register and suspend
    const regRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: suspendedPhone,
        businessName: 'Suspended Motors',
        password: 'Password123!',
      });

    const suspUserId = regRes.body.data.user.id;
    const suspToken = regRes.body.data.accessToken;

    // Suspend user directly in DB
    await prisma.user.update({
      where: { id: suspUserId },
      data: { status: 'SUSPENDED' },
    });

    // Attempting login
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        phoneNumber: suspendedPhone,
        password: 'Password123!',
      });

    expect(loginRes.status).toBe(403);
    expect(loginRes.body.error.code).toBe('ACCOUNT_SUSPENDED');

    // Attempting authenticated request with existing token
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${suspToken}`);

    expect(meRes.status).toBe(403);
    expect(meRes.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });
});
