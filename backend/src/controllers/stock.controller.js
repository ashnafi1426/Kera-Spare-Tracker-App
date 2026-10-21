import * as stockService from '../services/stock.service.js';

export async function addStockMovement(req, res, next) {
  try {
    const result = await stockService.addStockMovement(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Stock movement recorded successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function listStockMovements(req, res, next) {
  try {
    const { partId, limit, offset } = req.query;
    const result = await stockService.listStockMovements(req.user.id, { partId, limit, offset });
    res.status(200).json({
      success: true,
      data: result.movements,
      meta: { total: result.total },
    });
  } catch (err) {
    next(err);
  }
}
