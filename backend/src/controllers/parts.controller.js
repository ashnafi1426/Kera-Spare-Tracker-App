import path from 'path';
import fs from 'fs';
import prisma from '../config/db.js';
import * as partsService from '../services/parts.service.js';
import { imagesService } from '../services/images.service.js';
import { storageService } from '../services/storage.service.js';
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

    const savedImages = await imagesService.uploadInventoryImages({
      ownerId: req.user.id,
      partId: req.params.id,
      files: [req.file],
    });

    const primary = savedImages.find((img) => img.isPrimary) || savedImages[0];

    res.status(200).json({
      success: true,
      message: 'Part photo uploaded successfully',
      data: {
        photoUrl: primary.imageUrl,
        thumbnailUrl: primary.thumbnailUrl,
        image: primary,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function deletePhoto(req, res, next) {
  try {
    const part = await prisma.sparePart.findFirst({
      where: { id: req.params.id, ownerId: req.user.id, deletedAt: null },
    });
    if (!part) {
      throw new NotFoundError('Spare part not found');
    }

    if (part.photoUrl) {
      await storageService.deleteFile(part.photoUrl);
    }

    await prisma.sparePart.update({
      where: { id: req.params.id },
      data: { photoUrl: null },
    });

    res.status(200).json({
      success: true,
      message: 'Part photo removed successfully',
    });
  } catch (err) {
    next(err);
  }
}

export async function getPartPhoto(req, res, next) {
  try {
    const part = await prisma.sparePart.findFirst({
      where: { id: req.params.id, deletedAt: null },
    });

    if (!part || !part.photoUrl) {
      throw new NotFoundError('No photo associated with this spare part');
    }

    let filePath;
    if (part.photoUrl.includes('samples/')) {
      const filename = path.basename(part.photoUrl);
      filePath = path.resolve(config.uploadDir, 'parts', 'samples', filename);
    } else {
      const filename = path.basename(part.photoUrl);
      filePath = path.resolve(config.uploadDir, 'parts', part.ownerId, filename);
    }

    if (!fs.existsSync(filePath)) {
      throw new NotFoundError('Photo file not found on server storage');
    }

    res.sendFile(filePath);
  } catch (err) {
    next(err);
  }
}
