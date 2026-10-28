import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../sync/data/services/sync_push_service.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'local_auth_repository.dart';

/// Production API implementation of [AuthRepository] connecting to the Node.js / MySQL backend via Dio.
///
/// Features:
/// - Manages credentials, tokens, and stable device identity via [SessionStore].
/// - Single-refresh queued interceptor ensuring only 1 refresh request is fired concurrently.
/// - Offline-first instant local startup decision (Rule 3) without waiting for network.
/// - Graceful `needsLogin` state on token expiry/theft detection without deleting local data.
/// - Account switching conflict protection with unsynced changes detection.
class ApiAuthRepository implements AuthRepository {
  final Dio dio;
  final AppDatabase db;
  final FlutterSecureStorage _storage;
  final SessionStore _sessionStore;
  final LocalAuthRepository _localAuthRepo;
  final String baseUrl;
  final bool _isCustomDioClient;

  final _authStateController = StreamController<AuthUser?>.broadcast();
  final _needsLoginController = StreamController<bool>.broadcast();
  final _passwordChangedController = StreamController<bool>.broadcast();

  AuthUser? _cachedUser;
  bool _needsLogin = false;
  bool _passwordChangedRemotely = false;
  Completer<String?>? _refreshCompleter;

  ApiAuthRepository({
    required this.db,
    Dio? dioClient,
    FlutterSecureStorage? storage,
    SessionStore? sessionStore,
    String? baseUrl,
    LocalAuthRepository? localAuthRepo,
  })  : _storage = storage ?? defaultSecureStorage,
        _sessionStore = sessionStore ?? SessionStore(storage: storage),
        baseUrl = baseUrl ??
            (dioClient != null && dioClient.options.baseUrl.isNotEmpty
                ? dioClient.options.baseUrl
                : AppConstants.apiBaseUrl),
        _localAuthRepo =
            localAuthRepo ?? LocalAuthRepository(db: db, storage: storage),
        _isCustomDioClient = dioClient != null,
        dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  SessionStore get sessionStore => _sessionStore;

  /// True when the access/refresh token expired or was revoked and re-login is required.
  /// Offline operations and local database remain 100% operational in this state.
  bool get needsLogin => _needsLogin;

  /// Stream of `needsLogin` state updates for UI banners and sync pausing.
  Stream<bool> watchNeedsLogin() => _needsLoginController.stream;

  void setNeedsLogin(bool value) {
    if (_needsLogin != value) {
      _needsLogin = value;
      _needsLoginController.add(value);
    }
  }

  /// True when tokens were rejected because password was changed on another device.
  bool get isPasswordChangedRemotely => _passwordChangedRemotely;

  /// Stream of remote password change state.
  Stream<bool> watchPasswordChangedRemotely() =>
      _passwordChangedController.stream;

  void setPasswordChangedRemotely(bool value) {
    if (_passwordChangedRemotely != value) {
      _passwordChangedRemotely = value;
      _passwordChangedController.add(value);
    }
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.baseUrl.isEmpty) {
            options.baseUrl = dio.options.baseUrl.isNotEmpty
                ? dio.options.baseUrl
                : baseUrl;
          }

          // Send app version and device ID on every request
          options.headers['X-App-Version'] = AppConstants.appVersion;
          final deviceId = await _sessionStore.getOrCreateDeviceId();
          options.headers['X-Device-Id'] = deviceId;

