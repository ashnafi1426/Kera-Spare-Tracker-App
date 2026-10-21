import { Router } from 'express';
import * as locationsController from '../controllers/locations.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';

const router = Router();

router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', locationsController.listLocations);
router.post('/', locationsController.createLocation);
router.delete('/:id', locationsController.deleteLocation);

export default router;
