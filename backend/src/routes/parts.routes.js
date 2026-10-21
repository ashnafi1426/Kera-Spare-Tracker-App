import { Router } from 'express';
import * as partsController from '../controllers/parts.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { createPartSchema, updatePartSchema } from '../validators/parts.validator.js';
import { uploadPartPhoto } from '../middleware/upload.middleware.js';

const router = Router();

// All spare parts routes require authentication, active status, and OWNER role
router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', partsController.listParts);
router.post('/', validate(createPartSchema), partsController.createPart);
router.get('/:id', partsController.getPart);
router.put('/:id', validate(updatePartSchema), partsController.updatePart);
router.delete('/:id', partsController.deletePart);

// Private photo upload and streaming endpoints
router.post('/:id/photo', uploadPartPhoto.single('photo'), partsController.uploadPhoto);
router.get('/:id/photo', partsController.getPartPhoto);

export default router;
