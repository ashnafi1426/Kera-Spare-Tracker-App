import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

/// Production implementation of [AdminRepository] connecting to /api/v1/admin/* via Dio.
/// Strictly ONLINE ONLY; never accesses local Drift tables or sync queues.
class ApiAdminRepository implements AdminRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiAdminRepository({
    Dio? dioClient,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? defaultSecureStorage,
        _dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: '${AppConstants.apiBaseUrl}/admin',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'X-App-Version': AppConstants.appVersion,
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final expectedBase = '${AppConstants.apiBaseUrl}/admin';
          if (_dio.options.baseUrl != expectedBase) {
            _dio.options.baseUrl = expectedBase;
            options.baseUrl = expectedBase;
          }
          final token = await _storage.read(
            key: AppConstants.secureStorageTokenKey,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
        message: 'No internet connection. Admin operations require online access.',
        code: 'NO_INTERNET',
      );
    }

    final res = e.response;
    if (res?.data is Map<String, dynamic>) {
      final err = res!.data['error'];
      if (err is Map<String, dynamic>) {
        final code = err['code']?.toString() ?? 'SERVER_ERROR';
        final message = err['message']?.toString() ?? 'Admin request failed';
        return ServerFailure(
          message: message,
          code: code,
          statusCode: res.statusCode,
        );
      }
    }

    return ServerFailure(
      message: e.message ?? 'Unknown server error occurred',
      statusCode: res?.statusCode,
      code: 'SERVER_ERROR',
    );
  }

  @override
  Future<Result<AdminDashboardStats>> getDashboard() async {
    try {
      final res = await _dio.get('/dashboard');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(AdminDashboardStats.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to load dashboard statistics'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getOwners({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    int? inactiveDays,
    String? sortBy,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
      if (status != null && status != 'ALL') query['status'] = status;
      if (inactiveDays != null) query['inactive'] = inactiveDays;
      if (sortBy != null) query['sortBy'] = sortBy;

      final res = await _dio.get('/users', queryParameters: query);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final rawUsers = res.data['data'] as List<dynamic>? ?? [];
        final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};

        final owners = rawUsers
            .map((u) => AdminOwnerSummary.fromJson(u as Map<String, dynamic>))
            .toList();

        return Result.success({
          'owners': owners,
          'pagination': pagination,
        });
      }
      return const Result.failure(ServerFailure(message: 'Failed to fetch owners'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AdminOwnerDetails>> getOwnerDetails(String ownerId) async {
    try {
      final res = await _dio.get('/users/$ownerId');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(AdminOwnerDetails.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to load owner details'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> suspendOwner(String ownerId, {required String reason}) async {
    try {
      final res = await _dio.patch('/users/$ownerId/suspend', data: {'reason': reason});
      if (res.statusCode == 200) {
        return const Result.success(null);
      }
      return const Result.failure(ServerFailure(message: 'Failed to suspend owner'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> reactivateOwner(String ownerId) async {
    try {
      final res = await _dio.patch('/users/$ownerId/reactivate');
      if (res.statusCode == 200) {
        return const Result.success(null);
      }
      return const Result.failure(ServerFailure(message: 'Failed to reactivate owner'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> resetOwnerPassword(String ownerId) async {
    try {
      final res = await _dio.post('/users/$ownerId/reset-password');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(data);
      }
      return const Result.failure(ServerFailure(message: 'Failed to reset password'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateOwner(
    String ownerId, {
    String? businessName,
    String? phoneNumber,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (businessName != null) body['businessName'] = businessName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

      final res = await _dio.patch('/users/$ownerId', data: body);
      if (res.statusCode == 200) {
        return const Result.success(null);
      }
      return const Result.failure(ServerFailure(message: 'Failed to update owner details'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> disableOwner(
    String ownerId, {
    required String phoneConfirmation,
  }) async {
    try {
      final res = await _dio.delete(
        '/users/$ownerId',
        data: {'phoneConfirmation': phoneConfirmation},
      );
      if (res.statusCode == 200) {
        return const Result.success(null);
      }
      return const Result.failure(ServerFailure(message: 'Failed to disable account'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // Global Brands
  @override
  Future<Result<List<GlobalCatalogItem>>> getBrands() async {
    try {
      final res = await _dio.get('/brands');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        return Result.success(
          list.map((b) => GlobalCatalogItem.fromJson(b as Map<String, dynamic>)).toList(),
        );
      }
      return const Result.failure(ServerFailure(message: 'Failed to load brands'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> createBrand(String name) async {
    try {
      final res = await _dio.post('/brands', data: {'name': name});
      if (res.statusCode == 201 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to create brand'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> updateBrand(
    String id, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (isActive != null) body['isActive'] = isActive;

      final res = await _dio.patch('/brands/$id', data: body);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to update brand'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // Global Categories
  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async {
    try {
      final res = await _dio.get('/categories');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        return Result.success(
          list.map((c) => GlobalCatalogItem.fromJson(c as Map<String, dynamic>)).toList(),
        );
      }
      return const Result.failure(ServerFailure(message: 'Failed to load categories'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> createCategory(String name) async {
    try {
      final res = await _dio.post('/categories', data: {'name': name});
      if (res.statusCode == 201 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to create category'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> updateCategory(
    String id, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (isActive != null) body['isActive'] = isActive;

      final res = await _dio.patch('/categories/$id', data: body);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to update category'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // Global Units
  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async {
    try {
      final res = await _dio.get('/units');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        return Result.success(
          list.map((u) => GlobalCatalogItem.fromJson(u as Map<String, dynamic>)).toList(),
        );
      }
      return const Result.failure(ServerFailure(message: 'Failed to load units'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> createUnit(String name) async {
    try {
      final res = await _dio.post('/units', data: {'name': name});
      if (res.statusCode == 201 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to create unit'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GlobalCatalogItem>> updateUnit(
    String id, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (isActive != null) body['isActive'] = isActive;

      final res = await _dio.patch('/units/$id', data: body);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        return Result.success(GlobalCatalogItem.fromJson(data));
      }
      return const Result.failure(ServerFailure(message: 'Failed to update unit'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // Settings
  @override
  Future<Result<dynamic>> getSetting(String key) async {
    try {
      final res = await _dio.get('/settings/$key');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Result.success(res.data['data']);
      }
      return const Result.failure(ServerFailure(message: 'Failed to load setting'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<dynamic>> updateSetting(String key, dynamic value) async {
    try {
      final payload = value is Map<String, dynamic> ? value : {'value': value};
      final res = await _dio.put('/settings/$key', data: payload);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Result.success(res.data['data']);
      }
      return const Result.failure(ServerFailure(message: 'Failed to update setting'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // Audit Logs
  @override
  Future<Result<Map<String, dynamic>>> getAuditLogs({
    int page = 1,
    int limit = 50,
    String? action,
    String? targetUserId,
    String? adminId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (action != null && action.isNotEmpty && action != 'ALL') query['action'] = action;
      if (targetUserId != null) query['targetUserId'] = targetUserId;
      if (adminId != null) query['adminId'] = adminId;
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;

      final res = await _dio.get('/audit-logs', queryParameters: query);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};

        final logs = list
            .map((l) => AdminAuditLogEntry.fromJson(l as Map<String, dynamic>))
            .toList();

        return Result.success({
          'logs': logs,
          'pagination': pagination,
        });
      }
      return const Result.failure(ServerFailure(message: 'Failed to load audit logs'));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
