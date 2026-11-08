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

/**
 * Flexible profile photo upload handler.
 * Accepts multipart file field named 'photo', 'image', or 'avatar'.
 * Sets req.file reliably regardless of which field name the client sends.
 */
export const flexibleProfilePhotoUpload = (req, res, next) => {
  uploadSingleProfilePhoto.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'image', maxCount: 1 },
    { name: 'avatar', maxCount: 1 },
  ])(req, res, (err) => {
    if (err) return next(err);
    if (req.files) {
      req.file =
        req.files.photo?.[0] ||
        req.files.image?.[0] ||
        req.files.avatar?.[0] ||
        req.file;
    }
    next();
  });
};

/**
 * Flexible inventory images upload handler.
 * Accepts multiple or single images with fields 'images', 'photos', 'photo', or 'image'.
 * Sets req.files and req.file reliably.
 */
export const flexibleInventoryUpload = (req, res, next) => {
  uploadInventoryImages.fields([
    { name: 'images', maxCount: 10 },
    { name: 'photos', maxCount: 10 },
    { name: 'photo', maxCount: 1 },
    { name: 'image', maxCount: 1 },
  ])(req, res, (err) => {
    if (err) return next(err);
    if (req.files) {
      const allFiles = [
        ...(req.files.images || []),
        ...(req.files.photos || []),
        ...(req.files.photo || []),
        ...(req.files.image || []),
      ];
      req.files = allFiles;
      if (allFiles.length > 0 && !req.file) {
        req.file = allFiles[0];
      }
    }
    next();
  });
};
