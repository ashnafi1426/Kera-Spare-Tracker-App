import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { BadRequestError } from '../utils/errors.js';
import { config } from '../config/env.js';

// MIME types whitelist
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // CRITICAL: Partition private photos by ownerId from verified JWT
    const ownerId = req.user?.id;
    if (!ownerId) {
      return cb(new BadRequestError('Authentication required before uploading media'), null);
    }

    const uploadPath = path.join(config.uploadDir, 'parts', ownerId);
    fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

function fileFilter(req, file, cb) {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new BadRequestError(
        `Invalid file type '${file.mimetype}'. Allowed formats: JPEG, PNG, WEBP.`
      ),
      false
    );
  }
}

export const uploadPartPhoto = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.maxFileSizeMb * 1024 * 1024, // 5MB default
  },
});
