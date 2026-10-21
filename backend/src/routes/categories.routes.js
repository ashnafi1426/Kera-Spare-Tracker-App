import { Router } from 'express';
import * as categoriesController from '../controllers/categories.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';
import { requireRole } from '../middleware/rbac.middleware.js';

const router = Router();

router.use(authenticate, requireActive, requireRole('OWNER'));

router.get('/', categoriesController.listCategories);
router.post('/', categoriesController.createCategory);
router.delete('/:id', categoriesController.deleteCategory);

export default router;
