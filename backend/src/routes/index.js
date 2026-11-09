import { Router } from 'express';
import authRoutes from './auth.routes.js';
import partsRoutes from './parts.routes.js';
import stockRoutes from './stock.routes.js';
import salesRoutes from './sales.routes.js';
import brandsRoutes from './brands.routes.js';
import categoriesRoutes from './categories.routes.js';
import locationsRoutes from './locations.routes.js';
import adminRoutes from './admin.routes.js';
import configRoutes from './config.routes.js';
import syncRoutes from './sync.routes.js';
import reportsRoutes from './reports.routes.js';
import imagesRoutes from './images.routes.js';

const router = Router();

// 1. Auth routes (Login, Register, Refresh, Logout) - must be first
router.use('/auth', authRoutes);

// 2. Config & Health routes
router.use('/config', configRoutes);
router.use('/', configRoutes);

// 3. Domain Entity routes
router.use('/sync', syncRoutes);
router.use('/parts', partsRoutes);
router.use('/stock', stockRoutes);
router.use('/sales', salesRoutes);
router.use('/brands', brandsRoutes);
router.use('/categories', categoriesRoutes);
router.use('/locations', locationsRoutes);
router.use('/reports', reportsRoutes);
router.use('/admin', adminRoutes);

// 4. Image upload & management routes
router.use('/', imagesRoutes);

export default router;
