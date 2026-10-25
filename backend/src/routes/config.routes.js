import { Router } from 'express';
import { getPublicAppConfig } from '../controllers/config.controller.js';

const router = Router();

// Public endpoint: unauthenticated so app can query before login
router.get('/app-config', getPublicAppConfig);

export default router;
