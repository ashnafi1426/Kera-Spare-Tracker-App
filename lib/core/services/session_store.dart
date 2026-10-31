import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../constants/constants.dart';
import 'storage_service.dart';

/// Riverpod provider for SessionStore.
final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

/// Structured session data stored securely on the device.
class SessionData {
  final String accessToken;
  final String refreshToken;
  final String? accessTokenExpiresAt;
  final String? refreshTokenExpiresAt;
  final String ownerId;
  final String? ownerPhone;
  final String? ownerBusinessName;
  final String deviceId;
  final DateTime lastOnlineAt;
  final int offlineMaxDays;
  final Map<String, dynamic>? userProfile;

  const SessionData({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
    required this.ownerId,
    this.ownerPhone,
    this.ownerBusinessName,
    required this.deviceId,
    required this.lastOnlineAt,
    this.offlineMaxDays = 90,
    this.userProfile,
  });

  /// True if the offline duration has exceeded the server-mandated limit.
  bool get isOfflineMaxDaysExceeded {
    final daysOffline = DateTime.now().difference(lastOnlineAt).inDays;
    return daysOffline > offlineMaxDays;
  }
}

/// Secure storage service managing offline sessions, tokens, and stable device identity.
class SessionStore {
  static const String keyDeviceId = 'kera_device_id';
  static const String keyAccessToken = AppConstants.secureStorageTokenKey;
  static const String keyRefreshToken = AppConstants.secureStorageRefreshTokenKey;
  static const String keyAccessTokenExpiresAt = 'kera_access_token_expires_at';
  static const String keyRefreshTokenExpiresAt = 'kera_refresh_token_expires_at';
  static const String keyOwnerId = AppConstants.secureStorageOwnerIdKey;
  static const String keyOwnerPhone = 'kera_owner_phone';
  static const String keyOwnerBusinessName = 'kera_owner_business_name';
  static const String keyUserSession = 'kera_user_session';
  static const String keyLastOnlineAt = 'kera_last_online_at';
  static const String keyOfflineMaxDays = 'kera_offline_max_days';
  static const String keyHasSession = 'kera_has_session';
  static const String keyApiBaseUrl = 'kera_custom_api_base_url';

  final FlutterSecureStorage _storage;
  String? _cachedDeviceId;

  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? defaultSecureStorage;

