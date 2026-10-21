import { ForbiddenError, UnauthorizedError } from '../utils/errors.js';

export function requireActive(req, res, next) {
  if (!req.user) {
    return next(new UnauthorizedError('Authentication required'));
  }

  if (req.user.status === 'SUSPENDED') {
    return next(
      new ForbiddenError('Account is suspended. Please contact system administration.')
    );
  }

  next();
}
