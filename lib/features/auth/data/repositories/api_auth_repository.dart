import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'local_auth_repository.dart';

const String _userSessionKey = 'kera_user_session';

/// Production API implementation of [AuthRepository] connecting to the Node.js / MySQL backend via Dio.
///
/// Features:
/// - Stores access & refresh tokens in [FlutterSecureStorage].
/// - Automatic token refresh interceptor on 401 TOKEN_EXPIRED.
/// - Offline-first session recovery from local storage and Drift.
/// - Account suspension (403) handling.
class ApiAuthRepository implements AuthRepository {
  final Dio dio;
  final AppDatabase db;
  final FlutterSecureStorage _storage;
  final LocalAuthRepository _localAuthRepo;
  final String baseUrl;
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _cachedUser;
  bool _isRefreshing = false;

  ApiAuthRepository({
    required this.db,
    Dio? dioClient,
    FlutterSecureStorage? storage,
    String? baseUrl,
    LocalAuthRepository? localAuthRepo,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
       _localAuthRepo =
           localAuthRepo ?? LocalAuthRepository(db: db, storage: storage),
       dio =
           dioClient ??
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

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (dio.options.baseUrl != AppConstants.apiBaseUrl) {
            dio.options.baseUrl = AppConstants.apiBaseUrl;
            options.baseUrl = AppConstants.apiBaseUrl;
          }

          // Send app version on every request
          options.headers['X-App-Version'] = AppConstants.appVersion;

          // Attach Bearer access token if present
          final token = await _storage.read(
            key: AppConstants.secureStorageTokenKey,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
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
                key: _userSessionKey,
                value: jsonEncode(updated.toJson()),
              );
              _authStateController.add(updated);
            }
            return handler.reject(err);
          }

