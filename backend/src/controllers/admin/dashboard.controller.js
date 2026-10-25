import * as dashboardService from '../../services/admin/dashboardService.js';

export async function getDashboard(req, res, next) {
  try {
    const metrics = await dashboardService.getDashboardMetrics();
    res.status(200).json({
      success: true,
      data: metrics,
    });
  } catch (err) {
    next(err);
  }
}
