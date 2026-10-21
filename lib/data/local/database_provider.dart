import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/parts_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/stock_dao.dart';
import 'daos/sync_queue_dao.dart';

/// Singleton provider for the local Drift database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
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
