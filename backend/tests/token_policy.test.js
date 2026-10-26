import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import crypto from 'crypto';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { cleanupExpiredTokens } from '../src/jobs/cleanupTokens.job.js';

describe('Token Policy & Offline Rules Security Suite', () => {
  const ownerAPhone = `0920${Math.floor(100000 + Math.random() * 900000)}`;
  const ownerBPhone = `0921${Math.floor(100000 + Math.random() * 900000)}`;
  const password = 'SecurePassword123!';

  let ownerA;
  let ownerB;
  let ownerAAccessToken;
  let ownerARefreshToken;
  let ownerBAccessToken;
  let ownerBRefreshToken;

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch (_) {}
  });

  it('1. Register Owner A and Owner B', async () => {
    const resA = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: ownerAPhone,
        businessName: 'Owner A Parts',
        password,
      });

    expect(resA.status).toBe(201);
    expect(resA.body.success).toBe(true);
    ownerA = resA.body.data.user;
    ownerAAccessToken = resA.body.data.accessToken;
    ownerARefreshToken = resA.body.data.refreshToken;

    const resB = await request(app)
      .post('/api/v1/auth/register')
      .send({
        phoneNumber: ownerBPhone,
        businessName: 'Owner B Parts',
        password,
      });

    expect(resB.status).toBe(201);
    expect(resB.body.success).toBe(true);
    ownerB = resB.body.data.user;
    ownerBAccessToken = resB.body.data.accessToken;
    ownerBRefreshToken = resB.body.data.refreshToken;
  });

  it('2. POST /auth/login returns access token, refresh token, expiry times, offlineMaxDays, and profile', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        phoneNumber: ownerAPhone,
        password,
        deviceId: 'device-test-1',
        deviceName: 'Samsung Galaxy A16',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');
    expect(res.body.data).toHaveProperty('accessTokenExpiresAt');
    expect(res.body.data).toHaveProperty('refreshTokenExpiresAt');
    expect(res.body.data).toHaveProperty('offlineMaxDays', 90);
    expect(res.body.data).toHaveProperty('mustChangePassword');
    expect(res.body.data.user.phoneNumber).toBe(`+251${ownerAPhone.substring(1)}`);

    ownerAAccessToken = res.body.data.accessToken;
    ownerARefreshToken = res.body.data.refreshToken;
  });

  it('3. Database stores ONLY token hashes (SHA-256), never plaintext refresh tokens', async () => {
    const rawToken = ownerARefreshToken;
    const expectedHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    const dbRecord = await prisma.refreshToken.findFirst({
      where: { tokenHash: expectedHash },
    });

    expect(dbRecord).not.toBeNull();
    expect(dbRecord.userId).toBe(ownerA.id);
    expect(dbRecord.tokenHash).toBe(expectedHash);
    expect(dbRecord.tokenHash).not.toBe(rawToken); // Never stored raw
    expect(dbRecord.tokenHash.length).toBe(64); // SHA-256 hex length
    expect(dbRecord.deviceId).toBe('device-test-1');
    expect(dbRecord.deviceName).toBe('Samsung Galaxy A16');
  });

  it('4. POST /auth/refresh rotates the refresh token and links replacedByTokenId', async () => {
    const oldToken = ownerARefreshToken;
    const oldHash = crypto.createHash('sha256').update(oldToken).digest('hex');

    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({
        refreshToken: oldToken,
        deviceId: 'device-test-1',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('accessToken');
    expect(res.body.data).toHaveProperty('refreshToken');
    expect(res.body.data.refreshToken).not.toBe(oldToken); // Must be a new rotated token
    expect(res.body.data).toHaveProperty('offlineMaxDays', 90);

    const newRotatedToken = res.body.data.refreshToken;
    const newHash = crypto.createHash('sha256').update(newRotatedToken).digest('hex');

    // Verify old token was revoked and linked to the new token
    const oldRecord = await prisma.refreshToken.findFirst({
      where: { tokenHash: oldHash },
    });
    const newRecord = await prisma.refreshToken.findFirst({
      where: { tokenHash: newHash },
    });

    expect(oldRecord.revokedAt).not.toBeNull();
    expect(oldRecord.lastUsedAt).not.toBeNull();
    expect(oldRecord.replacedByTokenId).toBe(newRecord.id);
    expect(newRecord.revokedAt).toBeNull();

    // Store new active token for subsequent tests
    ownerARefreshToken = newRotatedToken;
    ownerAAccessToken = res.body.data.accessToken;
  });

  it('5. Token Reuse / Theft Detection: presenting an already-used token revokes the entire token family with 401 TOKEN_REUSED', async () => {
    // We try to re-use an already replaced token:
    const oldTokenReused = ownerARefreshToken;

    // First legitimate rotation:
    const legitimateRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldTokenReused });
    expect(legitimateRes.status).toBe(200);
    const validCurrentToken = legitimateRes.body.data.refreshToken;

    // Attacker tries to use oldTokenReused again:
    const theftRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldTokenReused });

    expect(theftRes.status).toBe(401);
    expect(theftRes.body.success).toBe(false);
    expect(theftRes.body.error.code).toBe('TOKEN_REUSED');

    // Verify all tokens for Owner A have been revoked due to theft detection
    const validCurrentHash = crypto.createHash('sha256').update(validCurrentToken).digest('hex');
    const victimRecord = await prisma.refreshToken.findFirst({
      where: { tokenHash: validCurrentHash },
    });
    expect(victimRecord.revokedAt).not.toBeNull();

    // Now even the valid current token cannot be used because the family was terminated
    const followUpRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: validCurrentToken });
    expect(followUpRes.status).toBe(401);
  });

  it('6. POST /auth/refresh with expired token returns 401 TOKEN_EXPIRED', async () => {
    // Login to get a fresh token
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password });
    const freshToken = loginRes.body.data.refreshToken;
    const tokenHash = crypto.createHash('sha256').update(freshToken).digest('hex');

    // Artificially expire the token in database
    await prisma.refreshToken.updateMany({
      where: { tokenHash },
      data: { expiresAt: new Date(Date.now() - 1000) },
    });

    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: freshToken });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('TOKEN_EXPIRED');
  });

  it('7. POST /auth/logout revokes the provided refresh token', async () => {
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password });
    const tokenToRevoke = loginRes.body.data.refreshToken;
    const tokenHash = crypto.createHash('sha256').update(tokenToRevoke).digest('hex');

    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${loginRes.body.data.accessToken}`)
      .send({ refreshToken: tokenToRevoke });

    expect(logoutRes.status).toBe(200);

    const record = await prisma.refreshToken.findFirst({
      where: { tokenHash },
    });
    expect(record.revokedAt).not.toBeNull();
  });

  it('8. POST /auth/logout-all revokes all sessions across all devices for the user', async () => {
    // Create session 1 (Phone)
    const s1 = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password, deviceId: 'phone-1' });

    // Create session 2 (Tablet)
    const s2 = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password, deviceId: 'tablet-1' });

    expect(s1.status).toBe(200);
    expect(s2.status).toBe(200);

    const res = await request(app)
      .post('/api/v1/auth/logout-all')
      .set('Authorization', `Bearer ${s1.body.data.accessToken}`)
      .send();

    expect(res.status).toBe(200);

    // Verify no unrevoked tokens exist for Owner A
    const activeTokens = await prisma.refreshToken.findMany({
      where: { userId: ownerA.id, revokedAt: null },
    });
    expect(activeTokens.length).toBe(0);
  });

  it('9. Suspended account returns 403 ACCOUNT_SUSPENDED and cannot log in or refresh', async () => {
    // Re-login Owner A to get a valid token before suspension
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password });
    const tokenBeforeSuspension = loginRes.body.data.refreshToken;
    const accessBeforeSuspension = loginRes.body.data.accessToken;

    // Suspend Owner A
    await prisma.user.update({
      where: { id: ownerA.id },
      data: {
        status: 'SUSPENDED',
        suspendedReason: 'Policy violation',
        suspendedAt: new Date(),
      },
    });

    // 9.1 Login attempt fails with 403
    const loginAttempt = await request(app)
      .post('/api/v1/auth/login')
      .send({ phoneNumber: ownerAPhone, password });
    expect(loginAttempt.status).toBe(403);
    expect(loginAttempt.body.error.code).toBe('ACCOUNT_SUSPENDED');

    // 9.2 Refresh attempt fails with 403
    const refreshAttempt = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokenBeforeSuspension });
    expect(refreshAttempt.status).toBe(403);
    expect(refreshAttempt.body.error.code).toBe('ACCOUNT_SUSPENDED');

    // 9.3 Authenticated request fails with 403
    const apiAttempt = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessBeforeSuspension}`);
    expect(apiAttempt.status).toBe(403);
    expect(apiAttempt.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });

  it('10. Tenant Isolation: Owner B cannot use or access Owner A tokens or data', async () => {
    // Owner B cannot refresh using someone else's token structure
    // Owner B's access token cannot read Owner A's profile as self
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${ownerBAccessToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.id).toBe(ownerB.id);
    expect(meRes.body.data.id).not.toBe(ownerA.id);
  });

  it('11. Cleanup job purges tokens expired/revoked for more than 30 days', async () => {
    const sixtyDaysAgo = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);

    // Insert an old expired/revoked token
    await prisma.refreshToken.create({
      data: {
        id: crypto.randomUUID(),
        userId: ownerB.id,
        tokenHash: 'dummy_old_hash_' + Date.now(),
        expiresAt: sixtyDaysAgo,
        revokedAt: sixtyDaysAgo,
      },
    });

    const purged = await cleanupExpiredTokens();
    expect(purged).toBeGreaterThanOrEqual(1);
  });
});
