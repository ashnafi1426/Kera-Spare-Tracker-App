import { Router } from 'express';
import * as settingsController from '../../controllers/admin/settings.controller.js';
import { validate } from '../../middleware/validate.middleware.js';
import {
  minAppVersionSchema,
  announcementSchema,
  maintenanceSchema,
} from '../../validators/admin/settings.validator.js';

const router = Router();

router.get('/min-app-version', settingsController.getMinAppVersion);
router.put('/min-app-version', validate(minAppVersionSchema), settingsController.putMinAppVersion);

router.get('/announcement', settingsController.getAnnouncement);
router.put('/announcement', validate(announcementSchema), settingsController.putAnnouncement);

router.get('/maintenance', settingsController.getMaintenance);
router.put('/maintenance', validate(maintenanceSchema), settingsController.putMaintenance);

export default router;
