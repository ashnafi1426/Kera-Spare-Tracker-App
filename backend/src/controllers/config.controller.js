import prisma from '../config/db.js';

export async function getPublicAppConfig(req, res, next) {
  try {
    const settings = await prisma.appSetting.findMany({
      where: {
        key: {
          in: ['minAppVersion', 'maintenanceMode', 'announcement', 'supportContact'],
        },
      },
    });

    const configMap = {};
    for (const s of settings) {
      configMap[s.key] = s.value;
    }

    // Default fallbacks if not seeded
    const minAppVersion = configMap.minAppVersion || { version: '1.0.0', enforce: false, downloadUrl: 'https://keraspare.et/download' };
    const maintenanceMode = configMap.maintenanceMode || { enabled: false, messageAm: '', messageEn: '' };
    let announcement = configMap.announcement || { active: false, titleAm: '', titleEn: '', bodyAm: '', bodyEn: '' };
    const supportContact = configMap.supportContact || {
      phone: '+251911000000',
      telegram: '@KeraSpareSupport',
    };

    // Check announcement validity window if active
    if (announcement && announcement.active) {
      const now = new Date();
      if (announcement.startTime && new Date(announcement.startTime) > now) {
        announcement = { ...announcement, active: false };
      }
      if (announcement.endTime && new Date(announcement.endTime) < now) {
        announcement = { ...announcement, active: false };
      }
    }

    res.status(200).json({
      success: true,
      data: {
        minAppVersion,
        maintenanceMode,
        announcement,
        supportContact,
      },
    });
  } catch (err) {
    next(err);
  }
}