  /// Returns a stable device ID unique to this physical installation.
  /// Generated via UUID v4 on first launch and permanently stored.
  Future<String> getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    try {
      String? id = await _storage.read(key: keyDeviceId);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await _storage.write(key: keyDeviceId, value: id);
      }
      _cachedDeviceId = id;
      return id;
    } catch (e) {
      debugPrint('[SessionStore] Error reading device ID: $e');
      _cachedDeviceId ??= const Uuid().v4();
      return _cachedDeviceId!;
    }
  }

  /// Fast synchronous-like local check: returns true if a session flag exists.
  Future<bool> hasSession() async {
    try {
      final flag = await _storage.read(key: keyHasSession);
      if (flag == 'true') return true;
      final token = await _storage.read(key: keyRefreshToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Persists full session after successful registration or login.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? accessTokenExpiresAt,
    String? refreshTokenExpiresAt,
    required String ownerId,
    String? ownerPhone,
    String? ownerBusinessName,
    int offlineMaxDays = 90,
    Map<String, dynamic>? userProfile,
  }) async {
    await getOrCreateDeviceId();
    final now = DateTime.now();

    await _storage.write(key: keyAccessToken, value: accessToken);
    await _storage.write(key: keyRefreshToken, value: refreshToken);
    if (accessTokenExpiresAt != null) {
      await _storage.write(key: keyAccessTokenExpiresAt, value: accessTokenExpiresAt);
    }
    if (refreshTokenExpiresAt != null) {
      await _storage.write(key: keyRefreshTokenExpiresAt, value: refreshTokenExpiresAt);
    }
    await _storage.write(key: keyOwnerId, value: ownerId);
    if (ownerPhone != null) {
      await _storage.write(key: keyOwnerPhone, value: ownerPhone);
    }
    if (ownerBusinessName != null) {
      await _storage.write(key: keyOwnerBusinessName, value: ownerBusinessName);
    }
    await _storage.write(key: keyLastOnlineAt, value: now.toIso8601String());
    await _storage.write(key: keyOfflineMaxDays, value: offlineMaxDays.toString());
    await _storage.write(key: keyHasSession, value: 'true');

    if (userProfile != null) {
      await _storage.write(key: keyUserSession, value: jsonEncode(userProfile));
    }
  }

  /// Updates rotated access & refresh tokens without disturbing profile or offline state.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    String? accessTokenExpiresAt,
    String? refreshTokenExpiresAt,
    int? offlineMaxDays,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    await _storage.write(key: keyRefreshToken, value: refreshToken);
    if (accessTokenExpiresAt != null) {
      await _storage.write(key: keyAccessTokenExpiresAt, value: accessTokenExpiresAt);
    }
    if (refreshTokenExpiresAt != null) {
      await _storage.write(key: keyRefreshTokenExpiresAt, value: refreshTokenExpiresAt);
    }
    if (offlineMaxDays != null) {
      await _storage.write(key: keyOfflineMaxDays, value: offlineMaxDays.toString());
    }
    await recordOnlineActivity();
  }

  /// Reads and constructs current session data if available.
  Future<SessionData?> readSession() async {
    try {
      Map<String, String> all = {};
      try {
        all = await _storage.readAll();
      } catch (_) {}

      final token = all[keyAccessToken] ?? await _storage.read(key: keyAccessToken);
      final refresh = all[keyRefreshToken] ?? await _storage.read(key: keyRefreshToken);
      String? ownerId = all[keyOwnerId] ?? await _storage.read(key: keyOwnerId);

      final sessionJson = all[keyUserSession] ?? await _storage.read(key: keyUserSession);
      Map<String, dynamic>? userMap;
      if (sessionJson != null && sessionJson.isNotEmpty) {
        try {
          userMap = jsonDecode(sessionJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      ownerId ??= userMap?['ownerId']?.toString() ?? userMap?['id']?.toString();

      if (ownerId == null || ownerId.isEmpty) {
        return null;
      }

      final deviceId = all[keyDeviceId] ?? await getOrCreateDeviceId();
      if (_cachedDeviceId == null && deviceId.isNotEmpty) {
        _cachedDeviceId = deviceId;
      }

      final lastOnlineStr = all[keyLastOnlineAt] ?? await _storage.read(key: keyLastOnlineAt);
      final lastOnline = lastOnlineStr != null ? DateTime.tryParse(lastOnlineStr) : null;
      final maxDaysStr = all[keyOfflineMaxDays] ?? await _storage.read(key: keyOfflineMaxDays);
      final maxDays = maxDaysStr != null ? int.tryParse(maxDaysStr) ?? 90 : 90;

      final accessExp = all[keyAccessTokenExpiresAt] ?? await _storage.read(key: keyAccessTokenExpiresAt);
      final refreshExp = all[keyRefreshTokenExpiresAt] ?? await _storage.read(key: keyRefreshTokenExpiresAt);
      final ownerPhone = all[keyOwnerPhone] ?? await _storage.read(key: keyOwnerPhone);
      final ownerBiz = all[keyOwnerBusinessName] ?? await _storage.read(key: keyOwnerBusinessName);

      return SessionData(
        accessToken: token ?? '',
        refreshToken: refresh ?? '',
        accessTokenExpiresAt: accessExp,
        refreshTokenExpiresAt: refreshExp,
        ownerId: ownerId,
        ownerPhone: ownerPhone,
        ownerBusinessName: ownerBiz,
        deviceId: deviceId,
        lastOnlineAt: lastOnline ?? DateTime.now(),
        offlineMaxDays: maxDays,
        userProfile: userMap,
      );
    } catch (e) {
      debugPrint('[SessionStore] readSession error: $e');
      return null;
    }
  }

  /// Retrieves the recorded last owner ID on this device (to detect multi-account conflicts).
  Future<String?> getLastOwnerId() async {
    try {
      return await _storage.read(key: keyOwnerId);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the recorded last owner phone or business name for user-facing dialogs.
  Future<String> getLastOwnerDisplayName() async {
    try {
      final name = await _storage.read(key: keyOwnerBusinessName);
      if (name != null && name.isNotEmpty) return name;
      final phone = await _storage.read(key: keyOwnerPhone);
      if (phone != null && phone.isNotEmpty) return phone;
      return 'Previous Owner';
    } catch (_) {
      return 'Previous Owner';
    }
  }

  /// Records online server interaction to track offline duration.
  Future<void> recordOnlineActivity() async {
    try {
      await _storage.write(key: keyLastOnlineAt, value: DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Checks if device has been offline longer than the server-mandated limit.
  Future<bool> isOfflineMaxDaysExceeded() async {
    final session = await readSession();
    if (session == null) return false;
    return session.isOfflineMaxDaysExceeded;
  }

  /// Revocation helper: clears tokens while preserving local user profile & offline DB data!
  /// Strictly follows Rule 6: NEVER delete local data automatically on token expiration.
  Future<void> clearTokensOnly() async {
    try {
      await _storage.delete(key: keyAccessToken);
      await _storage.delete(key: keyRefreshToken);
      await _storage.delete(key: keyAccessTokenExpiresAt);
      await _storage.delete(key: keyRefreshTokenExpiresAt);
    } catch (_) {}
  }

  /// Full logout helper: wipes all stored session data when explicitly confirmed and no pending changes.
  Future<void> clearAllSession() async {
    try {
      await _storage.delete(key: keyAccessToken);
      await _storage.delete(key: keyRefreshToken);
      await _storage.delete(key: keyAccessTokenExpiresAt);
      await _storage.delete(key: keyRefreshTokenExpiresAt);
      await _storage.delete(key: keyOwnerId);
      await _storage.delete(key: keyOwnerPhone);
      await _storage.delete(key: keyOwnerBusinessName);
      await _storage.delete(key: keyUserSession);
      await _storage.delete(key: keyHasSession);
      await _storage.delete(key: keyLastOnlineAt);
    } catch (_) {}
  }

  /// Persists working API base URL discovered dynamically or configured by user.
  Future<void> saveApiBaseUrl(String url) async {
    try {
      await _storage.write(key: keyApiBaseUrl, value: url);
    } catch (_) {}
  }

  /// Retrieves persisted working API base URL if previously saved.
  Future<String?> getSavedApiBaseUrl() async {
    try {
      return await _storage.read(key: keyApiBaseUrl);
    } catch (_) {
      return null;
    }
  }
}
