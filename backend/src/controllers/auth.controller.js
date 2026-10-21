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

export async function getProfile(req, res, next) {
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
