import * as categoriesService from '../services/categories.service.js';

export async function listCategories(req, res, next) {
  try {
    const categories = await categoriesService.listCategories(req.user.id);
    res.status(200).json({
      success: true,
      data: categories,
    });
  } catch (err) {
    next(err);
  }
}

export async function createCategory(req, res, next) {
  try {
    const category = await categoriesService.createCategory(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: category,
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteCategory(req, res, next) {
  try {
    const result = await categoriesService.deleteCategory(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}
