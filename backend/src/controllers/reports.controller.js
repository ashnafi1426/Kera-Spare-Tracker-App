import * as reportsService from '../services/reports.service.js';

export async function getSummary(req, res, next) {
  try {
    const { period, startDate, endDate } = req.query;
    const result = await reportsService.getOwnerReportSummary(req.user.id, {
      period,
      startDate,
      endDate,
    });
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function getTrends(req, res, next) {
  try {
    const { period, startDate, endDate } = req.query;
    const result = await reportsService.getOwnerReportTrends(req.user.id, {
      period,
      startDate,
      endDate,
    });
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function getAdminSummary(req, res, next) {
  try {
    const { period } = req.query;
    const result = await reportsService.getAdminReportsSummary({ period });
    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

