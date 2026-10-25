import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/db.js';
import * as auditLogService from './auditLogService.js';

export async function getSetting(key) {
  const setting = await prisma.appSetting.findUnique({
    where: { key },
  });
  return setting ? setting.value : null;
}

export async function updateSetting(key, value, adminId, req) {
  const existing = await prisma.appSetting.findUnique({
    where: { key },
  });

  const oldValue = existing ? existing.value : null;

  return prisma.$transaction(async (tx) => {
    const updated = await tx.appSetting.upsert({
      where: { key },
      create: {
        id: uuidv4(),
        key,
        value,
        updatedBy: adminId,
      },
      update: {
        value,
        updatedBy: adminId,
      },
    });

    await auditLogService.record(tx, {
      adminId,
      action: `SETTING_UPDATED`,
      oldValue: { key, value: oldValue },
      newValue: { key, value },
      reason: `System setting '${key}' updated by administrator`,
      req,
    });

    return updated.value;
  });
}
