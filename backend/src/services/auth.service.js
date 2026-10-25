import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { hashPassword, comparePassword } from '../utils/password.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt.js';
import {
  PhoneTakenError,
  InvalidCredentialsError,
  AccountSuspendedError,
  TokenExpiredError,
  InvalidTokenError,
  NotFoundError,
  TooManyRequestsError,
  ValidationError,
} from '../utils/errors.js';
import { ADMIN_PASSWORD_REGEX, normalizeEthiopianPhone } from '../validators/auth.validator.js';
import crypto from 'crypto';

// In-memory lockout tracking for Admin Login
// Key: 'ip:<ip>' and 'phone:<phone>'
const adminLoginAttempts = new Map();
const MAX_ADMIN_LOGIN_ATTEMPTS = 5;
const ADMIN_LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

export function getAdminLoginAttempt(key) {
  const record = adminLoginAttempts.get(key);
  if (!record) return null;
  const now = Date.now();
  if (record.lockedUntil && now > record.lockedUntil) {
    adminLoginAttempts.delete(key);
    return null;
  }
  if (!record.lockedUntil && now - record.firstAttemptAt > ADMIN_LOCKOUT_DURATION_MS) {
    adminLoginAttempts.delete(key);
    return null;
  }
  return record;
}

export function recordAdminLoginFailure(ip, phone) {
  const now = Date.now();
  const keys = [];
  if (ip) keys.push(`ip:${ip}`);
  if (phone) keys.push(`phone:${phone}`);

  for (const key of keys) {
    let record = adminLoginAttempts.get(key);
    if (
      !record ||
      (record.lockedUntil && now > record.lockedUntil) ||
      (!record.lockedUntil && now - record.firstAttemptAt > ADMIN_LOCKOUT_DURATION_MS)
    ) {
      record = { count: 1, firstAttemptAt: now, lockedUntil: null };
    } else {
      record.count += 1;
    }

    if (record.count >= MAX_ADMIN_LOGIN_ATTEMPTS) {
      record.lockedUntil = now + ADMIN_LOCKOUT_DURATION_MS;
    }
    adminLoginAttempts.set(key, record);
  }
}

export function clearAdminLoginAttempts(ip, phone) {
  if (ip) adminLoginAttempts.delete(`ip:${ip}`);
  if (phone) adminLoginAttempts.delete(`phone:${phone}`);
}

export function resetAllAdminLoginAttempts() {
  adminLoginAttempts.clear();
}

// Hash helper for storing refresh tokens securely in database
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export async function registerOwner({ phoneNumber, businessName, password, language = 'AMHARIC' }) {
  const existing = await prisma.user.findUnique({
    where: { phoneNumber },
  });

  if (existing) {
    throw new PhoneTakenError();
  }

  const passwordHash = await hashPassword(password);
  const userId = uuidv4();

  const user = await prisma.user.create({
    data: {
      id: userId,
      phoneNumber,
      businessName,
      passwordHash,
      role: 'OWNER',
      status: 'ACTIVE',
      language,
    },
    select: {
      id: true,
      phoneNumber: true,
      businessName: true,
      role: true,
      status: true,
      language: true,
      createdAt: true,
    },
  });

  // Issue access & refresh tokens
  const accessToken = signAccessToken({ id: user.id, role: user.role, status: user.status });
  const refreshToken = signRefreshToken({ id: user.id });

  // Store hashed refresh token in database (valid for 30 days)
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      id: uuidv4(),
      userId: user.id,
      tokenHash,
      expiresAt,
    },
  });

  return { user, accessToken, refreshToken };
}

