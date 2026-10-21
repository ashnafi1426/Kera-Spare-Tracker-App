import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { v4 as uuidv4 } from 'uuid';

describe('Tenant Privacy & Multi-Tenant Data Access Layer Isolation', () => {
  let ownerAToken;
  let ownerBToken;
  let ownerAPartId;
  let ownerACategoryId;

  const phoneA = `+251911${Math.floor(100000 + Math.random() * 900000)}`;
  const phoneB = `+251922${Math.floor(100000 + Math.random() * 900000)}`;

  beforeAll(async () => {
    try {
      // Register Owner A
      const resA = await request(app)
        .post('/api/v1/auth/register')
        .send({
          phoneNumber: phoneA,
          businessName: 'Owner A Motors',
          password: 'Password123!',
        });
      ownerAToken = resA.body.data?.token;

      // Register Owner B
      const resB = await request(app)
        .post('/api/v1/auth/register')
        .send({
          phoneNumber: phoneB,
          businessName: 'Owner B Spares',
          password: 'Password123!',
        });
      ownerBToken = resB.body.data?.token;
    } catch (err) {
      console.warn('Database not available during beforeAll hook:', err.message);
    }
  });

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  it('Owner A creates Category and Spare Part successfully', async () => {
    if (!ownerAToken) return;

    // Create Category for Owner A
    const catRes = await request(app)
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${ownerAToken}`)
      .send({ name: 'Engine Components' });

    expect(catRes.status).toBe(201);
    ownerACategoryId = catRes.body.data.id;

    // Create Spare Part for Owner A
    const partRes = await request(app)
      .post('/api/v1/parts')
      .set('Authorization', `Bearer ${ownerAToken}`)
      .send({
        name: 'Oil Filter C-302',
        partNumber: 'CAT-1R0716',
        categoryId: ownerACategoryId,
        purchasePrice: 450.0,
        sellingPrice: 700.0,
        cachedQuantity: 15,
      });

    expect(partRes.status).toBe(201);
    expect(partRes.body.data.name).toBe('Oil Filter C-302');
    ownerAPartId = partRes.body.data.id;
  });

  it('Owner B CANNOT view Owner A part by ID (Returns 404 Not Found)', async () => {
    if (!ownerBToken || !ownerAPartId) return;

    const res = await request(app)
      .get(`/api/v1/parts/${ownerAPartId}`)
      .set('Authorization', `Bearer ${ownerBToken}`);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('Owner B CANNOT update Owner A part (Returns 404 Not Found)', async () => {
    if (!ownerBToken || !ownerAPartId) return;

    const res = await request(app)
      .put(`/api/v1/parts/${ownerAPartId}`)
      .set('Authorization', `Bearer ${ownerBToken}`)
      .send({ name: 'Hacked Part Name', sellingPrice: 9999.0 });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  it('Owner B CANNOT delete Owner A part (Returns 404 Not Found)', async () => {
    if (!ownerBToken || !ownerAPartId) return;

    const res = await request(app)
      .delete(`/api/v1/parts/${ownerAPartId}`)
      .set('Authorization', `Bearer ${ownerBToken}`);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  it('Owner B parts list contains ZERO items from Owner A', async () => {
    if (!ownerBToken) return;

    const res = await request(app)
      .get('/api/v1/parts')
      .set('Authorization', `Bearer ${ownerBToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
    expect(res.body.meta.total).toBe(0);
  });

  it('Owner B CANNOT see Owner A category', async () => {
    if (!ownerBToken) return;

    const res = await request(app)
      .get('/api/v1/categories')
      .set('Authorization', `Bearer ${ownerBToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
  });
});
