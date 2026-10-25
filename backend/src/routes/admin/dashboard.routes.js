import { Router } from 'express';
import * as dashboardController from '../../controllers/admin/dashboard.controller.js';

const router = Router();

router.get('/', dashboardController.getDashboard);

export default router;
