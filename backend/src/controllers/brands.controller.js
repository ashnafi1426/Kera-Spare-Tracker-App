import * as brandsService from '../services/brands.service.js';

export async function listBrands(req, res, next) {
  try {
    const brands = await brandsService.listBrands(req.user.id);
    res.status(200).json({
      success: true,
      data: brands,
    });
  } catch (err) {
    next(err);
  }
}

export async function createCustomBrand(req, res, next) {
  try {
    const brand = await brandsService.createCustomBrand(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Custom brand created successfully',
      data: brand,
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteCustomBrand(req, res, next) {
  try {
    const result = await brandsService.deleteCustomBrand(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}
