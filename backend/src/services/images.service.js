import { prisma } from '../config/db.js';
import { storageService } from './storage.service.js';
import { BadRequestError, NotFoundError, ForbiddenError } from '../utils/errors.js';
import { logger } from '../config/logger.js';

export class ImagesService {
  /**
   * Uploads and replaces an owner's profile avatar.
   * Ensures fail-safe atomicity: previous photo is preserved if DB update fails.
   */
  async updateProfilePhoto({ userId, fileBuffer, originalFilename }) {
    if (!fileBuffer) {
      throw new BadRequestError('No image file provided for profile photo');
    }

    // 1. Fetch current user to inspect existing photoUrl
    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, photoUrl: true },
    });

    if (!currentUser) {
      throw new NotFoundError('User profile not found');
    }

    const previousPhotoUrl = currentUser.photoUrl;

    // 2. Process and save new profile photo to persistent storage
    const stored = await storageService.saveProfileImage({
      ownerId: userId,
      buffer: fileBuffer,
      originalFilename,
    });

    try {
      // 3. Update database record with new photo URL
      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: {
          photoUrl: stored.relativeUrl,
        },
        select: {
          id: true,
          businessName: true,
          photoUrl: true,
        },
      });

      // 4. Clean up previous image file only after successful database commit
      if (previousPhotoUrl && previousPhotoUrl.startsWith('/uploads/profiles/')) {
        await storageService.deleteFile(previousPhotoUrl);
        // Also attempt to delete old thumbnail if present
        const oldThumb = previousPhotoUrl.replace('/uploads/profiles/', '/uploads/thumbnails/profiles/');
        await storageService.deleteFile(oldThumb);
      }

      return {
        user: updatedUser,
        photoUrl: stored.relativeUrl,
        thumbnailUrl: stored.relativeThumbUrl,
      };
    } catch (err) {
      // If DB update fails, clean up the newly saved file so we don't leak orphaned files
      logger.error('Failed to update user profile photo in DB, cleaning up newly stored file:', err);
      await storageService.deleteFile(stored.storagePath);
      await storageService.deleteFile(stored.thumbnailStoragePath);
      throw err;
    }
  }

  /**
   * Removes an owner's profile avatar and resets to default.
   */
  async deleteProfilePhoto({ userId }) {
    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, photoUrl: true },
    });

    if (!currentUser) {
      throw new NotFoundError('User profile not found');
    }

    const oldUrl = currentUser.photoUrl;

    await prisma.user.update({
      where: { id: userId },
      data: { photoUrl: null },
    });

    if (oldUrl && oldUrl.startsWith('/uploads/profiles/')) {
      await storageService.deleteFile(oldUrl);
      const oldThumb = oldUrl.replace('/uploads/profiles/', '/uploads/thumbnails/profiles/');
      await storageService.deleteFile(oldThumb);
    }

    return { photoUrl: null };
  }

  /**
   * Uploads multiple or single images for an inventory spare part.
   * Automatically sets the first image as primary if none exists.
   */
  async uploadInventoryImages({ ownerId, partId, files }) {
    if (!files || files.length === 0) {
      throw new BadRequestError('At least one image file is required');
    }

    // 1. Verify part exists and belongs to this owner
    const part = await prisma.sparePart.findFirst({
      where: {
        id: partId,
        ownerId,
        deletedAt: null,
      },
      include: {
        images: {
          where: { deletedAt: null },
          select: { id: true, isPrimary: true },
        },
      },
    });

    if (!part) {
      throw new NotFoundError(`Spare part '${partId}' not found or access denied`);
    }

    const existingImages = part.images;
    const hasExistingPrimary = existingImages.some((img) => img.isPrimary);

    const savedRecords = [];
    const storedFilesToRollback = [];

    try {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const isPrimary = !hasExistingPrimary && i === 0 && savedRecords.length === 0;

        const stored = await storageService.saveInventoryImage({
          ownerId,
          partId,
          buffer: file.buffer,
          originalFilename: file.originalname,
        });

        storedFilesToRollback.push(stored.storagePath, stored.thumbnailStoragePath);

        const record = await prisma.inventoryImage.create({
          data: {
            id: stored.imageId,
            ownerId,
            partId,
            imageUrl: stored.relativeUrl,
            thumbnailUrl: stored.relativeThumbUrl,
            storagePath: stored.storagePath,
            thumbnailStoragePath: stored.thumbnailStoragePath,
            originalFilename: stored.originalFilename,
            mimeType: stored.mimeType,
            fileSize: stored.fileSize,
            width: stored.width,
            height: stored.height,
            isPrimary,
          },
        });

        // Update spare part's primary photoUrl if this is primary
        if (isPrimary) {
          await prisma.sparePart.update({
            where: { id: partId },
            data: { photoUrl: stored.relativeUrl },
          });
        }

        savedRecords.push(record);
      }

      return savedRecords;
    } catch (err) {
      logger.error('Failed to upload inventory images, rolling back stored files:', err);
      await storageService.deleteFiles(storedFilesToRollback);
      throw err;
    }
  }

  /**
   * Lists all active images for a spare part.
   */
  async getInventoryImages({ ownerId, partId }) {
    // Verify ownership
    const part = await prisma.sparePart.findFirst({
      where: { id: partId, ownerId, deletedAt: null },
      select: { id: true },
    });

    if (!part) {
      throw new NotFoundError(`Spare part '${partId}' not found or access denied`);
    }

    return prisma.inventoryImage.findMany({
      where: {
        partId,
        ownerId,
        deletedAt: null,
      },
      orderBy: [
        { isPrimary: 'desc' },
        { createdAt: 'asc' },
      ],
    });
  }

  /**
   * Sets a specific image as primary for a spare part.
   */
  async setPrimaryImage({ ownerId, partId, imageId }) {
    const image = await prisma.inventoryImage.findFirst({
      where: {
        id: imageId,
        partId,
        ownerId,
        deletedAt: null,
      },
    });

    if (!image) {
      throw new NotFoundError(`Image '${imageId}' not found for this spare part`);
    }

    // Atomically unset other primaries and set this one
    await prisma.$transaction([
      prisma.inventoryImage.updateMany({
        where: { partId, isPrimary: true },
        data: { isPrimary: false },
      }),
      prisma.inventoryImage.update({
        where: { id: imageId },
        data: { isPrimary: true },
      }),
      prisma.sparePart.update({
        where: { id: partId },
        data: { photoUrl: image.imageUrl },
      }),
    ]);

    return {
      ...image,
      isPrimary: true,
    };
  }

  /**
   * Deletes an individual inventory image.
   * If the deleted image was primary, promotes the next available image to primary.
   */
  async deleteInventoryImage({ ownerId, partId, imageId }) {
    const image = await prisma.inventoryImage.findFirst({
      where: {
        id: imageId,
        partId,
        ownerId,
        deletedAt: null,
      },
    });

    if (!image) {
      throw new NotFoundError(`Image '${imageId}' not found for this spare part`);
    }

    const wasPrimary = image.isPrimary;

    // Delete record from DB
    await prisma.inventoryImage.delete({
      where: { id: imageId },
    });

    // Delete files from storage
    if (image.storagePath) await storageService.deleteFile(image.storagePath);
    if (image.thumbnailStoragePath) await storageService.deleteFile(image.thumbnailStoragePath);

    // If was primary, reassign primary to next available image
    if (wasPrimary) {
      const nextImage = await prisma.inventoryImage.findFirst({
        where: { partId, deletedAt: null },
        orderBy: { createdAt: 'asc' },
      });

      if (nextImage) {
        await prisma.inventoryImage.update({
          where: { id: nextImage.id },
          data: { isPrimary: true },
        });
        await prisma.sparePart.update({
          where: { id: partId },
          data: { photoUrl: nextImage.imageUrl },
        });
      } else {
        await prisma.sparePart.update({
          where: { id: partId },
          data: { photoUrl: null },
        });
      }
    }

    return { success: true, imageId };
  }
}

export const imagesService = new ImagesService();
