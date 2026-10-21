import * as salesService from '../services/sales.service.js';

export async function createSale(req, res, next) {
  try {
    const sale = await salesService.recordSale(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Sale recorded and stock deducted successfully',
      data: sale,
    });
  } catch (err) {
    next(err);
  }
}

export async function listSales(req, res, next) {
  try {
    const { startDate, endDate, limit, offset } = req.query;
    const result = await salesService.listSales(req.user.id, { startDate, endDate, limit, offset });
    res.status(200).json({
      success: true,
      data: result.sales,
      meta: { total: result.total },
    });
  } catch (err) {
    next(err);
  }
}

export async function getSale(req, res, next) {
  try {
    const sale = await salesService.getSaleById(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      data: sale,
    });
  } catch (err) {
    next(err);
  }
}
