import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/services/app_config_service.dart';

void main() {
  group('AppConfig & Semantic Versioning', () {
    test('isVersionOlder accurately compares versions', () {
      expect(AppConfig.isVersionOlder('1.0.0', '1.0.1'), isTrue);
      expect(AppConfig.isVersionOlder('1.0.0', '1.1.0'), isTrue);
      expect(AppConfig.isVersionOlder('1.0.0', '2.0.0'), isTrue);
      expect(AppConfig.isVersionOlder('1.0.0+1', '1.0.1'), isTrue);
      expect(AppConfig.isVersionOlder('1.2.0', '1.1.9'), isFalse);
      expect(AppConfig.isVersionOlder('2.0.0', '1.9.9'), isFalse);
      expect(AppConfig.isVersionOlder('1.0.0', '1.0.0'), isFalse);
    });

    test('isUpdateRequired is true only when enforce is true and version is older', () {
      final configBlocked = AppConfig(
        minAppVersion: const MinAppVersionConfig(
          version: '2.0.0',
          enforce: true,
          downloadUrl: 'https://keraspare.et/download',
        ),
        maintenanceMode: const MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: const AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: const SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      expect(configBlocked.isUpdateRequired, isTrue);

      final configNotEnforced = AppConfig(
        minAppVersion: const MinAppVersionConfig(
          version: '2.0.0',
          enforce: false,
          downloadUrl: 'https://keraspare.et/download',
        ),
        maintenanceMode: const MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: const AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: const SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      expect(configNotEnforced.isUpdateRequired, isFalse);

      final configUpdated = AppConfig(
        minAppVersion: const MinAppVersionConfig(
          version: '1.0.0',
          enforce: true,
          downloadUrl: 'https://keraspare.et/download',
        ),
        maintenanceMode: const MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: const AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: const SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.5.0',
      );

      expect(configUpdated.isUpdateRequired, isFalse);
    });

    test('fromJson parses full app-config payload properly', () {
      final json = {
        'minAppVersion': {
          'version': '2.1.0',
          'enforce': true,
          'downloadUrl': 'https://custom.download/app.apk',
        },
        'maintenanceMode': {
          'enabled': true,
          'messageAm': 'ጥገና ላይ ነን',
          'messageEn': 'Under maintenance',
        },
        'announcement': {
          'active': true,
          'titleAm': 'ማስታወቂያ',
          'titleEn': 'Important Notice',
          'bodyAm': 'ዝርዝር መግለጫ',
          'bodyEn': 'Detailed description',
        },
        'supportContact': {
          'phone': '+251900112233',
          'telegram': '@SupportChannel',
        },
      };

      final parsed = AppConfig.fromJson(json, installedVersion: '1.0.0');
      expect(parsed.minAppVersion.version, equals('2.1.0'));
      expect(parsed.minAppVersion.enforce, isTrue);
      expect(parsed.minAppVersion.downloadUrl, equals('https://custom.download/app.apk'));
      expect(parsed.maintenanceMode.enabled, isTrue);
      expect(parsed.maintenanceMode.messageEn, equals('Under maintenance'));
      expect(parsed.announcement.active, isTrue);
      expect(parsed.announcement.titleEn, equals('Important Notice'));
      expect(parsed.supportContact.phone, equals('+251900112233'));
      expect(parsed.supportContact.telegram, equals('@SupportChannel'));
      expect(parsed.isUpdateRequired, isTrue);
    });
  });
}
