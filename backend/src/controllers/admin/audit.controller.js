import * as auditService from '../../services/admin/auditService.js';

export async function listAuditLogs(req, res, next) {
  try {
    const { page, limit, adminId, targetUserId, action, startDate, endDate } = req.query;
    const result = await auditService.listAuditLogs({
      page,
      limit,
      adminId,
      targetUserId,
      action,
      startDate,
      endDate,
    });

    res.status(200).json({
      success: true,
      data: result.logs,
      meta: result.meta,
    });
  } catch (err) {
    next(err);
  }
}
