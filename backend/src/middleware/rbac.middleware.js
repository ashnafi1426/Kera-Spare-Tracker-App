import { ForbiddenError, UnauthorizedError } from '../utils/errors.js';

export function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError('Authentication required'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        new ForbiddenError(
          `Access forbidden: Requires role ${allowedRoles.join(' or ')}. Your role is ${req.user.role}.`
        )
      );
    }

    next();
  };
}
