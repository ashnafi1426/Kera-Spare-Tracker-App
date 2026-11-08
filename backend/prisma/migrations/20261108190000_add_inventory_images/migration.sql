-- CreateTable
CREATE TABLE `inventory_images` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `partId` CHAR(36) NOT NULL,
    `imageUrl` VARCHAR(500) NOT NULL,
    `thumbnailUrl` VARCHAR(500) NULL,
    `storagePath` VARCHAR(500) NOT NULL,
    `thumbnailStoragePath` VARCHAR(500) NULL,
    `originalFilename` VARCHAR(255) NULL,
    `mimeType` VARCHAR(50) NOT NULL,
    `fileSize` INTEGER NOT NULL,
    `width` INTEGER NULL,
    `height` INTEGER NULL,
    `isPrimary` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `inventory_images_ownerId_partId_idx`(`ownerId`, `partId`),
    INDEX `inventory_images_ownerId_updatedAt_idx`(`ownerId`, `updatedAt`),
    INDEX `inventory_images_partId_isPrimary_idx`(`partId`, `isPrimary`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `inventory_images` ADD CONSTRAINT `inventory_images_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `inventory_images` ADD CONSTRAINT `inventory_images_partId_fkey` FOREIGN KEY (`partId`) REFERENCES `spare_parts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

