import * as syncService from '../services/sync.service.js';

export async function pullSync(req, res, next) {
  try {
    const { lastPulledAt } = req.query;
    const result = await syncService.pullSyncData(req.user.id, { lastPulledAt });
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
    const { batch } = req.body;
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
