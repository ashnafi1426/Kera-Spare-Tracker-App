import { Router } from 'express';
import * as catalogController from '../../controllers/admin/catalog.controller.js';
import { validate } from '../../middleware/validate.middleware.js';
import {
  createCatalogItemSchema,
  updateCatalogItemSchema,
} from '../../validators/admin/catalog.validator.js';

const router = Router();

// ==========================================
// BRANDS
// ==========================================
router.get('/brands', catalogController.listGlobalBrands);
router.post('/brands', validate(createCatalogItemSchema), catalogController.createGlobalBrand);
router.post('/brands/global', validate(createCatalogItemSchema), catalogController.createGlobalBrand); // backward compatibility
router.patch('/brands/:id', validate(updateCatalogItemSchema), catalogController.updateGlobalBrand);
router.delete('/brands/:id', catalogController.deactivateGlobalBrand);
router.patch('/brands/:id/deactivate', catalogController.deactivateGlobalBrand);

// ==========================================
// CATEGORIES
// ==========================================
router.get('/categories', catalogController.listGlobalCategories);
router.post('/categories', validate(createCatalogItemSchema), catalogController.createGlobalCategory);
router.patch('/categories/:id', validate(updateCatalogItemSchema), catalogController.updateGlobalCategory);
router.delete('/categories/:id', catalogController.deactivateGlobalCategory);
router.patch('/categories/:id/deactivate', catalogController.deactivateGlobalCategory);

// ==========================================
// UNITS
// ==========================================
router.get('/units', catalogController.listGlobalUnits);
router.post('/units', validate(createCatalogItemSchema), catalogController.createGlobalUnit);
router.patch('/units/:id', validate(updateCatalogItemSchema), catalogController.updateGlobalUnit);
router.delete('/units/:id', catalogController.deactivateGlobalUnit);
router.patch('/units/:id/deactivate', catalogController.deactivateGlobalUnit);

export default router;
