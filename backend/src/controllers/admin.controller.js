import * as adminService from '../services/admin.service.js';

export async function listUsers(req, res, next) {
  try {
    const { limit, offset } = req.query;
    const result = await adminService.listAllUsers({ limit, offset });
    res.status(200).json({
      success: true,
      data: result.users,
      meta: { total: result.total },
    });
  } catch (err) {
    next(err);
  }
}

export async function updateUserStatus(req, res, next) {
  try {
    const updated = await adminService.updateUserStatus(req.params.id, req.body);
    res.status(200).json({
      success: true,
      message: `User status updated to ${updated.status}`,
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function createGlobalBrand(req, res, next) {
  try {
    const brand = await adminService.createGlobalBrand(req.body);
    res.status(201).json({
      success: true,
      message: 'Global brand created successfully',
      data: brand,
    });
  } catch (err) {
    next(err);
  }
}

export async function getStats(req, res, next) {
  try {
    const stats = await adminService.getSystemStats();
    res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (err) {
    next(err);
  }
}
