-- AlterTable
ALTER TABLE `brands` ADD COLUMN `isActive` BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE `categories` ADD COLUMN `isActive` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `isGlobal` BOOLEAN NOT NULL DEFAULT false,
    MODIFY `ownerId` CHAR(36) NULL;

-- AlterTable
ALTER TABLE `users` ADD COLUMN `appVersion` VARCHAR(50) NULL,
    ADD COLUMN `disabledAt` TIMESTAMP(6) NULL,
    ADD COLUMN `failedSyncCount` INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN `lastLoginAt` TIMESTAMP(6) NULL,
    ADD COLUMN `lastSyncAt` TIMESTAMP(6) NULL,
    ADD COLUMN `mustChangePassword` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `suspendedAt` TIMESTAMP(6) NULL,
    ADD COLUMN `suspendedReason` TEXT NULL;

-- CreateTable
CREATE TABLE `units` (
    `id` CHAR(36) NOT NULL,
    `ownerId` CHAR(36) NULL,
    `name` VARCHAR(50) NOT NULL,
    `isGlobal` BOOLEAN NOT NULL DEFAULT false,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    INDEX `units_ownerId_updatedAt_idx`(`ownerId`, `updatedAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `subscription_plans` (
    `id` CHAR(36) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `price` DECIMAL(12, 2) NOT NULL,
    `durationDays` INTEGER NOT NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `updatedAt` TIMESTAMP(6) NOT NULL,
    `deletedAt` TIMESTAMP(6) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `audit_logs` (
    `id` CHAR(36) NOT NULL,
    `adminId` CHAR(36) NOT NULL,
    `targetUserId` CHAR(36) NULL,
    `action` VARCHAR(100) NOT NULL,
    `oldValue` JSON NULL,
    `newValue` JSON NULL,
    `reason` TEXT NULL,
    `ipAddress` VARCHAR(45) NULL,
    `userAgent` VARCHAR(255) NULL,
    `createdAt` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    INDEX `audit_logs_targetUserId_createdAt_idx`(`targetUserId`, `createdAt`),
    INDEX `audit_logs_adminId_createdAt_idx`(`adminId`, `createdAt`),
    INDEX `audit_logs_action_createdAt_idx`(`action`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `app_settings` (
    `id` CHAR(36) NOT NULL,
    `key` VARCHAR(100) NOT NULL,
    `value` JSON NOT NULL,
    `updatedBy` CHAR(36) NULL,
    `updatedAt` TIMESTAMP(6) NOT NULL,

    UNIQUE INDEX `app_settings_key_key`(`key`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `units` ADD CONSTRAINT `units_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `audit_logs` ADD CONSTRAINT `audit_logs_adminId_fkey` FOREIGN KEY (`adminId`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `audit_logs` ADD CONSTRAINT `audit_logs_targetUserId_fkey` FOREIGN KEY (`targetUserId`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `app_settings` ADD CONSTRAINT `app_settings_updatedBy_fkey` FOREIGN KEY (`updatedBy`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
