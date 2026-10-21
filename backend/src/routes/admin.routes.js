import { Router } from 'express';
import * as adminController from '../controllers/admin.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';

const router = Router();

// Strict: ONLY users with role ADMIN and ACTIVE status can access these routes
router.use(authenticate, requireActive, requireRole('ADMIN'));

router.get('/users', adminController.listUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.post('/brands/global', adminController.createGlobalBrand);
router.get('/stats', adminController.getStats);

export default router;
