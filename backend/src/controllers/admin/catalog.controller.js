import * as catalogService from '../../services/admin/catalogService.js';

// ==========================================
// BRANDS
// ==========================================

export async function listGlobalBrands(req, res, next) {
  try {
    const brands = await catalogService.listGlobalBrands();
    res.status(200).json({ success: true, data: brands });
  } catch (err) {
    next(err);
  }
}

export async function createGlobalBrand(req, res, next) {
  try {
    const brand = await catalogService.createGlobalBrand(req.body, req.user.id, req);
    res.status(201).json({
      success: true,
      message: 'Global brand created successfully',
      data: brand,
    });
  } catch (err) {
    next(err);
  }
}

export async function updateGlobalBrand(req, res, next) {
  try {
    const updated = await catalogService.updateGlobalBrand(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global brand updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function deactivateGlobalBrand(req, res, next) {
  try {
    const deactivated = await catalogService.deactivateGlobalBrand(
      req.params.id,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global brand deactivated successfully',
      data: deactivated,
    });
  } catch (err) {
    next(err);
  }
}

// ==========================================
// CATEGORIES
// ==========================================

export async function listGlobalCategories(req, res, next) {
  try {
    const categories = await catalogService.listGlobalCategories();
    res.status(200).json({ success: true, data: categories });
  } catch (err) {
    next(err);
  }
}

export async function createGlobalCategory(req, res, next) {
  try {
    const category = await catalogService.createGlobalCategory(
      req.body,
      req.user.id,
      req
    );
    res.status(201).json({
      success: true,
      message: 'Global category created successfully',
      data: category,
    });
  } catch (err) {
    next(err);
  }
}

export async function updateGlobalCategory(req, res, next) {
  try {
    const updated = await catalogService.updateGlobalCategory(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global category updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function deactivateGlobalCategory(req, res, next) {
  try {
    const deactivated = await catalogService.deactivateGlobalCategory(
      req.params.id,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global category deactivated successfully',
      data: deactivated,
    });
  } catch (err) {
    next(err);
  }
}

// ==========================================
// UNITS
// ==========================================

export async function listGlobalUnits(req, res, next) {
  try {
    const units = await catalogService.listGlobalUnits();
    res.status(200).json({ success: true, data: units });
  } catch (err) {
    next(err);
  }
}

export async function createGlobalUnit(req, res, next) {
  try {
    const unit = await catalogService.createGlobalUnit(
      req.body,
      req.user.id,
      req
    );
    res.status(201).json({
      success: true,
      message: 'Global unit created successfully',
      data: unit,
    });
  } catch (err) {
    next(err);
  }
}

export async function updateGlobalUnit(req, res, next) {
  try {
    const updated = await catalogService.updateGlobalUnit(
      req.params.id,
      req.body,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global unit updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

export async function deactivateGlobalUnit(req, res, next) {
  try {
    const deactivated = await catalogService.deactivateGlobalUnit(
      req.params.id,
      req.user.id,
      req
    );
    res.status(200).json({
      success: true,
      message: 'Global unit deactivated successfully',
      data: deactivated,
    });
  } catch (err) {
    next(err);
  }
}
