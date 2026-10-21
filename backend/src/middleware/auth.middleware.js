import { verifyJwt } from '../utils/jwt.js';
import { UnauthorizedError } from '../utils/errors.js';
import prisma from '../config/db.js';

export async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Authentication token missing or invalid format');
    }

    const token = authHeader.substring(7);
    const decoded = verifyJwt(token);

    if (!decoded || !decoded.id) {
      throw new UnauthorizedError('Invalid or expired authentication token');
    }

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
      throw new UnauthorizedError('User account not found or deactivated');
    }

    // CRITICAL: Attach verified user object to request
    // ownerId MUST always be derived from req.user.id, NEVER from body/params/query
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}
