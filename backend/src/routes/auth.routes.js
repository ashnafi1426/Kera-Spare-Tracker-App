import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import * as authController from '../controllers/auth.controller.js';
import { validate } from '../middleware/validate.middleware.js';
import {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  changePasswordSchema,
} from '../validators/auth.validator.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireActive } from '../middleware/status.middleware.js';

const router = Router();

// Rate limiting strictly applied to sensitive auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 requests per 15 min window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many authentication attempts. Please try again in 15 minutes.',
    },
  },
});

router.post('/register', authLimiter, validate(registerSchema), authController.register);
router.post('/login', authLimiter, validate(loginSchema), authController.login);
router.post('/refresh', validate(refreshTokenSchema), authController.refresh);
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, requireActive, authController.getMe);
router.get('/profile', authenticate, requireActive, authController.getMe);
router.post(
  '/change-password',
  authenticate,
  requireActive,
  validate(changePasswordSchema),
  authController.changePassword
);

export default router;
