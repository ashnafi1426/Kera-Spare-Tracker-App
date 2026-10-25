import { verifyAccessToken } from '../utils/jwt.js';
import {
  UnauthorizedError,
  TokenExpiredError,
  AccountSuspendedError,
  PasswordChangeRequiredError,
} from '../utils/errors.js';
import prisma from '../config/db.js';

export async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Authentication token missing or invalid format', 'UNAUTHORIZED');
    }

    const token = authHeader.substring(7);
    const result = verifyAccessToken(token);

    if (!result.valid) {
      if (result.expired) {
        throw new TokenExpiredError();
      }
      throw new UnauthorizedError('Invalid authentication token', 'INVALID_TOKEN');
    }

    const decoded = result.decoded;

    // Verify user still exists in database and is not soft-deleted
    const user = await prisma.user.findFirst({
      where: {
        id: decoded.id,
        deletedAt: null,
      },
      select: {
        id: true,
        phoneNumber: true,
        businessName: true,
        role: true,
        status: true,
        language: true,
        appVersion: true,
        mustChangePassword: true,
        suspendedReason: true,
      },
    });

    if (!user) {
      throw new UnauthorizedError('User account not found or deactivated', 'INVALID_TOKEN');
    }

    // 1. Account suspension check: reject immediately with 403 ACCOUNT_SUSPENDED
    if (user.status === 'SUSPENDED') {
      const reasonDetails = user.suspendedReason ? { reason: user.suspendedReason } : null;
      throw new AccountSuspendedError('Account is suspended. Please contact system administrator.', reasonDetails);
    }

    // 2. Track X-App-Version header if provided
    const clientAppVersion = req.headers['x-app-version'];
    if (clientAppVersion && clientAppVersion !== user.appVersion) {
      prisma.user
        .update({
          where: { id: user.id },
          data: { appVersion: String(clientAppVersion).substring(0, 50) },
        })
        .catch(() => {});
    }

    // 3. Must Change Password check: if true, only change-password, me, and logout are allowed
    if (user.mustChangePassword) {
      const path = req.path || req.originalUrl || '';
      const isAllowed =
        path.endsWith('/change-password') ||
        path.endsWith('/me') ||
        path.endsWith('/profile') ||
        path.endsWith('/logout');

      if (!isAllowed) {
        throw new PasswordChangeRequiredError();
      }
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}