          // Attach Bearer access token if present
          final session = await _sessionStore.readSession();
          if (session != null && session.accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          final statusCode = err.response?.statusCode;
          final responseData = err.response?.data;
          String? errorCode;

          if (responseData is Map<String, dynamic> &&
              responseData['error'] is Map) {
            errorCode = responseData['error']['code']?.toString();
          }

          // Handle 403 ACCOUNT_SUSPENDED: preserve local data and update state
          if (statusCode == 403 && errorCode == 'ACCOUNT_SUSPENDED') {
            String? reason;
            if (responseData is Map<String, dynamic> &&
                responseData['error'] is Map) {
              final errMap = responseData['error'] as Map;
              if (errMap['details'] is Map) {
                reason = errMap['details']['reason']?.toString();
              }
            }
            if (_cachedUser != null) {
              final updated = _cachedUser!.copyWith(
                status: 'SUSPENDED',
                suspendedReason: reason ?? _cachedUser!.suspendedReason,
              );
              _cachedUser = updated;
              await _storage.write(
                key: SessionStore.keyUserSession,
                value: jsonEncode(updated.toJson()),
              );
              _authStateController.add(updated);
            }
            return handler.reject(err);
          }

          // Handle 401 TOKEN_EXPIRED / INVALID_TOKEN with Single-Refresh Queued Interceptor (Rule 5 & 6)
          if (statusCode == 401 &&
              (errorCode == 'TOKEN_EXPIRED' ||
                  errorCode == 'INVALID_TOKEN' ||
                  errorCode == 'TOKEN_REUSED')) {
            final newToken = await _refreshTokenQueued();

            if (newToken != null && newToken.isNotEmpty) {
              // Retry original request with the new access token
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final retryResponse = await dio.fetch(err.requestOptions);
                return handler.resolve(retryResponse);
              } on DioException catch (retryErr) {
                return handler.reject(retryErr);
              }
            } else {
              // Refresh failed or revoked; app transitions to needsLogin without clearing local data
              return handler.reject(err);
            }
          }

