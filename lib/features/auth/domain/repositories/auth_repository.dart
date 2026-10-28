import '../../../../core/utils/result.dart';
import '../models/auth_user.dart';

/// Result of pre-logout checks verifying unsynced mutations and connectivity.
class LogoutPrecheck {
  final int pendingCount;
  final bool isOnline;

  const LogoutPrecheck({
    required this.pendingCount,
    required this.isOnline,
  });

  bool get hasPending => pendingCount > 0;
}

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
  /// If [forceDiscardUnsynced] is true, any pending local changes belonging to
  /// a different previous owner will be discarded.
  Future<Result<AuthUser>> login({
    required String phoneNumber,
    required String password,
    bool forceDiscardUnsynced = false,
  });

  /// Logs out the currently authenticated user and clears sessions.
  Future<Result<void>> logout();

  /// Inspects the sync queue and network connectivity before initiating logout.
  Future<LogoutPrecheck> precheckLogout();

  /// Pushes all pending queue items to remote server before executing logout.
  /// If sync fails or items remain in queue, cancels logout and returns failure.
  Future<Result<void>> performSyncAndLogout();

  /// Forces logout by discarding all unsynced data and wiping local tables.
  Future<Result<void>> forceDiscardAndLogout();

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
