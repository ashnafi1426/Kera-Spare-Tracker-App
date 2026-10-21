import '../../../../core/utils/result.dart';
import '../models/auth_user.dart';

/// Abstract authentication repository allowing seamless switching
/// between LocalAuthRepository and SupabaseAuthRepository.
abstract class AuthRepository {
  /// Registers a new spare parts business owner.
  Future<Result<AuthUser>> register({
    required String phoneNumber,
    required String businessName,
    required String password,
  });

  /// Authenticates an existing owner with phone number and password.
  Future<Result<AuthUser>> login({
    required String phoneNumber,
    required String password,
  });

  /// Logs out the currently authenticated user and clears sessions.
  Future<Result<void>> logout();

  /// Gets the currently authenticated user, or null if unauthenticated.
  Future<Result<AuthUser?>> currentUser();

  /// Changes the user's password verifying current password first.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Updates the business name for the active user.
  Future<Result<AuthUser>> updateBusinessName(String newBusinessName);

  /// Stream of authentication state changes.
  Stream<AuthUser?> watchCurrentUser();
}
