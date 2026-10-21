import { Router } from 'express';
import * as stockController from '../controllers/stock.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';

const router = Router();

router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', stockController.listStockMovements);
router.post('/movements', stockController.addStockMovement);

export default router;
