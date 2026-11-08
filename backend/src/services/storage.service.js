import fs from 'fs';
import path from 'path';
import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config/env.js';
import { logger } from '../config/logger.js';
import { BadRequestError } from '../utils/errors.js';

// Allowed MIME types and corresponding magic numbers
const MAGIC_NUMBERS = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47],
  'image/webp': [0x52, 0x49, 0x46, 0x46], // "RIFF"
};

/**
 * Validates file buffer magic bytes against expected image formats.
 * Prevents disguised executable / malicious payloads from being stored.
 *
 * @param {Buffer} buffer
 * @returns {string|null} verified MIME type or null
 */
export function validateImageMagicBytes(buffer) {
  if (!buffer || buffer.length < 12) return null;

  // Check JPEG
  if (
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
    return 'image/jpeg';
  }

  // Check PNG
  if (
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47
  ) {
    return 'image/png';
  }

  // Check WebP: bytes 0-3 = "RIFF", bytes 8-11 = "WEBP"
  if (
    buffer[0] === 0x52 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x46 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  ) {
    return 'image/webp';
  }

  return null;
}

/**
 * Modular Image Storage Provider using local persistent filesystem.
 * Easily swappable for S3/MinIO/Cloudflare R2 without affecting controllers.
 */
class LocalStorageService {
  constructor() {
    this.baseDir = path.resolve(config.uploadDir);
    this._ensureBaseDirectories();
  }

  _ensureBaseDirectories() {
    try {
      fs.mkdirSync(path.join(this.baseDir, 'profiles'), { recursive: true });
      fs.mkdirSync(path.join(this.baseDir, 'inventory'), { recursive: true });
      fs.mkdirSync(path.join(this.baseDir, 'thumbnails', 'profiles'), { recursive: true });
      fs.mkdirSync(path.join(this.baseDir, 'thumbnails', 'inventory'), { recursive: true });
    } catch (err) {
      logger.error('Failed to create base upload directories:', err);
    }
  }

  /**
   * Processes and stores an owner's profile avatar.
   * Compresses to WebP (512x512 max), creates thumbnail (128x128).
   *
   * @param {Object} params
   * @param {string} params.ownerId
   * @param {Buffer} params.buffer
   * @param {string} params.originalFilename
   * @returns {Promise<Object>}
   */
  async saveProfileImage({ ownerId, buffer, originalFilename }) {
    const verifiedMime = validateImageMagicBytes(buffer);
    if (!verifiedMime) {
      throw new BadRequestError('Invalid image content. Only JPEG, PNG, and WebP are allowed.');
    }

    const imageId = uuidv4();
    const filename = `${imageId}.webp`;

    const userProfileDir = path.join(this.baseDir, 'profiles', ownerId);
    const userThumbDir = path.join(this.baseDir, 'thumbnails', 'profiles', ownerId);

    fs.mkdirSync(userProfileDir, { recursive: true });
    fs.mkdirSync(userThumbDir, { recursive: true });

    const fullPath = path.join(userProfileDir, filename);
    const thumbPath = path.join(userThumbDir, filename);

    // 1. Process full profile avatar with sharp (max 512x512, square crop/fit)
    const processedImage = await sharp(buffer)
      .resize(512, 512, { fit: 'cover', position: 'center' })
      .webp({ quality: 85 })
      .toFile(fullPath);

    // 2. Generate small avatar thumbnail (128x128)
    await sharp(buffer)
      .resize(128, 128, { fit: 'cover', position: 'center' })
      .webp({ quality: 75 })
      .toFile(thumbPath);

    const relativeUrl = `/uploads/profiles/${ownerId}/${filename}`;
    const relativeThumbUrl = `/uploads/thumbnails/profiles/${ownerId}/${filename}`;

    return {
      imageId,
      filename,
      relativeUrl,
      relativeThumbUrl,
      storagePath: fullPath,
      thumbnailStoragePath: thumbPath,
      width: processedImage.width,
      height: processedImage.height,
      fileSize: processedImage.size,
      mimeType: 'image/webp',
    };
  }

  /**
   * Processes and stores an inventory spare-part image.
   * Compresses to WebP (max 1600x1600), creates thumbnail (320x320).
   *
   * @param {Object} params
   * @param {string} params.ownerId
   * @param {string} params.partId
   * @param {Buffer} params.buffer
   * @param {string} params.originalFilename
   * @returns {Promise<Object>}
   */
  async saveInventoryImage({ ownerId, partId, buffer, originalFilename }) {
    const verifiedMime = validateImageMagicBytes(buffer);
    if (!verifiedMime) {
      throw new BadRequestError('Invalid image content. Only JPEG, PNG, and WebP are allowed.');
    }

    const imageId = uuidv4();
    const filename = `${imageId}.webp`;

    const partDir = path.join(this.baseDir, 'inventory', ownerId, partId);
    const thumbDir = path.join(this.baseDir, 'thumbnails', 'inventory', ownerId, partId);

    fs.mkdirSync(partDir, { recursive: true });
    fs.mkdirSync(thumbDir, { recursive: true });

    const fullPath = path.join(partDir, filename);
    const thumbPath = path.join(thumbDir, filename);

    // 1. Full Image: resize max 1600x1600 (without upscale), WebP q85
    const processedImage = await sharp(buffer)
      .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 85 })
      .toFile(fullPath);

    // 2. Thumbnail: resize 320x320 inside/cover, WebP q75
    await sharp(buffer)
      .resize(320, 320, { fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 75 })
      .toFile(thumbPath);

    const relativeUrl = `/uploads/inventory/${ownerId}/${partId}/${filename}`;
    const relativeThumbUrl = `/uploads/thumbnails/inventory/${ownerId}/${partId}/${filename}`;

    return {
      imageId,
      filename,
      relativeUrl,
      relativeThumbUrl,
      storagePath: fullPath,
      thumbnailStoragePath: thumbPath,
      width: processedImage.width,
      height: processedImage.height,
      fileSize: processedImage.size,
      mimeType: 'image/webp',
      originalFilename: originalFilename ? path.basename(originalFilename) : null,
    };
  }

  /**
   * Safely deletes a file from persistent storage.
   * Never throws if file does not exist.
   *
   * @param {string} filePath
   */
  async deleteFile(filePath) {
    if (!filePath) return;
    try {
      const resolved = path.isAbsolute(filePath)
        ? filePath
        : path.resolve(this.baseDir, filePath.replace(/^\/?(uploads\/)?/, ''));

      // Guard against path traversal outside uploadDir
      if (!resolved.startsWith(this.baseDir)) {
        logger.warn(`Blocked attempt to delete file outside uploadDir: ${filePath}`);
        return;
      }

      if (fs.existsSync(resolved)) {
        await fs.promises.unlink(resolved);
        logger.info(`Deleted file: ${resolved}`);
      }
    } catch (err) {
      logger.error(`Error deleting file at ${filePath}:`, err);
    }
  }

  /**
   * Safely deletes multiple files (e.g. image + thumbnail).
   *
   * @param {string[]} filePaths
   */
  async deleteFiles(filePaths) {
    if (!Array.isArray(filePaths)) return;
    await Promise.all(filePaths.map((p) => this.deleteFile(p)));
  }
}

export const storageService = new LocalStorageService();
