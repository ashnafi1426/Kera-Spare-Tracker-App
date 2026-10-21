import prisma from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';
import { hashPassword, comparePassword } from '../utils/password.js';
import { signJwt } from '../utils/jwt.js';
import { ConflictError, UnauthorizedError, NotFoundError, BadRequestError } from '../utils/errors.js';

export async function registerOwner({ phoneNumber, businessName, password, language = 'AMHARIC' }) {
  // Normalize phone number (standard Ethiopian format e.g. +251...)
  let formattedPhone = phoneNumber.trim();
  if (formattedPhone.startsWith('09') || formattedPhone.startsWith('07')) {
    formattedPhone = `+251${formattedPhone.substring(1)}`;
  }

  const existing = await prisma.user.findUnique({
    where: { phoneNumber: formattedPhone },
  });

  if (existing) {
    throw new ConflictError('A business account with this phone number already exists.');
  }

  const passwordHash = await hashPassword(password);
  const userId = uuidv4();

  const user = await prisma.user.create({
    data: {
      id: userId,
      phoneNumber: formattedPhone,
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

  const token = signJwt({ id: user.id, role: user.role, status: user.status });

  return { user, token };
}

export async function loginUser({ phoneNumber, password }) {
  let formattedPhone = phoneNumber.trim();
  if (formattedPhone.startsWith('09') || formattedPhone.startsWith('07')) {
    formattedPhone = `+251${formattedPhone.substring(1)}`;
  }

  const user = await prisma.user.findFirst({
    where: {
      phoneNumber: formattedPhone,
      deletedAt: null,
    },
  });

  if (!user) {
    throw new UnauthorizedError('Invalid phone number or password.');
  }

  const isPasswordValid = await comparePassword(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new UnauthorizedError('Invalid phone number or password.');
  }

  if (user.status === 'SUSPENDED') {
    throw new UnauthorizedError('Account is suspended. Please contact system administrator.');
  }

  const token = signJwt({ id: user.id, role: user.role, status: user.status });

  return {
    user: {
      id: user.id,
      phoneNumber: user.phoneNumber,
      businessName: user.businessName,
      role: user.role,
      status: user.status,
      language: user.language,
    },
    token,
  };
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
    throw new BadRequestError('Current password is incorrect.');
  }

  const newHash = await hashPassword(newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: newHash },
  });

  return { message: 'Password updated successfully.' };
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
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw new NotFoundError('User profile not found.');
  }

  return user;
}
