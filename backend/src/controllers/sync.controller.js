import * as syncService from '../services/sync.service.js';
import prisma from '../config/db.js';

export async function pullSync(req, res, next) {
  try {
    const { lastPulledAt, cursor } = req.query;
    const result = await syncService.pullSyncData(req.user.id, {
      lastPulledAt: lastPulledAt || cursor,
    });
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function pushSync(req, res, next) {
  try {
    const batch = Array.isArray(req.body)
      ? req.body
      : (req.body?.batch || req.body?.operations || []);
    const result = await syncService.pushSyncData(req.user.id, batch);
    res.status(200).json({
      success: true,
      message: 'Batch synchronized successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function getSyncStatus(req, res, next) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { lastSyncAt: true, failedSyncCount: true },
    });
    res.status(200).json({
      success: true,
      data: {
        serverTimestamp: new Date().toISOString(),
        lastSyncAt: user?.lastSyncAt || null,
        failedSyncCount: user?.failedSyncCount || 0,
      },
    });
  } catch (err) {
    next(err);
  }
}
