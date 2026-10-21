import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';

export function signJwt(payload, options = {}) {
  return jwt.sign(payload, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
    ...options,
  });
}

export function verifyJwt(token) {
  try {
    return jwt.verify(token, config.jwtSecret);
  } catch (err) {
    return null;
  }
}
