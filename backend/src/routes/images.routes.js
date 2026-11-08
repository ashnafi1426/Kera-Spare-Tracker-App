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

// All image operations require authentication, active status, and OWNER role
router.use(authenticate, requireActive, requireRole('OWNER'));

// ==========================================
// PROFILE IMAGE ROUTES
// ==========================================
router.post(
  '/profile/image',
  uploadSingleProfilePhoto.single('image'),
  imagesController.uploadProfileImage
);

// Fallback to field 'photo' for profile photo
router.post(
  '/profile/photo',
  uploadSingleProfilePhoto.single('photo'),
  imagesController.uploadProfileImage
);

router.delete('/profile/image', imagesController.deleteProfileImage);
router.delete('/profile/photo', imagesController.deleteProfileImage);

// ==========================================
// INVENTORY IMAGE ROUTES (/spare-parts/:id/images)
// ==========================================
router.post(
  '/spare-parts/:id/images',
  uploadInventoryImages.array('images', 10),
  imagesController.uploadInventoryImages
);

router.get('/spare-parts/:id/images', imagesController.getInventoryImages);

router.delete(
  '/spare-parts/:id/images/:imageId',
  imagesController.deleteInventoryImage
);

router.patch(
  '/spare-parts/:id/images/:imageId/primary',
  imagesController.setPrimaryInventoryImage
);

// Aliases for /parts/:id/images
router.post(
  '/parts/:id/images',
  uploadInventoryImages.array('images', 10),
  imagesController.uploadInventoryImages
);

router.get('/parts/:id/images', imagesController.getInventoryImages);

router.delete(
  '/parts/:id/images/:imageId',
  imagesController.deleteInventoryImage
);

router.patch(
  '/parts/:id/images/:imageId/primary',
  imagesController.setPrimaryInventoryImage
);

export default router;
