import * as usersService from '../../services/admin/usersService.js';

export async function listUsers(req, res, next) {
  try {
    const { page, limit, search, status, inactive, sortBy, sortOrder } = req.query;
    const result = await usersService.listUsers({
      page,
      limit,
      search,
      status,
      inactive,
      sortBy,
      sortOrder,
    });

    res.status(200).json({
      success: true,
      data: result.users,
      meta: result.meta,
    });
  } catch (err) {
    next(err);
  }
}

export async function getUserById(req, res, next) {
  try {
    const result = await usersService.getUserById(req.params.id);
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function suspendUser(req, res, next) {
  try {
    const updated = await usersService.suspendUser(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Account successfully suspended and session revoked',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function reactivateUser(req, res, next) {
  try {
    const updated = await usersService.reactivateUser(
      req.params.id,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Account successfully reactivated',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function updateUser(req, res, next) {
  try {
    const updated = await usersService.updateUser(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Account details updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function resetPassword(req, res, next) {
  try {
    const result = await usersService.resetPassword(
      req.params.id,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message:
        'Temporary password generated. The user must change password upon next login.',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function softDisableUser(req, res, next) {
  try {
    const updated = await usersService.softDisableUser(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Account has been soft-disabled',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}
