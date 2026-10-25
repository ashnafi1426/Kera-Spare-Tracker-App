import * as settingsService from '../../services/admin/settingsService.js';

export async function getMinAppVersion(req, res, next) {
  try {
    const value = await settingsService.getSetting('minAppVersion');
    res.status(200).json({ success: true, data: value });
  } catch (err) {
    next(err);
  }
}

export async function putMinAppVersion(req, res, next) {
  try {
    const updated = await settingsService.updateSetting(
      'minAppVersion',
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Minimum app version setting updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function getAnnouncement(req, res, next) {
  try {
    const value = await settingsService.getSetting('announcement');
    res.status(200).json({ success: true, data: value });
  } catch (err) {
    next(err);
  }
}

export async function putAnnouncement(req, res, next) {
  try {
    const updated = await settingsService.updateSetting(
      'announcement',
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Announcement updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function getMaintenance(req, res, next) {
  try {
    const value = await settingsService.getSetting('maintenanceMode');
    res.status(200).json({ success: true, data: value });
  } catch (err) {
    next(err);
  }
}

export async function putMaintenance(req, res, next) {
  try {
    const updated = await settingsService.updateSetting(
      'maintenanceMode',
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Maintenance mode updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}
