import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/constants.dart';

/// Representation of the remote app-config response.
class MinAppVersionConfig {
  final String version;
  final bool enforce;
  final String downloadUrl;

  const MinAppVersionConfig({
    required this.version,
    required this.enforce,
    required this.downloadUrl,
  });

  factory MinAppVersionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MinAppVersionConfig(
        version: '1.0.0',
        enforce: false,
        downloadUrl: 'https://keraspare.et/download',
      );
    }
    return MinAppVersionConfig(
      version: json['version']?.toString() ?? '1.0.0',
      enforce: json['enforce'] == true,
      downloadUrl: json['downloadUrl']?.toString() ??
          'https://keraspare.et/download',
    );
  }
}

class MaintenanceModeConfig {
  final bool enabled;
  final String messageAm;
  final String messageEn;

  const MaintenanceModeConfig({
    required this.enabled,
    required this.messageAm,
    required this.messageEn,
  });

  factory MaintenanceModeConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MaintenanceModeConfig(
        enabled: false,
        messageAm: '',
        messageEn: '',
      );
    }
    return MaintenanceModeConfig(
      enabled: json['enabled'] == true,
      messageAm: json['messageAm']?.toString() ?? '',
      messageEn: json['messageEn']?.toString() ?? '',
    );
  }
}

class AnnouncementConfig {
  final bool active;
  final String titleAm;
  final String titleEn;
  final String bodyAm;
  final String bodyEn;

  const AnnouncementConfig({
    required this.active,
    required this.titleAm,
    required this.titleEn,
    required this.bodyAm,
    required this.bodyEn,
  });

  factory AnnouncementConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AnnouncementConfig(
        active: false,
        titleAm: '',
        titleEn: '',
        bodyAm: '',
        bodyEn: '',
      );
    }
    return AnnouncementConfig(
      active: json['active'] == true,
      titleAm: json['titleAm']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      bodyAm: json['bodyAm']?.toString() ?? '',
      bodyEn: json['bodyEn']?.toString() ?? '',
    );
  }

  String get uniqueHash => '$titleEn|$titleAm|$bodyEn|$bodyAm';
}

class SupportContactConfig {
  final String phone;
  final String telegram;

  const SupportContactConfig({
    required this.phone,
    required this.telegram,
  });

  factory SupportContactConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SupportContactConfig(
        phone: AppConstants.fallbackSupportPhone,
        telegram: AppConstants.fallbackSupportTelegram,
      );
    }
    return SupportContactConfig(
      phone: json['phone']?.toString() ?? AppConstants.fallbackSupportPhone,
      telegram: json['telegram']?.toString() ??
          AppConstants.fallbackSupportTelegram,
    );
  }
}

class AppConfig {
  final MinAppVersionConfig minAppVersion;
  final MaintenanceModeConfig maintenanceMode;
  final AnnouncementConfig announcement;
  final SupportContactConfig supportContact;
  final String installedVersion;

  const AppConfig({
    required this.minAppVersion,
    required this.maintenanceMode,
    required this.announcement,
    required this.supportContact,
    required this.installedVersion,
  });

  factory AppConfig.defaults({String installedVersion = AppConstants.appVersion}) {
    return AppConfig(
      minAppVersion: const MinAppVersionConfig(
        version: '1.0.0',
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
        phone: AppConstants.fallbackSupportPhone,
        telegram: AppConstants.fallbackSupportTelegram,
      ),
      installedVersion: installedVersion,
    );
  }

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    String installedVersion = AppConstants.appVersion,
  }) {
    return AppConfig(
      minAppVersion: MinAppVersionConfig.fromJson(
        json['minAppVersion'] as Map<String, dynamic>?,
      ),
      maintenanceMode: MaintenanceModeConfig.fromJson(
        json['maintenanceMode'] as Map<String, dynamic>?,
      ),
      announcement: AnnouncementConfig.fromJson(
        json['announcement'] as Map<String, dynamic>?,
      ),
      supportContact: SupportContactConfig.fromJson(
        json['supportContact'] as Map<String, dynamic>?,
      ),
      installedVersion: installedVersion,
    );
  }

  /// Compares semantic versions: returns true if installedVersion < minAppVersion.version
  bool get isUpdateRequired {
    if (!minAppVersion.enforce) return false;
    return isVersionOlder(installedVersion, minAppVersion.version);
  }

  /// Semantic version comparator helper
  static bool isVersionOlder(String current, String required) {
    try {
      final cParts = _parseVersion(current);
      final rParts = _parseVersion(required);

      final maxLen = cParts.length > rParts.length ? cParts.length : rParts.length;
      for (var i = 0; i < maxLen; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final r = i < rParts.length ? rParts[i] : 0;
        if (c < r) return true;
        if (c > r) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersion(String v) {
    final clean = v.split(RegExp(r'[\+\-]')).first.trim();
    return clean
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }
}

/// Service managing remote config fetch and caching.
class AppConfigService {
  final Dio _dio;
  final Connectivity _connectivity;

  AppConfigService({
    Dio? dioClient,
    Connectivity? connectivity,
  })  : _dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ),
            ),
        _connectivity = connectivity ?? Connectivity();

  Future<String> getInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        return info.version;
      }
    } catch (_) {}
    return AppConstants.appVersion;
  }

  Future<AppConfig> fetchAppConfig() async {
    final currentVersion = await getInstalledVersion();
    try {
      final response = await _dio.get('/app-config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AppConfig.fromJson(data, installedVersion: currentVersion);
      }
    } on DioException catch (e) {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError)) {
        for (final candidate in AppConstants.candidateAndroidBaseUrls) {
          if (candidate == _dio.options.baseUrl) continue;
          try {
            final candidateDio = Dio(
              BaseOptions(
                baseUrl: candidate,
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 2),
              ),
            );
            final res = await candidateDio.get('/app-config');
            if (res.statusCode == 200 && res.data['success'] == true) {
              AppConstants.setApiBaseUrl(candidate);
              _dio.options.baseUrl = candidate;
              final data = res.data['data'] as Map<String, dynamic>;
              return AppConfig.fromJson(data, installedVersion: currentVersion);
            }
          } catch (_) {
            // Continue testing candidates
          }
        }
      }
    } catch (_) {
      // Return defaults on network error
    }
    return AppConfig.defaults(installedVersion: currentVersion);
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
