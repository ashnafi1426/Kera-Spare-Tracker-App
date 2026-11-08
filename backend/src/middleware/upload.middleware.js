import multer from 'multer';
import { BadRequestError } from '../utils/errors.js';
import { config } from '../config/env.js';

// MIME types whitelist
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

function fileFilter(req, file, cb) {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    cb(
      new BadRequestError(
        `Invalid file format '${file.mimetype}'. Only JPEG, PNG, and WebP images are allowed.`
      ),
      false
    );
  }
}

// In-memory storage for immediate magic-byte validation and sharp compression
const memoryStorage = multer.memoryStorage();

export const uploadSingleProfilePhoto = multer({
  storage: memoryStorage,
  fileFilter,
  limits: {
    fileSize: config.maxFileSizeMb * 1024 * 1024, // 5MB
    files: 1,
  },
});

export const uploadInventoryImages = multer({
  storage: memoryStorage,
  fileFilter,
  limits: {
    fileSize: config.maxFileSizeMb * 1024 * 1024, // 5MB per file
    files: 10, // Max 10 images at once
  },
});

// Backward compatibility alias for single photo
export const uploadPartPhoto = uploadInventoryImages;
export const uploadProfilePhoto = uploadSingleProfilePhoto;
