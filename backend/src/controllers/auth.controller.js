import * as authService from '../services/auth.service.js';

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
    const result = await authService.loginUser(req.body);
    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    const result = await authService.refreshUserToken({ refreshToken });
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
    const result = await authService.logoutUser(req.user.id, refreshToken);
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
