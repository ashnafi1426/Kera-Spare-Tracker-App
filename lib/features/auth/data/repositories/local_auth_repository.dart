import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

const String _userSessionKey = 'kera_user_session';
const String _passHashPrefix = 'kera_passhash_';

/// Local offline-first implementation of AuthRepository using Drift and FlutterSecureStorage.
class LocalAuthRepository implements AuthRepository {
  final AppDatabase db;
  final FlutterSecureStorage _storage;
  final PasswordHasher _hasher;
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _cachedUser;

  LocalAuthRepository({
    required this.db,
    FlutterSecureStorage? storage,
    PasswordHasher? hasher,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _hasher = hasher ?? PasswordHasher();

  @override
  Stream<AuthUser?> watchCurrentUser() => _authStateController.stream;

  @override
  Future<Result<AuthUser>> register({
    required String phoneNumber,
    required String businessName,
    required String password,
  }) async {
    try {
      final normalizedPhone = Validators.normalizeEthiopianPhone(phoneNumber);
      final trimmedBusiness = businessName.trim();

      if (trimmedBusiness.isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Business name is required'),
        );
      }

      // Check if phone already registered locally
      final existing = await (db.select(db.profiles)
            ..where((t) =>
                t.phoneNumber.equals(normalizedPhone) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing != null) {
        return const Result.failure(
          AuthFailure(
            message: 'A business owner with this phone number is already registered',
          ),
        );
      }

      // Hash password securely
      final passwordHash = await _hasher.hashPassword(password);

      // Create new profile ID & owner ID
      final userId = const Uuid().v4();

      await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: Value(userId),
          ownerId: userId,
          phoneNumber: Value(normalizedPhone),
          businessName: Value(trimmedBusiness),
          role: const Value(UserRole.owner),
        ),
      );

      // Enqueue mutation for future cloud sync
      await db.syncQueueDao.enqueue(
        tableName: 'profiles',
        recordId: userId,
        operation: SyncOperation.insert,
        payload: jsonEncode({
          'id': userId,
          'owner_id': userId,
          'phone_number': normalizedPhone,
          'business_name': trimmedBusiness,
          'role': 'owner',
        }),
      );

      // Store password hash securely
      await _storage.write(
        key: '$_passHashPrefix$normalizedPhone',
        value: passwordHash,
      );

      final user = AuthUser(
        id: userId,
        ownerId: userId,
        phoneNumber: normalizedPhone,
        businessName: trimmedBusiness,
        role: 'owner',
      );

      await _persistSession(user);
      return Result.success(user);
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
      final normalizedPhone = Validators.normalizeEthiopianPhone(phoneNumber);

      // Fetch user profile from SQLite
      final profile = await (db.select(db.profiles)
            ..where((t) =>
                t.phoneNumber.equals(normalizedPhone) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (profile == null) {
        return const Result.failure(
          AuthFailure(message: 'Invalid phone number or password'),
        );
      }

      // Retrieve stored hash
      final storedHash = await _storage.read(
        key: '$_passHashPrefix$normalizedPhone',
      );

      if (storedHash == null) {
        return const Result.failure(
          AuthFailure(message: 'Invalid phone number or password'),
        );
      }

      // Verify password
      final isMatch = await _hasher.verifyPassword(
        password: password,
        storedHash: storedHash,
      );

      if (!isMatch) {
        return const Result.failure(
          AuthFailure(message: 'Invalid phone number or password'),
        );
      }

      final user = AuthUser(
        id: profile.id,
        ownerId: profile.ownerId,
        phoneNumber: profile.phoneNumber ?? normalizedPhone,
        businessName: profile.businessName ?? '',
        role: profile.role.name,
      );

      await _persistSession(user);
      return Result.success(user);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Login failed: ${e.toString()}', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.delete(key: AppConstants.secureStorageTokenKey);
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
      if (_cachedUser != null) {
        return Result.success(_cachedUser);
      }

      final sessionJson = await _storage.read(key: _userSessionKey);
      if (sessionJson == null || sessionJson.isEmpty) {
        _authStateController.add(null);
        return const Result.success(null);
      }

      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(map);
      _cachedUser = user;
      _authStateController.add(user);
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
      final userResult = await currentUser();
      final user = userResult.valueOrNull;
      if (user == null) {
        return const Result.failure(
          AuthFailure(message: 'User is not logged in'),
        );
      }

      final storedHash = await _storage.read(
        key: '$_passHashPrefix${user.phoneNumber}',
      );
      if (storedHash == null) {
        return const Result.failure(
          AuthFailure(message: 'Password record not found'),
        );
      }

      final isMatch = await _hasher.verifyPassword(
        password: currentPassword,
        storedHash: storedHash,
      );
      if (!isMatch) {
        return const Result.failure(
          AuthFailure(message: 'Current password is incorrect'),
        );
      }

      final newHash = await _hasher.hashPassword(newPassword);
      await _storage.write(
        key: '$_passHashPrefix${user.phoneNumber}',
        value: newHash,
      );

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        AuthFailure(message: 'Change password failed: ${e.toString()}', cause: e),
      );
    }
  }

  Future<void> _persistSession(AuthUser user) async {
    _cachedUser = user;
    await _storage.write(
      key: AppConstants.secureStorageTokenKey,
      value: const Uuid().v4(),
    );
    await _storage.write(
      key: AppConstants.secureStorageOwnerIdKey,
      value: user.ownerId,
    );
    await _storage.write(
      key: _userSessionKey,
      value: jsonEncode(user.toJson()),
    );
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }
}
