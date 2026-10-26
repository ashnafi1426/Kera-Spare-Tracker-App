export class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class BadRequestError extends AppError {
  constructor(message = 'Bad Request', details = null) {
    super(message, 400, 'BAD_REQUEST', details);
  }
}

export class ValidationError extends AppError {
  constructor(message = 'Validation failed', details = null) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized', code = 'UNAUTHORIZED') {
    super(message, 401, code);
  }
}

export class InvalidCredentialsError extends AppError {
  constructor(message = 'Invalid phone number or password') {
    super(message, 401, 'INVALID_CREDENTIALS');
  }
}

export class TokenExpiredError extends AppError {
  constructor(message = 'Authentication token has expired') {
    super(message, 401, 'TOKEN_EXPIRED');
  }
}

export class InvalidTokenError extends AppError {
  constructor(message = 'Invalid or revoked token') {
    super(message, 401, 'INVALID_TOKEN');
  }
}

export class TokenReusedError extends AppError {
  constructor(message = 'Refresh token already used. Session compromised.') {
    super(message, 401, 'TOKEN_REUSED');
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden', code = 'FORBIDDEN') {
    super(message, 403, code);
  }
}

export class AccountSuspendedError extends AppError {
  constructor(message = 'Account is suspended. Please contact system administrator.', details = null) {
    super(message, 403, 'ACCOUNT_SUSPENDED', details);
  }
}

export class PasswordChangeRequiredError extends AppError {
  constructor(message = 'Password change is required before accessing other resources.') {
    super(message, 403, 'PASSWORD_CHANGE_REQUIRED');
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found', code = 'NOT_FOUND') {
    super(message, 404, code);
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Resource already exists', code = 'CONFLICT') {
    super(message, 409, code);
  }
}

export class PhoneTakenError extends AppError {
  constructor(message = 'A business account with this phone number already exists.') {
    super(message, 409, 'PHONE_TAKEN');
  }
}

export class TooManyRequestsError extends AppError {
  constructor(message = 'Too many requests. Please try again later.', code = 'TOO_MANY_REQUESTS') {
    super(message, 429, code);
  }
}

