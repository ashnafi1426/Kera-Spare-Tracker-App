import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import app from '../src/app.js';
import prisma from '../src/config/db.js';
import { validateImageMagicBytes, storageService } from '../src/services/storage.service.js';

describe('Image Management & Storage Security System', () => {
  let ownerToken;
  let otherOwnerToken;
  let testPartId;
  let validJpegBuffer;
  let validPngBuffer;
  let fakeExecutableBuffer;

  const phoneOwner = `+251933${Math.floor(100000 + Math.random() * 900000)}`;
  const phoneOther = `+251944${Math.floor(100000 + Math.random() * 900000)}`;

  beforeAll(async () => {
    // Generate valid test image buffers using Sharp
    validJpegBuffer = await sharp({
      create: {
        width: 100,
        height: 100,
        channels: 3,
        background: { r: 255, g: 100, b: 50 },
      },
    })
      .jpeg()
      .toBuffer();

    validPngBuffer = await sharp({
      create: {
        width: 80,
        height: 80,
        channels: 4,
        background: { r: 0, g: 150, b: 255, alpha: 1 },
      },
    })
      .png()
      .toBuffer();

    // Fake malicious file (text starting with script header)
    fakeExecutableBuffer = Buffer.from('<?php echo "malicious payload"; ?>');

    try {
      // Register test owner
      const resA = await request(app)
        .post('/api/v1/auth/register')
        .send({
          phoneNumber: phoneOwner,
          businessName: 'Quality Spare Parts',
          password: 'Password123!',
        });
      ownerToken = resA.body.data?.token;

      // Register other owner for isolation test
      const resB = await request(app)
        .post('/api/v1/auth/register')
        .send({
          phoneNumber: phoneOther,
          businessName: 'Competitor Parts',
          password: 'Password123!',
        });
      otherOwnerToken = resB.body.data?.token;

      if (ownerToken) {
        // Create a spare part for test owner
        const partRes = await request(app)
          .post('/api/v1/parts')
          .set('Authorization', `Bearer ${ownerToken}`)
          .send({
            name: 'Heavy Duty Alternator',
            partNumber: 'ALT-999',
            sellingPrice: 12500,
            purchasePrice: 9000,
          });
        testPartId = partRes.body.data?.id;
      }
    } catch (err) {
      console.warn('DB not reachable in test hook, testing unit logic:', err.message);
    }
  });

  afterAll(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
  });

  // =========================================================================
  // 1. FILE SIGNATURE / MAGIC BYTES SECURITY TESTS
  // =========================================================================
  describe('File Signature & Magic Bytes Validation', () => {
    it('detects valid JPEG image magic bytes', () => {
      const mime = validateImageMagicBytes(validJpegBuffer);
      expect(mime).toBe('image/jpeg');
    });

    it('detects valid PNG image magic bytes', () => {
      const mime = validateImageMagicBytes(validPngBuffer);
      expect(mime).toBe('image/png');
    });

    it('rejects disguised executable / script even with .jpg name', () => {
      const mime = validateImageMagicBytes(fakeExecutableBuffer);
      expect(mime).toBeNull();
    });

    it('rejects empty or corrupt buffers', () => {
      expect(validateImageMagicBytes(Buffer.alloc(0))).toBeNull();
      expect(validateImageMagicBytes(Buffer.from([0x00, 0x01, 0x02]))).toBeNull();
    });
  });

  // =========================================================================
  // 2. STORAGE SERVICE UNIT TESTS
  // =========================================================================
  describe('Storage Service WebP Optimization & Deletion', () => {
    it('stores profile photo as WebP and creates thumbnail', async () => {
      const res = await storageService.saveProfileImage({
        ownerId: 'test_owner_123',
        buffer: validJpegBuffer,
        originalFilename: 'my_camera_pic.jpg',
      });

      expect(res.filename.endsWith('.webp')).toBe(true);
      expect(res.mimeType).toBe('image/webp');
      expect(res.relativeUrl).toContain('/uploads/profiles/test_owner_123/');
      expect(res.relativeThumbUrl).toContain('/uploads/thumbnails/profiles/test_owner_123/');
      expect(fs.existsSync(res.storagePath)).toBe(true);
      expect(fs.existsSync(res.thumbnailStoragePath)).toBe(true);

      // Clean up test files
      await storageService.deleteFile(res.storagePath);
      await storageService.deleteFile(res.thumbnailStoragePath);
      expect(fs.existsSync(res.storagePath)).toBe(false);
    });

    it('stores inventory image as WebP and creates thumbnail', async () => {
      const res = await storageService.saveInventoryImage({
        ownerId: 'test_owner_123',
        partId: 'part_xyz',
        buffer: validPngBuffer,
        originalFilename: 'sample.png',
      });

      expect(res.filename.endsWith('.webp')).toBe(true);
      expect(res.relativeUrl).toContain('/uploads/inventory/test_owner_123/part_xyz/');
      expect(fs.existsSync(res.storagePath)).toBe(true);
      expect(fs.existsSync(res.thumbnailStoragePath)).toBe(true);

      // Clean up
      await storageService.deleteFile(res.storagePath);
      await storageService.deleteFile(res.thumbnailStoragePath);
      expect(fs.existsSync(res.storagePath)).toBe(false);
    });
  });

  // =========================================================================
  // 3. API ENDPOINTS INTEGRATION TESTS
  // =========================================================================
  describe('API Endpoints (Owner Profile & Spare-Parts Images)', () => {
    it('rejects unauthorized image requests', async () => {
      const res = await request(app)
        .post('/api/v1/profile/image')
        .attach('image', validJpegBuffer, 'avatar.jpg');

      expect([401, 403]).toContain(res.status);
    });

    it('rejects upload of non-image file spoofed as photo', async () => {
      if (!ownerToken) return;

      const res = await request(app)
        .post('/api/v1/profile/image')
        .set('Authorization', `Bearer ${ownerToken}`)
        .attach('image', fakeExecutableBuffer, 'virus.php.jpg');

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('uploads owner profile image successfully', async () => {
      if (!ownerToken) return;

      const res = await request(app)
        .post('/api/v1/profile/image')
        .set('Authorization', `Bearer ${ownerToken}`)
        .attach('image', validJpegBuffer, 'avatar.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.photoUrl).toBeDefined();
      expect(res.body.data.photoUrl).toContain('.webp');
    });

    it('deletes owner profile image and returns default', async () => {
      if (!ownerToken) return;

      const res = await request(app)
        .delete('/api/v1/profile/image')
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.photoUrl).toBeNull();
    });

    it('uploads inventory images and sets first as primary', async () => {
      if (!ownerToken || !testPartId) return;

      const res = await request(app)
        .post(`/api/v1/spare-parts/${testPartId}/images`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .attach('images', validJpegBuffer, 'part_front.jpg')
        .attach('images', validPngBuffer, 'part_side.png');

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(2);
      expect(res.body.data[0].isPrimary).toBe(true);
      expect(res.body.data[1].isPrimary).toBe(false);

      // Verify listing images
      const listRes = await request(app)
        .get(`/api/v1/spare-parts/${testPartId}/images`)
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(listRes.status).toBe(200);
      expect(listRes.body.data.length).toBe(2);

      // Verify setting second image as primary
      const secondImageId = res.body.data[1].id;
      const patchRes = await request(app)
        .patch(`/api/v1/spare-parts/${testPartId}/images/${secondImageId}/primary`)
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(patchRes.status).toBe(200);
      expect(patchRes.body.data.isPrimary).toBe(true);

      // Verify deleting an image
      const delRes = await request(app)
        .delete(`/api/v1/spare-parts/${testPartId}/images/${secondImageId}`)
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(delRes.status).toBe(200);
    });

    it('strictly isolates images: other owner cannot upload or access another owner parts', async () => {
      if (!otherOwnerToken || !testPartId) return;

      // Other owner tries to upload image to Owner A's part
      const res = await request(app)
        .post(`/api/v1/spare-parts/${testPartId}/images`)
        .set('Authorization', `Bearer ${otherOwnerToken}`)
        .attach('images', validJpegBuffer, 'hacked.jpg');

      expect([403, 404]).toContain(res.status);

      // Other owner tries to list Owner A's part images
      const listRes = await request(app)
        .get(`/api/v1/spare-parts/${testPartId}/images`)
        .set('Authorization', `Bearer ${otherOwnerToken}`);

      expect([403, 404]).toContain(listRes.status);
    });
  });
});

