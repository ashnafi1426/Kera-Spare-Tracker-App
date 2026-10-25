import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

/// Provider for AdminRepository instance.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return ApiAdminRepository();
});

/// Dashboard statistics provider.
final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getDashboard();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (err) => throw Exception(err.message),
  );
});

/// Filter state for owners list.
class AdminOwnersFilter {
  final String? search;
  final String status;
  final int? inactiveDays;
  final int page;

  const AdminOwnersFilter({
    this.search,
    this.status = 'ALL',
    this.inactiveDays,
    this.page = 1,
  });

  AdminOwnersFilter copyWith({
    String? search,
    String? status,
    int? inactiveDays,
    int? page,
    bool clearInactive = false,
  }) {
    return AdminOwnersFilter(
      search: search ?? this.search,
      status: status ?? this.status,
      inactiveDays: clearInactive ? null : (inactiveDays ?? this.inactiveDays),
      page: page ?? this.page,
    );
  }
}

class AdminOwnersState {
  final List<AdminOwnerSummary> owners;
  final Map<String, dynamic> pagination;
  final bool isLoading;
  final String? errorMessage;
  final AdminOwnersFilter filter;

  const AdminOwnersState({
    required this.owners,
    required this.pagination,
    this.isLoading = false,
    this.errorMessage,
    required this.filter,
  });

  AdminOwnersState copyWith({
    List<AdminOwnerSummary>? owners,
    Map<String, dynamic>? pagination,
    bool? isLoading,
    String? errorMessage,
    AdminOwnersFilter? filter,
    bool clearError = false,
  }) {
    return AdminOwnersState(
      owners: owners ?? this.owners,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}

class AdminOwnersNotifier extends Notifier<AdminOwnersState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminOwnersState build() {
    state = const AdminOwnersState(
      owners: [],
      pagination: {},
      isLoading: true,
      filter: AdminOwnersFilter(),
    );
    loadOwners();
    return state;
  }

  Future<void> loadOwners({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final filter = state.filter.copyWith(page: page);

    final result = await _repo.getOwners(
      page: filter.page,
      search: filter.search,
      status: filter.status,
      inactiveDays: filter.inactiveDays,
    );

    result.when(
      onSuccess: (data) {
        state = state.copyWith(
          owners: data['owners'] as List<AdminOwnerSummary>,
          pagination: data['pagination'] as Map<String, dynamic>,
          isLoading: false,
          filter: filter,
        );
      },
      onFailure: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: err.message,
        );
      },
    );
  }

  void setSearch(String? search) {
    state = state.copyWith(filter: state.filter.copyWith(search: search, page: 1));
    loadOwners(page: 1);
  }

  void setStatus(String status) {
    state = state.copyWith(
      filter: state.filter.copyWith(status: status, clearInactive: true, page: 1),
    );
    loadOwners(page: 1);
  }

  void setInactiveFilter(int days) {
    state = state.copyWith(
      filter: state.filter.copyWith(inactiveDays: days, status: 'ALL', page: 1),
    );
    loadOwners(page: 1);
  }
}

final adminOwnersProvider =
    NotifierProvider<AdminOwnersNotifier, AdminOwnersState>(
  AdminOwnersNotifier.new,
);

/// Owner details provider family.
final adminOwnerDetailsProvider = FutureProvider.autoDispose
    .family<AdminOwnerDetails, String>((ref, ownerId) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getOwnerDetails(ownerId);
  return result.when(
    onSuccess: (details) => details,
    onFailure: (err) => throw Exception(err.message),
  );
});

/// Global Catalog State
class AdminCatalogState {
  final List<GlobalCatalogItem> brands;
  final List<GlobalCatalogItem> categories;
  final List<GlobalCatalogItem> units;
  final bool isLoading;
  final String? errorMessage;

