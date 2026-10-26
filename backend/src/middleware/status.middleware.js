import { AccountSuspendedError, UnauthorizedError } from '../utils/errors.js';

export function requireActive(req, res, next) {
  if (!req.user) {
    return next(new UnauthorizedError('Authentication required'));
  }

  if (req.user.status === 'SUSPENDED' || req.user.disabledAt) {
    return next(new AccountSuspendedError());
  }

  next();
}
