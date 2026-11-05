import 'package:flutter/foundation.dart';
import 'app_database.dart';

/// DatabaseManager handles multi-tenant database lifecycle.
/// Each owner gets an isolated physical SQLite database file `kera_owner_{ownerId}.sqlite`.
/// This guarantees that switching accounts never leaks or exposes another owner's data.
class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager instance = DatabaseManager._();

  final Map<String, AppDatabase> _databases = {};
  AppDatabase? _defaultDatabase;

  /// Returns the isolated database for [ownerId], or default database if null.
  AppDatabase getDatabase([String? ownerId]) {
    if (ownerId == null || ownerId.trim().isEmpty) {
      _defaultDatabase ??= AppDatabase();
      return _defaultDatabase!;
    }

    final key = ownerId.trim();
    if (_databases.containsKey(key)) {
      return _databases[key]!;
    }

    final db = AppDatabase.forOwner(key);
    _databases[key] = db;
    return db;
  }

  /// Closes database connection for a specific owner (e.g. on logout).
  Future<void> closeForOwner(String ownerId) async {
    final key = ownerId.trim();
    if (_databases.containsKey(key)) {
      final db = _databases.remove(key);
      if (db != null) {
        await db.close();
        debugPrint('[DatabaseManager] Closed database for owner: $key');
      }
    }
  }

  /// Closes all active databases (e.g. on app shutdown or complete session purge).
  Future<void> closeAll() async {
    if (_defaultDatabase != null) {
      await _defaultDatabase!.close();
      _defaultDatabase = null;
    }
    for (final entry in _databases.entries) {
      await entry.value.close();
    }
    _databases.clear();
    debugPrint('[DatabaseManager] Closed all database instances.');
  }

  /// Generates the safe filename for an owner's database.
  static String getDatabaseFileName(String? ownerId) {
    if (ownerId == null || ownerId.trim().isEmpty) {
      return 'kera_spare_tracker.sqlite';
    }
    final sanitized = ownerId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'kera_owner_$sanitized.sqlite';
  }
}