  const AdminCatalogState({
    this.brands = const [],
    this.categories = const [],
    this.units = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminCatalogState copyWith({
    List<GlobalCatalogItem>? brands,
    List<GlobalCatalogItem>? categories,
    List<GlobalCatalogItem>? units,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminCatalogState(
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminCatalogNotifier extends Notifier<AdminCatalogState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminCatalogState build() {
    state = const AdminCatalogState(isLoading: true);
    loadAll();
    return state;
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final brandsRes = await _repo.getBrands();
    final categoriesRes = await _repo.getCategories();
    final unitsRes = await _repo.getUnits();

    state = state.copyWith(
      brands: brandsRes.valueOrNull ?? state.brands,
      categories: categoriesRes.valueOrNull ?? state.categories,
      units: unitsRes.valueOrNull ?? state.units,
      isLoading: false,
    );
  }

  Future<bool> addBrand(String name) async {
    final res = await _repo.createBrand(name);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }

  Future<bool> updateBrand(String id, {String? name, bool? isActive}) async {
    final res = await _repo.updateBrand(id, name: name, isActive: isActive);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }

  Future<bool> addCategory(String name) async {
    final res = await _repo.createCategory(name);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }

  Future<bool> updateCategory(String id, {String? name, bool? isActive}) async {
    final res = await _repo.updateCategory(id, name: name, isActive: isActive);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }

  Future<bool> addUnit(String name) async {
    final res = await _repo.createUnit(name);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }

  Future<bool> updateUnit(String id, {String? name, bool? isActive}) async {
    final res = await _repo.updateUnit(id, name: name, isActive: isActive);
    if (res.isSuccess) {
      await loadAll();
      return true;
    }
    return false;
  }
}

final adminCatalogProvider =
    NotifierProvider<AdminCatalogNotifier, AdminCatalogState>(
  AdminCatalogNotifier.new,
);

/// Audit logs filter state and provider
class AdminAuditLogsFilter {
  final String? action;
  final String? targetUserId;
  final int page;

  const AdminAuditLogsFilter({
    this.action,
    this.targetUserId,
    this.page = 1,
  });

  AdminAuditLogsFilter copyWith({
    String? action,
    String? targetUserId,
    int? page,
    bool clearAction = false,
  }) {
    return AdminAuditLogsFilter(
      action: clearAction ? null : (action ?? this.action),
      targetUserId: targetUserId ?? this.targetUserId,
      page: page ?? this.page,
    );
  }
}

class AdminAuditLogsState {
  final List<AdminAuditLogEntry> logs;
  final Map<String, dynamic> pagination;
  final bool isLoading;
  final String? errorMessage;
  final AdminAuditLogsFilter filter;

  const AdminAuditLogsState({
    required this.logs,
    required this.pagination,
    this.isLoading = false,
    this.errorMessage,
    required this.filter,
  });

  AdminAuditLogsState copyWith({
    List<AdminAuditLogEntry>? logs,
    Map<String, dynamic>? pagination,
    bool? isLoading,
    String? errorMessage,
    AdminAuditLogsFilter? filter,
    bool clearError = false,
  }) {
    return AdminAuditLogsState(
      logs: logs ?? this.logs,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}

class AdminAuditLogsNotifier extends Notifier<AdminAuditLogsState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminAuditLogsState build() {
    state = const AdminAuditLogsState(
      logs: [],
      pagination: {},
      isLoading: true,
      filter: AdminAuditLogsFilter(),
    );
    loadLogs();
    return state;
  }

  Future<void> loadLogs({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final filter = state.filter.copyWith(page: page);

    final res = await _repo.getAuditLogs(
      page: filter.page,
      action: filter.action,
      targetUserId: filter.targetUserId,
    );

    res.when(
      onSuccess: (data) {
        state = state.copyWith(
          logs: data['logs'] as List<AdminAuditLogEntry>,
          pagination: data['pagination'] as Map<String, dynamic>,
          isLoading: false,
          filter: filter,
        );
      },
      onFailure: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: err.message,
        );
      },
    );
  }

  void setAction(String? action) {
    state = state.copyWith(
      filter: state.filter.copyWith(action: action, clearAction: action == 'ALL', page: 1),
    );
    loadLogs(page: 1);
  }
}

final adminAuditLogsProvider =
    NotifierProvider<AdminAuditLogsNotifier, AdminAuditLogsState>(
  AdminAuditLogsNotifier.new,
);

/// Admin Settings State
class AdminSettingsState {
  final AdminMinAppVersion minAppVersion;
  final AdminAnnouncement announcement;
  final AdminMaintenanceMode maintenance;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const AdminSettingsState({
    this.minAppVersion = const AdminMinAppVersion(version: '1.0.0', enforce: false),
    this.announcement = const AdminAnnouncement(active: false),
    this.maintenance = const AdminMaintenanceMode(enabled: false),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminSettingsState copyWith({
    AdminMinAppVersion? minAppVersion,
    AdminAnnouncement? announcement,
    AdminMaintenanceMode? maintenance,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminSettingsState(
      minAppVersion: minAppVersion ?? this.minAppVersion,
      announcement: announcement ?? this.announcement,
      maintenance: maintenance ?? this.maintenance,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminSettingsNotifier extends Notifier<AdminSettingsState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminSettingsState build() {
    state = const AdminSettingsState(isLoading: true);
    loadSettings();
    return state;
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final vRes = await _repo.getSetting('min-app-version');
    final aRes = await _repo.getSetting('announcement');
    final mRes = await _repo.getSetting('maintenance');

    AdminMinAppVersion minVer = state.minAppVersion;
    if (vRes.isSuccess && vRes.valueOrNull != null) {
      minVer = AdminMinAppVersion.fromJson(vRes.valueOrNull as Map<String, dynamic>);
    }

    AdminAnnouncement ann = state.announcement;
    if (aRes.isSuccess && aRes.valueOrNull != null) {
      ann = AdminAnnouncement.fromJson(aRes.valueOrNull as Map<String, dynamic>);
    }

    AdminMaintenanceMode maint = state.maintenance;
    if (mRes.isSuccess && mRes.valueOrNull != null) {
      maint = AdminMaintenanceMode.fromJson(mRes.valueOrNull as Map<String, dynamic>);
    }

    state = state.copyWith(
      minAppVersion: minVer,
      announcement: ann,
      maintenance: maint,
      isLoading: false,
    );
  }

  Future<bool> saveMinAppVersion(String version, bool enforce) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final payload = {'version': version, 'enforce': enforce};
    final res = await _repo.updateSetting('min-app-version', payload);

    return res.when(
      onSuccess: (_) {
        state = state.copyWith(
          isSaving: false,
          minAppVersion: AdminMinAppVersion(version: version, enforce: enforce),
          successMessage: 'Version setting updated',
        );
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(isSaving: false, errorMessage: err.message);
        return false;
      },
    );
  }

  Future<bool> saveAnnouncement(AdminAnnouncement announcement) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final res = await _repo.updateSetting('announcement', announcement.toJson());

    return res.when(
      onSuccess: (_) {
        state = state.copyWith(
          isSaving: false,
          announcement: announcement,
          successMessage: 'Announcement updated',
        );
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(isSaving: false, errorMessage: err.message);
        return false;
      },
    );
  }

  Future<bool> saveMaintenance(AdminMaintenanceMode maintenance) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final res = await _repo.updateSetting('maintenance', maintenance.toJson());

    return res.when(
      onSuccess: (_) {
        state = state.copyWith(
          isSaving: false,
          maintenance: maintenance,
          successMessage: 'Maintenance mode updated',
        );
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(isSaving: false, errorMessage: err.message);
        return false;
      },
    );
  }
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AdminSettingsState>(
  AdminSettingsNotifier.new,
);

