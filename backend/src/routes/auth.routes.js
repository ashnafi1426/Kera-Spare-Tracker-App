import { Router } from 'express';
import * as authController from '../controllers/auth.controller.js';
import { validate } from '../middleware/validate.middleware.js';
import { registerSchema, loginSchema, changePasswordSchema } from '../validators/auth.validator.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';

const router = Router();

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.get('/profile', authenticate, requireActive, authController.getProfile);
router.post(
  '/change-password',
  authenticate,
  requireActive,
  validate(changePasswordSchema),
  authController.changePassword
);

export default router;
