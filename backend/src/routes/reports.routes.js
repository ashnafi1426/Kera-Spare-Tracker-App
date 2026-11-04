import { Router } from 'express';
import * as reportsController from '../controllers/reports.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';

const router = Router();

router.use(authenticate, requireActive);

router.get('/summary', reportsController.getSummary);
router.get('/trends', reportsController.getTrends);

export default router;

