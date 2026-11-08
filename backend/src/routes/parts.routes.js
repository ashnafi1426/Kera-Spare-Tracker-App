import { Router } from 'express';
import * as partsController from '../controllers/parts.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { createPartSchema, updatePartSchema } from '../validators/parts.validator.js';
import { uploadPartPhoto, flexibleInventoryUpload } from '../middleware/upload.middleware.js';

const router = Router();

// Public streaming of part photo (allows standard <img> and Image.network to render)
router.get('/:id/photo', partsController.getPartPhoto);

// All spare parts mutation and list routes require authentication, active status, and OWNER role
router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', partsController.listParts);
router.post('/', validate(createPartSchema), partsController.createPart);
router.get('/:id', partsController.getPart);
router.put('/:id', validate(updatePartSchema), partsController.updatePart);
router.delete('/:id', partsController.deletePart);

// Photo upload and delete endpoints
router.post('/:id/photo', flexibleInventoryUpload, partsController.uploadPhoto);
router.delete('/:id/photo', partsController.deletePhoto);

export default router;
