import { Router } from 'express';
import authRoutes from './auth.routes.js';
import partsRoutes from './parts.routes.js';
import stockRoutes from './stock.routes.js';
import salesRoutes from './sales.routes.js';
import brandsRoutes from './brands.routes.js';
import categoriesRoutes from './categories.routes.js';
import locationsRoutes from './locations.routes.js';
import adminRoutes from './admin.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/parts', partsRoutes);
router.use('/stock', stockRoutes);
router.use('/sales', salesRoutes);
router.use('/brands', brandsRoutes);
router.use('/categories', categoriesRoutes);
router.use('/locations', locationsRoutes);
router.use('/admin', adminRoutes);

export default router;
