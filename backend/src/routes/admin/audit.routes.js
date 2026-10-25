import { Router } from 'express';
import * as auditController from '../../controllers/admin/audit.controller.js';

const router = Router();

router.get('/', auditController.listAuditLogs);

export default router;
