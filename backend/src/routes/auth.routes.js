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
import { uploadProfilePhoto, flexibleProfilePhotoUpload } from '../middleware/upload.middleware.js';

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

const adminAuthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // strict: 5 failed attempts per 15 min window
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  validate: { xForwardedForHeader: false },
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many admin authentication attempts. Please try again in 15 minutes.',
    },
  },
});



router.post('/register', authLimiter, validate(registerSchema), authController.register);
router.post('/login', authLimiter, validate(loginSchema), authController.login);
router.post('/admin/login', adminAuthLimiter, validate(loginSchema), authController.adminLogin);
router.post('/refresh', authLimiter, validate(refreshTokenSchema), authController.refresh);
// Logout handler supporting both Bearer auth and direct refreshToken revocation
router.post('/logout', (req, res, next) => {
  // If authorization header exists, try authenticating; otherwise let controller handle refreshToken
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    return authenticate(req, res, () => authController.logout(req, res, next));
  }
  return authController.logout(req, res, next);
});
router.post('/logout-all', authenticate, authController.logoutAll);
router.get('/me', authenticate, requireActive, authController.getMe);
router.get('/profile', authenticate, requireActive, authController.getMe);
router.post(
  '/profile/photo',
  authenticate,
  requireActive,
  flexibleProfilePhotoUpload,
  authController.uploadProfilePhoto
);
router.delete(
  '/profile/photo',
  authenticate,
  requireActive,
  authController.deleteProfilePhoto
);
router.post(
  '/change-password',
  authenticate,
  requireActive,
  validate(changePasswordSchema),
  authController.changePassword
);

export default router;
