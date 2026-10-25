import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config/env.js';

export function signAccessToken(payload) {
  const expiresIn =
    payload && payload.role === 'ADMIN'
      ? config.jwtAdminAccessExpiresIn
      : config.jwtAccessExpiresIn;

  return jwt.sign(payload, config.jwtSecret, {
    expiresIn,
  });
}

export function signRefreshToken(payload) {
  return jwt.sign({ ...payload, jti: uuidv4() }, config.jwtRefreshSecret, {
    expiresIn: config.jwtRefreshExpiresIn,
  });
}

// Backward compatible alias
export function signJwt(payload, options = {}) {
  return signAccessToken(payload);
}

export function verifyAccessToken(token) {
  try {
    return { valid: true, expired: false, decoded: jwt.verify(token, config.jwtSecret) };
  } catch (err) {
    return {
      valid: false,
      expired: err.name === 'TokenExpiredError',
      decoded: null,
      error: err.message,
    };
  }
}

export function verifyRefreshToken(token) {
  try {
    return { valid: true, expired: false, decoded: jwt.verify(token, config.jwtRefreshSecret) };
  } catch (err) {
    return {
      valid: false,
      expired: err.name === 'TokenExpiredError',
      decoded: null,
      error: err.message,
    };
  }
}

// Backward compatible alias
export function verifyJwt(token) {
  const result = verifyAccessToken(token);
  return result.valid ? result.decoded : null;
}
