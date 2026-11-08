import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/utils/result.dart';

/// Remote HTTP data source for spare parts inventory interacting with `/api/v1/parts`.
class PartsRemoteDataSource {
  final Dio _dio;
  final SessionStore _sessionStore;

  PartsRemoteDataSource({
    Dio? dioClient,
    SessionStore? sessionStore,
  })  : _dio = dioClient ?? Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl)),
        _sessionStore = sessionStore ?? SessionStore();

  Future<void> _attachAuthHeader() async {
    final session = await _sessionStore.readSession();
    if (session != null && session.accessToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
  }

  /// Fetches paginated spare parts from backend API.
  Future<Result<List<Map<String, dynamic>>>> fetchRemoteParts({
    int page = 1,
    int limit = 50,
    String? sinceCursor,
  }) async {
    try {
      await _attachAuthHeader();
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (sinceCursor != null && sinceCursor.isNotEmpty) {
        queryParams['since'] = sinceCursor;
      }

      final response = await _dio.get('/parts', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = response.data;
        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : <dynamic>[]);

        return Result.success(list.cast<Map<String, dynamic>>());
      }
      return Result.failure(ServerFailure(
        message: 'Failed to fetch parts: HTTP ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Result.failure(NetworkFailure(
        message: e.message ?? 'Network error fetching parts',
        cause: e,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(
        message: 'Unexpected error: $e',
        cause: e,
      ));
    }
  }

  /// Uploads a photo for a part to the backend server storage.
  Future<Result<String>> uploadPartPhoto({
    required String partId,
    required String filePath,
  }) async {
    try {
      await _attachAuthHeader();
      final file = File(filePath);
      if (!file.existsSync()) {
        return Result.failure(ValidationFailure(message: 'File not found: $filePath'));
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/parts/$partId/photo', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final photoUrl = (data is Map && data['data'] is Map)
            ? (data['data']['photoUrl'] as String?)
            : null;
        if (photoUrl != null) {
          return Result.success(photoUrl);
        }
      }
      return Result.failure(ServerFailure(
        message: 'Failed to upload photo: HTTP ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Result.failure(NetworkFailure(
        message: e.message ?? 'Network error uploading photo',
        cause: e,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(
        message: 'Unexpected photo upload error: $e',
        cause: e,
      ));
    }
  }
}
