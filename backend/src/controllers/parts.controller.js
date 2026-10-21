import path from 'path';
import fs from 'fs';
import * as partsService from '../services/parts.service.js';
import { NotFoundError, BadRequestError } from '../utils/errors.js';
import { config } from '../config/env.js';

export async function listParts(req, res, next) {
  try {
    const { search, brandId, categoryId, locationId, limit, offset } = req.query;
    const result = await partsService.listParts(req.user.id, {
      search,
      brandId,
      categoryId,
      locationId,
      limit,
      offset,
    });
    res.status(200).json({
      success: true,
      data: result.parts,
      meta: { total: result.total },
    });
  } catch (err) {
    next(err);
  }
}

export async function getPart(req, res, next) {
  try {
    const part = await partsService.getPartById(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      data: part,
    });
  } catch (err) {
    next(err);
  }
}

export async function createPart(req, res, next) {
  try {
    const part = await partsService.createPart(req.user.id, req.body);
    res.status(201).json({
      success: true,
      message: 'Spare part created successfully',
      data: part,
    });
  } catch (err) {
    next(err);
  }
}

export async function updatePart(req, res, next) {
  try {
    const part = await partsService.updatePart(req.user.id, req.params.id, req.body);
    res.status(200).json({
      success: true,
      message: 'Spare part updated successfully',
      data: part,
    });
  } catch (err) {
    next(err);
  }
}

export async function deletePart(req, res, next) {
  try {
    const result = await partsService.deletePart(req.user.id, req.params.id);
    res.status(200).json({
      success: true,
      message: result.message,
    });
  } catch (err) {
    next(err);
  }
}

export async function uploadPhoto(req, res, next) {
  try {
    if (!req.file) {
      throw new BadRequestError('No image file uploaded');
    }

    const part = await partsService.updatePartPhoto(req.user.id, req.params.id, req.file.filename);
    res.status(200).json({
      success: true,
      message: 'Part photo uploaded successfully',
      data: {
        photoUrl: `/api/v1/parts/${req.params.id}/photo`,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function getPartPhoto(req, res, next) {
  try {
    // 1. Verify part belongs to authenticated user (throws 404 if not found or belongs to another owner)
    const part = await partsService.getPartById(req.user.id, req.params.id);

    if (!part.photoUrl) {
      throw new NotFoundError('No photo associated with this spare part');
    }

    const filePath = path.resolve(config.uploadDir, 'parts', req.user.id, part.photoUrl);

    if (!fs.existsSync(filePath)) {
      throw new NotFoundError('Photo file not found on server storage');
    }

    // Serve private file safely
    res.sendFile(filePath);
  } catch (err) {
    next(err);
  }
}
