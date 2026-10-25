import { Router } from 'express';
import * as syncController from '../controllers/sync.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';

const router = Router();

// Sync is gated by authentication and active status
router.use(authenticate, requireActive);

router.get('/pull', syncController.pullSync);
router.post('/push', syncController.pushSync);

export default router;