export async function loginUser({ phoneNumber, password }) {
  const normalizedPhone = normalizeEthiopianPhone(phoneNumber);
  const user = await prisma.user.findFirst({
    where: {
      phoneNumber: normalizedPhone,
      deletedAt: null,
    },
  });


  if (!user) {
    throw new InvalidCredentialsError();
  }

  const isPasswordValid = await comparePassword(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new InvalidCredentialsError();
  }

  if (user.status === 'SUSPENDED') {
    throw new AccountSuspendedError(
      'Account is suspended. Please contact system administrator.',
      user.suspendedReason ? { reason: user.suspendedReason } : null
    );
  }

  // Generate tokens
  const accessToken = signAccessToken({ id: user.id, role: user.role, status: user.status });
  const refreshToken = signRefreshToken({ id: user.id });

  // Store hashed refresh token
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      id: uuidv4(),
      userId: user.id,
      tokenHash,
      expiresAt,
    },
  });

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  return {
    user: {
      id: user.id,
      phoneNumber: user.phoneNumber,
      businessName: user.businessName,
      role: user.role,
      status: user.status,
      language: user.language,
      mustChangePassword: user.mustChangePassword,
    },
    accessToken,
    refreshToken,
  };
}

export async function loginAdmin({ phoneNumber, password, ipAddress, userAgent }) {
  const normalizedPhone = normalizeEthiopianPhone(phoneNumber);

  // 1. Check for temporary lockout (per IP or per phone number)
  const ipKey = ipAddress ? `ip:${ipAddress}` : null;
  const phoneKey = `phone:${normalizedPhone}`;

  const ipAttempt = ipKey ? getAdminLoginAttempt(ipKey) : null;
  const phoneAttempt = getAdminLoginAttempt(phoneKey);

  if (
    (ipAttempt && ipAttempt.count >= MAX_ADMIN_LOGIN_ATTEMPTS) ||
    (phoneAttempt && phoneAttempt.count >= MAX_ADMIN_LOGIN_ATTEMPTS)
  ) {
    throw new TooManyRequestsError(
      'Too many failed login attempts. Account or IP temporarily locked for 15 minutes.'
    );
  }

  // 2. Uniform failure helper (prevents account enumeration)
  const failLogin = async () => {
    recordAdminLoginFailure(ipAddress, normalizedPhone);
    try {
      await prisma.auditLog.create({
        data: {
          id: uuidv4(),
          action: 'ADMIN_LOGIN_FAILED',
          ipAddress: ipAddress || null,
          userAgent: userAgent || null,
          newValue: { phoneNumber: normalizedPhone, reason: 'INVALID_CREDENTIALS' },
        },
      });
    } catch (e) {
      // audit logging error must not mask the authentication error
    }
    throw new InvalidCredentialsError('Invalid phone number or password.');
  };

  const user = await prisma.user.findFirst({
    where: {
      phoneNumber: normalizedPhone,
      deletedAt: null,
    },
  });

  // Non-existent user or user is not an administrator
  if (!user || user.role !== 'ADMIN') {
    await failLogin();
  }

  // Password verification
  const isPasswordValid = await comparePassword(password, user.passwordHash);
  if (!isPasswordValid) {
    await failLogin();
  }

  // Suspended administrator check
  if (user.status === 'SUSPENDED') {
    throw new AccountSuspendedError('Admin account is suspended. Please contact system administrator.');
  }

  // Successful login: clear lockout counters
  clearAdminLoginAttempts(ipAddress, normalizedPhone);

  // Generate tokens (role: 'ADMIN' gets 10m access token via jwt.js)
  const accessToken = signAccessToken({ id: user.id, role: user.role, status: user.status });
  const refreshToken = signRefreshToken({ id: user.id });

  // Store hashed refresh token
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      id: uuidv4(),
      userId: user.id,
      tokenHash,
      expiresAt,
    },
  });

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  // Audit successful login
  try {
    await prisma.auditLog.create({
      data: {
        id: uuidv4(),
        adminId: user.id,
        targetUserId: user.id,
        action: 'ADMIN_LOGIN_SUCCESS',
        ipAddress: ipAddress || null,
        userAgent: userAgent || null,
        newValue: { phoneNumber: user.phoneNumber },
      },
    });
  } catch (e) {}

  return {
    user: {
      id: user.id,
      phoneNumber: user.phoneNumber,
      businessName: user.businessName,
      role: user.role,
      status: user.status,
      language: user.language,
      mustChangePassword: user.mustChangePassword,
    },
    accessToken,
    refreshToken,
  };
}

