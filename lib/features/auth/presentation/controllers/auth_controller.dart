import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider for ApiAuthRepository connecting to Node.js backend.
final apiAuthRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ApiAuthRepository(db: db);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Default AuthRepository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(apiAuthRepositoryProvider);
});

/// Notifier tracking whether token expiration/revocation requires re-login
/// while keeping offline functionality intact (Rule 4).
class NeedsLoginNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(apiAuthRepositoryProvider);
    final sub = repo.watchNeedsLogin().listen((val) => state = val);
    ref.onDispose(sub.cancel);
    return repo.needsLogin;
  }

  void setNeedsLogin(bool val) {
    ref.read(apiAuthRepositoryProvider).setNeedsLogin(val);
    state = val;
  }
}

final needsLoginProvider =
    NotifierProvider<NeedsLoginNotifier, bool>(NeedsLoginNotifier.new);

/// Provider checking whether offline duration exceeded server-mandated limit (Rule 7).
final offlineMaxDaysExceededProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(apiAuthRepositoryProvider);
  return repo.sessionStore.isOfflineMaxDaysExceeded();
});

/// Controller managing active authentication state and session lifecycle.
class AuthController extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() async {
    final result = await _repo.currentUser();
    return result.valueOrNull;
  }

  /// Logs in an existing owner.
  Future<Result<AuthUser>> login({
    required String phoneNumber,
    required String password,
    bool forceDiscardUnsynced = false,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.login(
      phoneNumber: phoneNumber,
      password: password,
      forceDiscardUnsynced: forceDiscardUnsynced,
    );
    if (result.isSuccess) {
      state = AsyncValue.data(result.valueOrNull);
    } else {
      // Preserve existing cached user so offline usage isn't interrupted on login failure
      final current = await _repo.currentUser();
      state = AsyncValue.data(current.valueOrNull);
    }
    return result;
  }

  /// Registers a new spare parts business owner.
  Future<Result<AuthUser>> register({
    required String phoneNumber,
    required String businessName,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.register(
      phoneNumber: phoneNumber,
      businessName: businessName,
      password: password,
    );
    if (result.isSuccess) {
      state = AsyncValue.data(result.valueOrNull);
    } else {
      final current = await _repo.currentUser();
      state = AsyncValue.data(current.valueOrNull);
    }
    return result;
  }

  /// Checks pending unsynced changes and connectivity status before attempting logout.
  Future<LogoutPrecheck> precheckLogout() => _repo.precheckLogout();

  /// Synchronizes all pending changes with the server before logging out.
  /// If sync fails or queue is not empty, aborts logout, keeps user logged in, and returns failure.
  Future<Result<void>> performSyncAndLogout() async {
    state = const AsyncValue.loading();
    final result = await _repo.performSyncAndLogout();
    if (result.isSuccess) {
      state = const AsyncValue.data(null);
    } else {
      final current = await _repo.currentUser();
      state = AsyncValue.data(current.valueOrNull);
    }
    return result;
  }

  /// Forces logout by discarding all unsynced data and wiping local tables.
  Future<Result<void>> forceDiscardAndLogout() async {
    state = const AsyncValue.loading();
    final result = await _repo.forceDiscardAndLogout();
    state = const AsyncValue.data(null);
    return result;
  }

  /// Logs out the user.
  Future<Result<void>> logout() async {
    state = const AsyncValue.loading();
    final result = await _repo.logout();
    state = const AsyncValue.data(null);
    return result;
  }

  /// Changes the user password.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result.isSuccess) {
      final userResult = await _repo.currentUser();
      state = AsyncValue.data(userResult.valueOrNull);
    }
    return result;
  }

  /// Updates the business name and reflects it in auth state.
  Future<Result<AuthUser>> updateBusinessName(String newName) async {
    final result = await _repo.updateBusinessName(newName);
    if (result.isSuccess) {
      state = AsyncValue.data(result.valueOrNull);
    }
    return result;
  }
}

/// Provider exposing AuthController and the current AuthUser.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

/// Live stream provider of pending sync queue count.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.watchCountPending();
});

/// Provider indicating if the user account is suspended.
final accountSuspendedProvider = Provider<bool>((ref) {
  final user = ref.watch(authControllerProvider).value;
  return user?.isSuspended ?? false;
});

/// Provider stream indicating if password was changed remotely.
final passwordChangedRemotelyProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo is ApiAuthRepository) {
    return repo.watchPasswordChangedRemotely();
  }
  return Stream.value(false);
});

/// Provider returning the last online timestamp of the current session.
final lastOnlineTimestampProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  if (repo is ApiAuthRepository) {
    final session = await repo.sessionStore.readSession();
    return session?.lastOnlineAt;
  }
  return null;
});
