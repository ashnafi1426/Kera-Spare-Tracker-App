import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider for AuthRepository. Defaults to ApiAuthRepository connecting to Node.js backend.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ApiAuthRepository(db: db);
  ref.onDispose(repo.dispose);
  return repo;
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
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    state = AsyncValue.data(result.valueOrNull);
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
    state = AsyncValue.data(result.valueOrNull);
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
