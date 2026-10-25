import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import { requireActive } from '../../middleware/status.middleware.js';
import { requireRole } from '../../middleware/rbac.middleware.js';

import dashboardRoutes from './dashboard.routes.js';
import usersRoutes from './users.routes.js';
import catalogRoutes from './catalog.routes.js';
import settingsRoutes from './settings.routes.js';
import auditRoutes from './audit.routes.js';
import * as dashboardController from '../../controllers/admin/dashboard.controller.js';

const router = Router();

// Gating middleware: authenticate, requireActive, requireRole('ADMIN')
router.use(authenticate, requireActive, requireRole('ADMIN'));

// Sub-routes
router.use('/dashboard', dashboardRoutes);
router.use('/users', usersRoutes);
router.use('/', catalogRoutes);
router.use('/settings', settingsRoutes);
router.use('/audit-logs', auditRoutes);

// Backward compatibility for /admin/stats
router.get('/stats', dashboardController.getDashboard);

export default router;
