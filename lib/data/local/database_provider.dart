import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/parts/presentation/providers/metadata_providers.dart';
import 'app_database.dart';
import 'daos/parts_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/stock_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'database_manager.dart';

/// Provider for the local Drift database partitioned by owner.
/// Switching accounts automatically points to the isolated owner SQLite file.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  return DatabaseManager.instance
      .getDatabase(ownerId.isNotEmpty ? ownerId : null);
});

/// Provider for PartsDao.
final partsDaoProvider = Provider<PartsDao>((ref) {
  return ref.watch(appDatabaseProvider).partsDao;
});

/// Provider for StockDao.
final stockDaoProvider = Provider<StockDao>((ref) {
  return ref.watch(appDatabaseProvider).stockDao;
});

/// Provider for SalesDao.
final salesDaoProvider = Provider<SalesDao>((ref) {
  return ref.watch(appDatabaseProvider).salesDao;
});

/// Provider for SyncQueueDao.
final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao;
});

/// Provider for SettingsDao.
final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});
