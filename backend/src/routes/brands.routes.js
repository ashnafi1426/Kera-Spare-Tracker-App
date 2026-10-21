import { Router } from 'express';
import * as brandsController from '../controllers/brands.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';

const router = Router();

router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', brandsController.listBrands);
router.post('/custom', brandsController.createCustomBrand);
router.delete('/custom/:id', brandsController.deleteCustomBrand);

export default router;
