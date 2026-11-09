import { Router } from 'express';
import * as imagesController from '../controllers/images.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';
import {
  uploadSingleProfilePhoto,
  uploadInventoryImages,
} from '../middleware/upload.middleware.js';

const router = Router();

// Authentication middleware applied strictly to image routes
const imageAuth = [authenticate, requireActive, requireRole('OWNER')];

// ==========================================
// PROFILE IMAGE ROUTES
// ==========================================
router.post(
  '/profile/image',
  ...imageAuth,
  uploadSingleProfilePhoto.single('image'),
  imagesController.uploadProfileImage
);

// Fallback to field 'photo' for profile photo
router.post(
  '/profile/photo',
  ...imageAuth,
  uploadSingleProfilePhoto.single('photo'),
  imagesController.uploadProfileImage
);

router.delete('/profile/image', ...imageAuth, imagesController.deleteProfileImage);
router.delete('/profile/photo', ...imageAuth, imagesController.deleteProfileImage);

// ==========================================
// INVENTORY IMAGE ROUTES (/spare-parts/:id/images)
// ==========================================
router.post(
  '/spare-parts/:id/images',
  ...imageAuth,
  uploadInventoryImages.array('images', 10),
  imagesController.uploadInventoryImages
);

router.get('/spare-parts/:id/images', ...imageAuth, imagesController.getInventoryImages);

router.delete(
  '/spare-parts/:id/images/:imageId',
  ...imageAuth,
  imagesController.deleteInventoryImage
);

router.patch(
  '/spare-parts/:id/images/:imageId/primary',
  ...imageAuth,
  imagesController.setPrimaryInventoryImage
);

// Aliases for /parts/:id/images
router.post(
  '/parts/:id/images',
  ...imageAuth,
  uploadInventoryImages.array('images', 10),
  imagesController.uploadInventoryImages
);

router.get('/parts/:id/images', ...imageAuth, imagesController.getInventoryImages);

router.delete(
  '/parts/:id/images/:imageId',
  ...imageAuth,
  imagesController.deleteInventoryImage
);

router.patch(
  '/parts/:id/images/:imageId/primary',
  ...imageAuth,
  imagesController.setPrimaryInventoryImage
);

export default router;

