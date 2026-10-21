import bcrypt from 'bcryptjs';
import { config } from '../config/env.js';

export async function hashPassword(plainPassword) {
  return bcrypt.hash(plainPassword, config.bcryptSaltRounds);
}

export async function comparePassword(plainPassword, hashedPassword) {
  return bcrypt.compare(plainPassword, hashedPassword);
}