          // Handle 401 TOKEN_EXPIRED: attempt token refresh once
          if (statusCode == 401 &&
              (errorCode == 'TOKEN_EXPIRED' || errorCode == 'INVALID_TOKEN')) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              try {
                final refreshToken = await _storage.read(
                  key: AppConstants.secureStorageRefreshTokenKey,
                );

                if (refreshToken != null && refreshToken.isNotEmpty) {
                  // Use a separate Dio instance without interceptors to avoid loops
                  final refreshDio = Dio(
                    BaseOptions(
                      baseUrl: baseUrl,
                      connectTimeout: const Duration(seconds: 8),
                      receiveTimeout: const Duration(seconds: 8),
                    ),
                  );

                  final refreshRes = await refreshDio.post(
                    '/auth/refresh',
                    data: {'refreshToken': refreshToken},
                  );

                  if (refreshRes.statusCode == 200 &&
                      refreshRes.data['success'] == true) {
                    final data =
                        refreshRes.data['data'] as Map<String, dynamic>;
                    final newAccessToken = data['accessToken']?.toString();
                    final newRefreshToken = data['refreshToken']?.toString();

                    if (newAccessToken != null) {
                      await _storage.write(
                        key: AppConstants.secureStorageTokenKey,
                        value: newAccessToken,
                      );
                    }
                    if (newRefreshToken != null) {
                      await _storage.write(
                        key: AppConstants.secureStorageRefreshTokenKey,
                        value: newRefreshToken,
                      );
                    }

                    _isRefreshing = false;

                    // Retry original request with new access token
                    err.requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
                    final retryResponse = await dio.fetch(err.requestOptions);
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (_) {
                // Refresh failed; clear session and force re-login
                await logout();
              } finally {
                _isRefreshing = false;
              }
            }
          }

          return handler.next(err);
        },
      ),
    );
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
      final response = await dio.post(
        '/auth/register',
        data: {
          'phoneNumber': phoneNumber,
          'businessName': businessName.trim(),
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      final user = AuthUser.fromJson(userMap);

      // Persist session tokens & user profile
      await _persistSession(
        user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Save local password hash for offline continuity
      try {
        final hash = await PasswordHasher().hashPassword(password);
        await _storage.write(
          key: 'kera_passhash_${user.phoneNumber}',
          value: hash,
        );
      } catch (_) {}

      return Result.success(user);
    } on DioException catch (e) {
      final failure = _mapDioError(e);
      // Seamless offline fallback: register locally in Drift SQLite and queue for sync
      if (failure is NetworkFailure) {
        final localResult = await _localAuthRepo.register(
          phoneNumber: phoneNumber,
          businessName: businessName,
          password: password,
        );
        if (localResult.isSuccess && localResult.valueOrNull != null) {
          _cachedUser = localResult.valueOrNull;
          _authStateController.add(_cachedUser);
        }
        return localResult;
      }
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Registration failed: ${e.toString()}', cause: e),
      );
    }
  }

  @override
  Future<Result<AuthUser>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'phoneNumber': phoneNumber, 'password': password},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      final user = AuthUser.fromJson(userMap);

      await _persistSession(
        user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Save local password hash for offline continuity
      try {
        final hash = await PasswordHasher().hashPassword(password);
        await _storage.write(
          key: 'kera_passhash_${user.phoneNumber}',
          value: hash,
        );
      } catch (_) {}

      return Result.success(user);
    } on DioException catch (e) {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError)) {
        for (final candidate in AppConstants.candidateAndroidBaseUrls) {
          if (candidate == dio.options.baseUrl) continue;
          try {
            final testDio = Dio(
              BaseOptions(
                baseUrl: candidate,
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 3),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'X-App-Version': AppConstants.appVersion,
                },
              ),
            );
            final response = await testDio.post(
              '/auth/login',
              data: {'phoneNumber': phoneNumber, 'password': password},
            );
            if (response.statusCode == 200 && response.data['success'] == true) {
              AppConstants.setApiBaseUrl(candidate);
              dio.options.baseUrl = candidate;

              final data = response.data['data'] as Map<String, dynamic>;
              final userMap = data['user'] as Map<String, dynamic>;
              final accessToken = data['accessToken']?.toString();
              final refreshToken = data['refreshToken']?.toString();

              final user = AuthUser.fromJson(userMap);
              await _persistSession(
                user,
                accessToken: accessToken,
                refreshToken: refreshToken,
              );
              try {
                final hash = await PasswordHasher().hashPassword(password);
                await _storage.write(
                  key: 'kera_passhash_${user.phoneNumber}',
                  value: hash,
                );
              } catch (_) {}
              return Result.success(user);
            }
          } catch (_) {
            // Keep testing candidates
          }
        }
      }

      final failure = _mapDioError(e);
      // Seamless offline fallback: authenticate against local SQLite & secure hash
      if (failure is NetworkFailure) {
        final localResult = await _localAuthRepo.login(
          phoneNumber: phoneNumber,
          password: password,
        );
        if (localResult.isSuccess && localResult.valueOrNull != null) {
          _cachedUser = localResult.valueOrNull;
          _authStateController.add(_cachedUser);
        }
        return localResult;
      }
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Login failed: ${e.toString()}', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _storage.read(
        key: AppConstants.secureStorageRefreshTokenKey,
      );
      if (refreshToken != null) {
        // Attempt server-side revocation (ignore network errors if offline)
        try {
          await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
        } catch (_) {}
      }

      await _storage.delete(key: AppConstants.secureStorageTokenKey);
      await _storage.delete(key: AppConstants.secureStorageRefreshTokenKey);
      await _storage.delete(key: AppConstants.secureStorageOwnerIdKey);
      await _storage.delete(key: _userSessionKey);

      _cachedUser = null;
      _authStateController.add(null);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Logout failed: ${e.toString()}', cause: e),
      );
    }
  }

  @override
  Future<Result<AuthUser?>> currentUser() async {
    try {
      // 1. In-memory cache
      if (_cachedUser != null) {
        return Result.success(_cachedUser);
      }

      // 2. Offline-First: Read securely stored session without blocking on the network
      final sessionJson = await _storage.read(key: _userSessionKey);
      if (sessionJson == null || sessionJson.isEmpty) {
        _authStateController.add(null);
        return const Result.success(null);
      }

      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(map);
      _cachedUser = user;
      _authStateController.add(user);

      // 3. Opportunistic background check if connected (silent, non-blocking)
      _syncProfileSilently(user.id);

      return Result.success(user);
    } catch (e) {
      _authStateController.add(null);
      return const Result.success(null);
    }
  }

  void _syncProfileSilently(String userId) {
    unawaited(() async {
      try {
        final res = await dio.get('/auth/me');
        if (res.statusCode == 200 && res.data['success'] == true) {
          final data = res.data['data'] as Map<String, dynamic>;
          final updatedUser = AuthUser.fromJson(data);
          _cachedUser = updatedUser;
          await _storage.write(
            key: _userSessionKey,
            value: jsonEncode(updatedUser.toJson()),
          );
          _authStateController.add(updatedUser);
        }
      } catch (_) {
        // Ignore background network/auth errors in silent profile sync
      }
    }());
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
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await _storage.write(
            key: AppConstants.secureStorageTokenKey,
            value: newAccessToken,
          );
        }
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _storage.write(
            key: AppConstants.secureStorageRefreshTokenKey,
            value: newRefreshToken,
          );
        }
      }
      if (_cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(mustChangePassword: false);
        await _storage.write(
          key: _userSessionKey,
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
        key: _userSessionKey,
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

  Future<void> _persistSession(
    AuthUser user, {
    String? accessToken,
    String? refreshToken,
  }) async {
    _cachedUser = user;

    if (accessToken != null) {
      await _storage.write(
        key: AppConstants.secureStorageTokenKey,
        value: accessToken,
      );
    }
    if (refreshToken != null) {
      await _storage.write(
        key: AppConstants.secureStorageRefreshTokenKey,
        value: refreshToken,
      );
    }

    await _storage.write(
      key: AppConstants.secureStorageOwnerIdKey,
      value: user.ownerId,
    );

    await _storage.write(
      key: _userSessionKey,
      value: jsonEncode(user.toJson()),
    );

    // Save profile row in Drift SQLite so offline queries and local repos work immediately (owners only)
    if (!user.isAdmin) {
      await db
          .into(db.profiles)
          .insertOnConflictUpdate(
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

    _authStateController.add(user);

  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
        message: 'No internet connection. Please connect to the internet to authenticate.',
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
    _localAuthRepo.dispose();
  }
}
