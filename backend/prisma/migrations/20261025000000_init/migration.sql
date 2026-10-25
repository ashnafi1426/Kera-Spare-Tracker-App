-- CreateTable
CREATE TABLE `brands` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NULL,
    `name` VARCHAR(100) NOT NULL,
    `isGlobal` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `brands_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `categories` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `categories_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `locations` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `locations_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `refresh_tokens` (
    `id` CHAR(36) NOT NULL,
    `userId` CHAR(36) NOT NULL,
    `tokenHash` VARCHAR(255) NOT NULL,
    `expiresAt` TIMESTAMP(6) NOT NULL,
    `revokedAt` TIMESTAMP(6) NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    INDEX `refresh_tokens_userId_idx`(`userId` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `sale_items` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `saleId` CHAR(36) NOT NULL,
    `partId` CHAR(36) NULL,
    `partNameSnapshot` VARCHAR(200) NOT NULL,
    `quantity` DECIMAL(12, 3) NOT NULL,
    `unitCostSnapshot` DECIMAL(12, 2) NOT NULL,
    `unitPriceSnapshot` DECIMAL(12, 2) NOT NULL,
    `subtotal` DECIMAL(12, 2) NOT NULL,
    `profit` DECIMAL(12, 2) NOT NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `sale_items_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    INDEX `sale_items_partId_fkey`(`partId` ASC),
    INDEX `sale_items_saleId_idx`(`saleId` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `sales` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `receiptNumber` VARCHAR(50) NOT NULL,
    `totalAmount` DECIMAL(12, 2) NOT NULL,
    `totalProfit` DECIMAL(12, 2) NOT NULL,
    `paymentMethod` ENUM('CASH', 'BANK_TRANSFER', 'CREDIT') NOT NULL DEFAULT 'CASH',
    `customerName` VARCHAR(100) NULL,
    `customerPhone` VARCHAR(20) NULL,
    `notes` TEXT NULL,
    `soldAt` TIMESTAMP(6) NOT NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `sales_ownerId_soldAt_idx`(`ownerId` ASC, `soldAt` ASC),
    INDEX `sales_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `spare_parts` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `partNumber` VARCHAR(100) NULL,
    `photoUrl` VARCHAR(500) NULL,
    `brandId` CHAR(36) NULL,
    `categoryId` CHAR(36) NULL,
    `locationId` CHAR(36) NULL,
    `customLocation` VARCHAR(100) NULL,
    `description` TEXT NULL,
    `unit` VARCHAR(50) NULL,
    `cachedQuantity` DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    `purchasePrice` DECIMAL(12, 2) NULL,
    `sellingPrice` DECIMAL(12, 2) NULL,
    `notes` TEXT NULL,
    `sizeSpecs` VARCHAR(100) NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `spare_parts_brandId_fkey`(`brandId` ASC),
    INDEX `spare_parts_categoryId_fkey`(`categoryId` ASC),
    INDEX `spare_parts_locationId_fkey`(`locationId` ASC),
    INDEX `spare_parts_ownerId_name_idx`(`ownerId` ASC, `name` ASC),
    INDEX `spare_parts_ownerId_partNumber_idx`(`ownerId` ASC, `partNumber` ASC),
    INDEX `spare_parts_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_movements` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `partId` CHAR(36) NOT NULL,
    `movementType` ENUM('PURCHASE', 'SALE', 'ADJUSTMENT_IN', 'ADJUSTMENT_OUT', 'RETURN') NOT NULL,
    `quantity` DECIMAL(12, 3) NOT NULL,
    `unitCost` DECIMAL(12, 2) NULL,
    `reason` VARCHAR(255) NULL,
    `referenceId` VARCHAR(100) NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `stock_movements_ownerId_partId_idx`(`ownerId` ASC, `partId` ASC),
    INDEX `stock_movements_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    INDEX `stock_movements_partId_fkey`(`partId` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `subscriptions` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NOT NULL,
    `plan` ENUM('FREE', 'STANDARD', 'PREMIUM') NOT NULL DEFAULT 'FREE',
    `status` ENUM('ACTIVE', 'EXPIRED', 'TRIAL') NOT NULL DEFAULT 'ACTIVE',
    `startDate` TIMESTAMP(6) NOT NULL,
    `endDate` TIMESTAMP(6) NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `subscriptions_ownerId_updatedAt_idx`(`ownerId` ASC, `updatedAt` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `users` (
    `id` CHAR(36) NOT NULL,
    `phoneNumber` VARCHAR(20) NOT NULL,
    `businessName` VARCHAR(100) NOT NULL,
    `passwordHash` VARCHAR(255) NOT NULL,
    `role` ENUM('OWNER', 'ADMIN') NOT NULL DEFAULT 'OWNER',
    `status` ENUM('ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    `language` ENUM('AMHARIC', 'ENGLISH') NOT NULL DEFAULT 'AMHARIC',
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    UNIQUE INDEX `users_phoneNumber_key`(`phoneNumber` ASC),
    PRIMARY KEY (`id` ASC)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `brands` ADD CONSTRAINT `brands_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `categories` ADD CONSTRAINT `categories_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `locations` ADD CONSTRAINT `locations_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `refresh_tokens` ADD CONSTRAINT `refresh_tokens_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sale_items` ADD CONSTRAINT `sale_items_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sale_items` ADD CONSTRAINT `sale_items_partId_fkey` FOREIGN KEY (`partId`) REFERENCES `spare_parts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sale_items` ADD CONSTRAINT `sale_items_saleId_fkey` FOREIGN KEY (`saleId`) REFERENCES `sales`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sales` ADD CONSTRAINT `sales_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `spare_parts` ADD CONSTRAINT `spare_parts_brandId_fkey` FOREIGN KEY (`brandId`) REFERENCES `brands`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `spare_parts` ADD CONSTRAINT `spare_parts_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `categories`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `spare_parts` ADD CONSTRAINT `spare_parts_locationId_fkey` FOREIGN KEY (`locationId`) REFERENCES `locations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `spare_parts` ADD CONSTRAINT `spare_parts_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_movements` ADD CONSTRAINT `stock_movements_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_movements` ADD CONSTRAINT `stock_movements_partId_fkey` FOREIGN KEY (`partId`) REFERENCES `spare_parts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `subscriptions` ADD CONSTRAINT `subscriptions_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