export async function refreshUserToken({ refreshToken }) {
  if (!refreshToken) {
    throw new InvalidTokenError('Refresh token required');
  }

  // 1. Verify token signature
  const verifyResult = verifyRefreshToken(refreshToken);
  if (!verifyResult.valid) {
    if (verifyResult.expired) {
      throw new TokenExpiredError('Refresh token has expired. Please log in again.');
    }
    throw new InvalidTokenError('Invalid refresh token.');
  }

  const userId = verifyResult.decoded.id;
  const tokenHash = hashToken(refreshToken);

  // 2. Check token in database
  const storedToken = await prisma.refreshToken.findFirst({
    where: {
      userId,
      tokenHash,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
  });

  if (!storedToken) {
    throw new InvalidTokenError('Refresh token revoked or not found');
  }

  // 3. Verify user is still active
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
  });

  if (!user) {
    throw new InvalidTokenError('User not found');
  }

  if (user.status === 'SUSPENDED') {
    throw new AccountSuspendedError(
      'Account is suspended. Please contact system administrator.',
      user.suspendedReason ? { reason: user.suspendedReason } : null
    );
  }

  // 4. Revoke old refresh token (Token rotation)
  await prisma.refreshToken.update({
    where: { id: storedToken.id },
    data: { revokedAt: new Date() },
  });

  // 5. Issue new access token and rotated refresh token
  const newAccessToken = signAccessToken({ id: user.id, role: user.role, status: user.status });
  const newRefreshToken = signRefreshToken({ id: user.id });

  const newTokenHash = hashToken(newRefreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      id: uuidv4(),
      userId: user.id,
      tokenHash: newTokenHash,
      expiresAt,
    },
  });

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  };
}

export async function logoutUser(userId, refreshToken) {
  if (refreshToken) {
    const tokenHash = hashToken(refreshToken);
    await prisma.refreshToken.updateMany({
      where: {
        userId,
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  } else {
    // Revoke all active tokens for this user
    await prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  return { message: 'Logged out successfully' };
}

export async function changeUserPassword(userId, { currentPassword, newPassword }) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw new NotFoundError('User not found.');
  }

  // If user is ADMIN, enforce strong 12+ character password policy
  if (user.role === 'ADMIN') {
    if (!ADMIN_PASSWORD_REGEX.test(newPassword)) {
      throw new ValidationError(
        'Admin password must be at least 12 characters long and contain a mix of uppercase letters, lowercase letters, numbers, and symbols.'
      );
    }
  }

  const isValid = await comparePassword(currentPassword, user.passwordHash);
  if (!isValid) {
    throw new InvalidCredentialsError('Current password is incorrect.');
  }

  const newHash = await hashPassword(newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: newHash, mustChangePassword: false },
  });

  // Revoke existing refresh tokens on password change
  await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });

  // Issue new access & refresh tokens for the active session
  const accessToken = signAccessToken({ id: user.id, role: user.role, status: user.status });
  const refreshToken = signRefreshToken({ id: user.id });
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      id: uuidv4(),
      userId: user.id,
      tokenHash,
      expiresAt,
    },
  });

  return {
    message: 'Password updated successfully.',
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      phoneNumber: user.phoneNumber,
      businessName: user.businessName,
      role: user.role,
      status: user.status,
      language: user.language,
      mustChangePassword: false,
    },
  };
}

export async function getUserProfile(userId) {
  const user = await prisma.user.findFirst({
    where: { id: userId, deletedAt: null },
    select: {
      id: true,
      phoneNumber: true,
      businessName: true,
      role: true,
      status: true,
      language: true,
      mustChangePassword: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw new NotFoundError('User profile not found.');
  }

  return user;
}
