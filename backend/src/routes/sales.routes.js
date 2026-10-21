import { Router } from 'express';
import * as salesController from '../controllers/sales.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';
import { validate } from '../middleware/validate.middleware.js';
import { createSaleSchema } from '../validators/sales.validator.js';

const router = Router();

router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', salesController.listSales);
router.post('/', validate(createSaleSchema), salesController.createSale);
router.get('/:id', salesController.getSale);

export default router;
