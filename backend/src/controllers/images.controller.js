import { imagesService } from '../services/images.service.js';
import { BadRequestError } from '../utils/errors.js';

/**
 * Controller handling Owner Profile and Inventory Spare Part images.
 */
export async function uploadProfileImage(req, res, next) {
  try {
    const file = req.file;
    if (!file) {
      throw new BadRequestError('No image uploaded. Pass multipart form file in "photo" or "image" field.');
    }

    const result = await imagesService.updateProfilePhoto({
      userId: req.user.id,
      fileBuffer: file.buffer,
      originalFilename: file.originalname,
    });

    res.status(200).json({
      success: true,
      message: 'Profile photo updated successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteProfileImage(req, res, next) {
  try {
    const result = await imagesService.deleteProfilePhoto({
      userId: req.user.id,
    });

    res.status(200).json({
      success: true,
      message: 'Profile photo removed successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function uploadInventoryImages(req, res, next) {
  try {
    const { id: partId } = req.params;
    const files = req.files || (req.file ? [req.file] : []);

    if (!files || files.length === 0) {
      throw new BadRequestError('No image uploaded. Pass files in "images" or "photos" field.');
    }

    const savedImages = await imagesService.uploadInventoryImages({
      ownerId: req.user.id,
      partId,
      files,
    });

    res.status(201).json({
      success: true,
      message: `${savedImages.length} image(s) uploaded successfully`,
      data: savedImages,
    });
  } catch (err) {
    next(err);
  }
}

export async function getInventoryImages(req, res, next) {
  try {
    const { id: partId } = req.params;

    const images = await imagesService.getInventoryImages({
      ownerId: req.user.id,
      partId,
    });

    res.status(200).json({
      success: true,
      data: images,
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteInventoryImage(req, res, next) {
  try {
    const { id: partId, imageId } = req.params;

    const result = await imagesService.deleteInventoryImage({
      ownerId: req.user.id,
      partId,
      imageId,
    });

    res.status(200).json({
      success: true,
      message: 'Image deleted successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
}

export async function setPrimaryInventoryImage(req, res, next) {
  try {
    const { id: partId, imageId } = req.params;

    const updated = await imagesService.setPrimaryImage({
      ownerId: req.user.id,
      partId,
      imageId,
    });

    res.status(200).json({
      success: true,
      message: 'Primary image updated successfully',
      data: updated,
    });
  } catch (err) {
    next(err);
  }
}

