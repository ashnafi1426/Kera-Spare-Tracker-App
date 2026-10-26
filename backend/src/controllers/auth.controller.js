import * as authService from '../services/auth.service.js';
import { ForbiddenError } from '../utils/errors.js';

export async function register(req, res, next) {
  try {
    const result = await authService.registerOwner(req.body);
    res.status(201).json({
      success: true,
      message: 'Business account created successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function login(req, res, next) {
  try {
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress;
    const result = await authService.loginUser({
      ...req.body,
      ipAddress,
    });
    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function adminLogin(req, res, next) {
  try {
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress;
    const userAgent = req.headers['user-agent'];
    const result = await authService.loginAdmin({
      phoneNumber: req.body.phoneNumber,
      password: req.body.password,
      ipAddress,
      userAgent,
    });
    res.status(200).json({
      success: true,
      message: 'Admin authentication successful',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}


export async function refresh(req, res, next) {
  try {
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress;
    const { refreshToken, deviceId, deviceName } = req.body;
    const result = await authService.refreshUserToken({
      refreshToken,
      deviceId,
      deviceName,
      ipAddress,
    });
    res.status(200).json({
      success: true,
      message: 'Token refreshed successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body;
    const result = await authService.logoutUser(req.user?.id, refreshToken);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}

export async function logoutAll(req, res, next) {
  try {
    const result = await authService.logoutAllDevices(req.user.id);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}

export async function getMe(req, res, next) {
  try {
    const user = await authService.getUserProfile(req.user.id);
    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (err) {
    next(err);
  }
}

export async function changePassword(req, res, next) {
  try {
    const result = await authService.changeUserPassword(req.user.id, req.body);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}
