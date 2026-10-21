import { verifyAccessToken } from '../utils/jwt.js';
import { UnauthorizedError, TokenExpiredError, AccountSuspendedError } from '../utils/errors.js';
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
      },
    });

    if (!user) {
      throw new UnauthorizedError('User account not found or deactivated', 'INVALID_TOKEN');
    }

    // Gating check: if user account is suspended, reject immediately with 403 ACCOUNT_SUSPENDED
    if (user.status === 'SUSPENDED') {
      throw new AccountSuspendedError();
    }

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}
