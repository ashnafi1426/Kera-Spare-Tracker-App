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
} from '../utils/errors.js';
import crypto from 'crypto';

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
  const user = await prisma.user.findFirst({
    where: {
      phoneNumber,
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

  const isValid = await comparePassword(currentPassword, user.passwordHash);
  if (!isValid) {
    throw new InvalidCredentialsError('Current password is incorrect.');
  }

  const newHash = await hashPassword(newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: newHash, mustChangePassword: false },
  });

  // Revoke all refresh tokens on password change for security
  await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });

  return { message: 'Password updated successfully. Please log in with new password.' };
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