          return handler.next(err);
        },
      ),
    );
  }

  /// Single-refresh locking queue.
  /// If multiple concurrent requests receive 401, all wait on a single refresh call.
  Future<String?> _refreshTokenQueued() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final session = await _sessionStore.readSession();
      final refreshToken = session?.refreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        setNeedsLogin(true);
        completer.complete(null);
        return null;
      }

      final activeBaseUrl =
          dio.options.baseUrl.isNotEmpty ? dio.options.baseUrl : baseUrl;

      // Use a separate Dio instance without interceptors to avoid loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: activeBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-App-Version': AppConstants.appVersion,
          },
        ),
      )..httpClientAdapter = dio.httpClientAdapter;

      final deviceId = await _sessionStore.getOrCreateDeviceId();
      final refreshRes = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );

      if (refreshRes.statusCode == 200 &&
          refreshRes.data['success'] == true) {
        final data = refreshRes.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();
        final accessExp = data['accessTokenExpiresAt']?.toString();
        final refreshExp = data['refreshTokenExpiresAt']?.toString();
        final offlineMaxDays = data['offlineMaxDays'] as int?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _sessionStore.updateTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            accessTokenExpiresAt: accessExp,
            refreshTokenExpiresAt: refreshExp,
            offlineMaxDays: offlineMaxDays,
          );

          setNeedsLogin(false);
          completer.complete(newAccessToken);
          return newAccessToken;
        }
      }

      // Failed with unexpected format
      await _sessionStore.clearTokensOnly();
      setNeedsLogin(true);
      completer.complete(null);
      return null;
    } on DioException catch (e) {
      final errData = e.response?.data;
      String? errCode;
      if (errData is Map<String, dynamic> && errData['error'] is Map) {
        errCode = errData['error']['code']?.toString();
      }

      if (e.response?.statusCode == 403 || errCode == 'ACCOUNT_SUSPENDED') {
        if (_cachedUser != null) {
          final updated = _cachedUser!.copyWith(status: 'SUSPENDED');
          _cachedUser = updated;
          await _storage.write(
            key: SessionStore.keyUserSession,
            value: jsonEncode(updated.toJson()),
          );
          _authStateController.add(updated);
        }
        await _sessionStore.clearTokensOnly();
        setNeedsLogin(true);
        completer.complete(null);
        return null;
      }

      if (errCode == 'PASSWORD_CHANGED') {
        setPasswordChangedRemotely(true);
      }

      // If refresh failed with TOKEN_EXPIRED, TOKEN_REUSED, or 401
      if (e.response?.statusCode == 401 ||
          errCode == 'TOKEN_EXPIRED' ||
          errCode == 'TOKEN_REUSED' ||
          errCode == 'INVALID_TOKEN' ||
          errCode == 'PASSWORD_CHANGED') {
        // Clear ONLY tokens; preserve all local data and offline functionality (Rule 6)
        await _sessionStore.clearTokensOnly();
        setNeedsLogin(true);
        completer.complete(null);
        return null;
      }

      // Network-level error during refresh (connection timeout, etc.):
      // Do NOT revoke tokens or mark needsLogin; keep existing tokens for when connection restores
      completer.complete(null);
      return null;
    } catch (_) {
      await _sessionStore.clearTokensOnly();
      setNeedsLogin(true);
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  @override
  Stream<AuthUser?> watchCurrentUser() => _authStateController.stream;

  @override
  Future<Result<AuthUser>> register({
    required String phoneNumber,
    required String businessName,
    required String password,
  }) async {
    try {
      final deviceId = await _sessionStore.getOrCreateDeviceId();
      final response = await dio.post(
        '/auth/register',
        data: {
          'phoneNumber': phoneNumber.trim(),
          'businessName': businessName.trim(),
          'password': password,
          'deviceId': deviceId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      final accessTokenExpiresAt = data['accessTokenExpiresAt']?.toString();
      final refreshTokenExpiresAt = data['refreshTokenExpiresAt']?.toString();
      final offlineMaxDays = data['offlineMaxDays'] as int? ?? 90;

      final user = AuthUser.fromJson(userMap);

      await _sessionStore.saveSession(
        accessToken: accessToken ?? '',
        refreshToken: refreshToken ?? '',
        accessTokenExpiresAt: accessTokenExpiresAt,
        refreshTokenExpiresAt: refreshTokenExpiresAt,
        ownerId: user.ownerId,
        ownerPhone: user.phoneNumber,
        ownerBusinessName: user.businessName,
        offlineMaxDays: offlineMaxDays,
        userProfile: user.toJson(),
      );

      // Save profile in Drift SQLite so local queries work immediately (Rule 2)
      if (!user.isAdmin) {
        await db.into(db.profiles).insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: Value(user.id),
            ownerId: user.ownerId,
            phoneNumber: Value(user.phoneNumber),
            businessName: Value(user.businessName),
            role: const Value(UserRole.owner),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
      }

      // Save local password hash for offline continuity
      try {
        final hash = await PasswordHasher().hashPassword(password);
        await _storage.write(
          key: 'kera_passhash_${user.phoneNumber}',
          value: hash,
        );
      } catch (_) {}

      _cachedUser = user;
      _authStateController.add(user);
      setNeedsLogin(false);

      return Result.success(user);
    } on DioException catch (e) {
      if (!_isCustomDioClient &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown ||
              e.response == null)) {
        final working = await _probeWorkingCandidate();
        if (working != null && working != dio.options.baseUrl) {
          AppConstants.setApiBaseUrl(working);
          dio.options.baseUrl = working;
          await _sessionStore.saveApiBaseUrl(working);
          return register(
            phoneNumber: phoneNumber,
            businessName: businessName,
            password: password,
          );
        }
      }

      final failure = _mapDioError(e);
      // Rule 1: Registration REQUIRES internet
      if (failure is NetworkFailure) {
        return const Result.failure(OfflineInternetRequiredFailure());
      }
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Registration failed: ${e.toString()}', cause: e),
      );
    }
  }

  /// Probes candidate Android base URLs in parallel to quickly discover the active backend host.
  Future<String?> _probeWorkingCandidate() async {
    final candidates = AppConstants.candidateAndroidBaseUrls;
    try {
      final results = await Future.wait(
        candidates.map((candidate) async {
          try {
            final probeDio = Dio(
              BaseOptions(
                baseUrl: candidate,
                connectTimeout: const Duration(milliseconds: 1500),
                receiveTimeout: const Duration(milliseconds: 1500),
                sendTimeout: const Duration(milliseconds: 1500),
              ),
            );
            final res = await probeDio.get('/health');
            if (res.statusCode == 200) {
              return candidate;
            }
          } catch (_) {}
          return null;
        }),
      );
      for (final c in results) {
        if (c != null) return c;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Result<AuthUser>> login({
    required String phoneNumber,
    required String password,
    bool forceDiscardUnsynced = false,
  }) async {
    try {
      final deviceId = await _sessionStore.getOrCreateDeviceId();
      final response = await dio.post(
        '/auth/login',
        data: {
          'phoneNumber': phoneNumber.trim(),
          'password': password.trim(),
          'deviceId': deviceId,
        },
      );

      return await _handleSuccessfulAuthResponse(
        response.data['data'] as Map<String, dynamic>,
        password: password,
        forceDiscardUnsynced: forceDiscardUnsynced,
      );
    } on DioException catch (e) {
      // Android loopback / Wi-Fi candidate check (testing across USB reverse, Wi-Fi LAN, and emulator)
      if (!_isCustomDioClient &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown ||
              e.response == null)) {
        final working = await _probeWorkingCandidate();
        if (working != null && working != dio.options.baseUrl) {
          AppConstants.setApiBaseUrl(working);
          dio.options.baseUrl = working;
          await _sessionStore.saveApiBaseUrl(working);
          try {
            final deviceId = await _sessionStore.getOrCreateDeviceId();
            final response = await dio.post(
              '/auth/login',
              data: {
                'phoneNumber': phoneNumber.trim(),
                'password': password.trim(),
                'deviceId': deviceId,
              },
            );
            if (response.statusCode == 200 && response.data['success'] == true) {
              return await _handleSuccessfulAuthResponse(
                response.data['data'] as Map<String, dynamic>,
                password: password,
                forceDiscardUnsynced: forceDiscardUnsynced,
              );
            }
          } catch (_) {}
        }
      }

      final failure = _mapDioError(e);
      if (failure is NetworkFailure) {
        // Rule 1: First login on a new or empty phone REQUIRES internet
        final normalizedPhone = Validators.normalizeEthiopianPhone(phoneNumber);
        final localProfile = await (db.select(db.profiles)
              ..where((t) =>
                  t.phoneNumber.equals(normalizedPhone) & t.deletedAt.isNull()))
            .getSingleOrNull();

        if (localProfile == null) {
          return const Result.failure(OfflineInternetRequiredFailure());
        }

        // Existing local owner on phone: authenticate offline with local hash
        final localResult = await _localAuthRepo.login(
          phoneNumber: phoneNumber,
          password: password,
          forceDiscardUnsynced: forceDiscardUnsynced,
        );
        if (localResult.isSuccess && localResult.valueOrNull != null) {
          _cachedUser = localResult.valueOrNull;
          _authStateController.add(_cachedUser);
        }
        return localResult;
      }
      return Result.failure(failure);
    } catch (e) {
      if (e is Failure) return Result.failure(e);
      return Result.failure(
        AuthFailure(message: 'Login failed: ${e.toString()}', cause: e),
      );
    }
  }

  Future<Result<AuthUser>> _handleSuccessfulAuthResponse(
    Map<String, dynamic> data, {
    required String password,
    required bool forceDiscardUnsynced,
  }) async {
    final userMap = data['user'] as Map<String, dynamic>;
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final accessTokenExpiresAt = data['accessTokenExpiresAt']?.toString();
    final refreshTokenExpiresAt = data['refreshTokenExpiresAt']?.toString();
    final offlineMaxDays = data['offlineMaxDays'] as int? ?? 90;

    final user = AuthUser.fromJson(userMap);

    // Rule 4: Multi-account conflict detection
    final previousOwnerId = await _sessionStore.getLastOwnerId();
    if (previousOwnerId != null &&
        previousOwnerId.isNotEmpty &&
        previousOwnerId != user.ownerId) {
      final hasUnsynced = await db.syncQueueDao.hasUnsyncedChanges();
      if (hasUnsynced && !forceDiscardUnsynced) {
        final previousName = await _sessionStore.getLastOwnerDisplayName();
        return Result.failure(
          DifferentOwnerConflictFailure(
            previousOwnerId: previousOwnerId,
            previousOwnerName: previousName,
          ),
        );
      }
      if (hasUnsynced && forceDiscardUnsynced) {
        // Explicitly confirmed: clear old tenant data to make room for new owner
        await db.clearAllOwnerData();
      }
    }

    await _sessionStore.saveSession(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      ownerId: user.ownerId,
      ownerPhone: user.phoneNumber,
      ownerBusinessName: user.businessName,
      offlineMaxDays: offlineMaxDays,
      userProfile: user.toJson(),
    );

    // Save profile row in Drift SQLite so offline queries work immediately
    if (!user.isAdmin) {
      await db.into(db.profiles).insertOnConflictUpdate(
        ProfilesCompanion.insert(
          id: Value(user.id),
          ownerId: user.ownerId,
          phoneNumber: Value(user.phoneNumber),
          businessName: Value(user.businessName),
          role: const Value(UserRole.owner),
          syncStatus: const Value(SyncStatus.synced),
        ),
      );
    }

    // Save local password hash for offline continuity
    try {
      final hash = await PasswordHasher().hashPassword(password);
      await _storage.write(
        key: 'kera_passhash_${user.phoneNumber}',
        value: hash,
      );
    } catch (_) {}

    _cachedUser = user;
    _authStateController.add(user);
    setNeedsLogin(false);

    return Result.success(user);
  }

  @override
  Future<LogoutPrecheck> precheckLogout() async {
    final pendingCount = await db.syncQueueDao.countPending();
    bool isOnline = false;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      isOnline = connectivity.isNotEmpty &&
          !connectivity.contains(ConnectivityResult.none);
    } catch (_) {}
    return LogoutPrecheck(pendingCount: pendingCount, isOnline: isOnline);
  }

  @override
  Future<Result<void>> performSyncAndLogout() async {
    final pushService = SyncPushService(
      db: db,
      dio: dio,
      sessionStore: _sessionStore,
    );
    final pushResult = await pushService.pushPendingQueue();
    if (pushResult.isFailure) {
      return Result.failure(pushResult.failureOrNull!);
    }

    final remaining = await db.syncQueueDao.countPending();
    if (remaining > 0) {
      return const Result.failure(
        SyncFailure(
          message:
              'Some changes could not be synchronized. Please try again.',
        ),
      );
    }

    return logout();
  }

  @override
  Future<Result<void>> forceDiscardAndLogout() async {
    return logout();
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final session = await _sessionStore.readSession();
      if (session != null && session.refreshToken.isNotEmpty) {
        try {
          await dio.post(
            '/auth/logout',
            data: {
              'refreshToken': session.refreshToken,
              'deviceId': session.deviceId,
            },
          );
        } catch (_) {}
      }

      await _sessionStore.clearAllSession();
      await db.clearAllOwnerData();
      _cachedUser = null;
      _authStateController.add(null);
      setNeedsLogin(false);
      setPasswordChangedRemotely(false);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Logout failed: ${e.toString()}', cause: e),
      );
    }
  }

  @override
  Future<Result<AuthUser?>> currentUser() async {
    final sw = Stopwatch()..start();
    try {
      // 1. In-memory cache
      if (_cachedUser != null) {
        return Result.success(_cachedUser);
      }

      // 2. Offline-First: Read securely stored session without blocking on the network (Rule 3)
      final session = await _sessionStore.readSession();
      debugPrint(
        '[STARTUP] ApiAuthRepository currentUser() sessionStore.read: ${sw.elapsedMilliseconds}ms',
      );
      if (session == null || session.userProfile == null) {
        _authStateController.add(null);
        return const Result.success(null);
      }

      final user = AuthUser.fromJson(session.userProfile!);

      // 3. For owners: verify that local profile exists in Drift SQLite (Rule 3)
      if (!user.isAdmin) {
        final profile = await (db.select(db.profiles)
              ..where((t) => t.id.equals(user.id)))
            .getSingleOrNull();
        if (profile == null) {
          debugPrint('[STARTUP] Local Drift profile missing for stored session');
          _authStateController.add(null);
          return const Result.success(null);
        }
      }

      _cachedUser = user;
      _authStateController.add(user);

      // 4. If tokens were cleared due to expiry/theft, notify needsLogin state
      if (session.refreshToken.isEmpty) {
        setNeedsLogin(true);
      }

      return Result.success(user);
    } catch (e) {
      _authStateController.add(null);
      return const Result.success(null);
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();
        final accessExp = data['accessTokenExpiresAt']?.toString();
        final refreshExp = data['refreshTokenExpiresAt']?.toString();

        if (newAccessToken != null && newRefreshToken != null) {
          await _sessionStore.updateTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            accessTokenExpiresAt: accessExp,
            refreshTokenExpiresAt: refreshExp,
          );
        }
      }
      if (_cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(mustChangePassword: false);
        await _storage.write(
          key: SessionStore.keyUserSession,
          value: jsonEncode(_cachedUser!.toJson()),
        );
        _authStateController.add(_cachedUser);
      }
      try {
        await _localAuthRepo.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } catch (_) {}
      return const Result.success(null);
    } on DioException catch (e) {
      final failure = _mapDioError(e);
      if (failure is NetworkFailure) {
        return _localAuthRepo.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        AuthFailure(
          message: 'Change password failed: ${e.toString()}',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<AuthUser>> updateBusinessName(String newBusinessName) async {
    try {
      final userResult = await currentUser();
      final user = userResult.valueOrNull;
      if (user == null) {
        return const Result.failure(
          AuthFailure(message: 'User is not logged in'),
        );
      }

      final now = DateTime.now();
      await (db.update(db.profiles)..where((t) => t.id.equals(user.id))).write(
        ProfilesCompanion(
          businessName: Value(newBusinessName),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

      final updatedUser = user.copyWith(businessName: newBusinessName);
      await _storage.write(
        key: SessionStore.keyUserSession,
        value: jsonEncode(updatedUser.toJson()),
      );
      _cachedUser = updatedUser;
      _authStateController.add(updatedUser);

      return Result.success(updatedUser);
    } catch (e) {
      return Result.failure(
        AuthFailure(
          message: 'Update business name failed: ${e.toString()}',
          cause: e,
        ),
      );
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown ||
        e.response == null) {
      return const NetworkFailure(
        message:
            'No internet connection. Please connect to the internet to authenticate.',
        code: 'NO_INTERNET',
      );
    }

    final response = e.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final errorObj = response.data['error'];
      if (errorObj is Map<String, dynamic>) {
        final code = errorObj['code']?.toString() ?? 'SERVER_ERROR';
        final message =
            errorObj['message']?.toString() ?? 'Authentication error';
        return AuthFailure(
          message: message,
          code: code,
          cause: errorObj['details'],
        );
      }
    }

    return ServerFailure(
      message: e.message ?? 'Server error occurred',
      statusCode: response?.statusCode,
      code: 'SERVER_ERROR',
    );
  }

  void dispose() {
    _authStateController.close();
    _needsLoginController.close();
    _passwordChangedController.close();
    _localAuthRepo.dispose();
  }
}
