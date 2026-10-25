import { Router } from 'express';
import * as usersController from '../../controllers/admin/users.controller.js';
import { validate } from '../../middleware/validate.middleware.js';
import {
  suspendUserSchema,
  updateUserSchema,
  softDisableUserSchema,
} from '../../validators/admin/users.validator.js';

const router = Router();

router.get('/', usersController.listUsers);
router.get('/:id', usersController.getUserById);
router.patch('/:id/suspend', validate(suspendUserSchema), usersController.suspendUser);
router.patch('/:id/reactivate', usersController.reactivateUser);
router.patch('/:id', validate(updateUserSchema), usersController.updateUser);
router.post('/:id/reset-password', usersController.resetPassword);
router.delete('/:id', validate(softDisableUserSchema), usersController.softDisableUser);

export default router;
