import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Retrieves a setting value by key, or null if unset.
  Future<String?> getSetting(String key) async {
    final entry = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return entry?.value;
  }

  /// Sets or updates a key-value setting.
  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes a setting entry by key.
  Future<int> deleteSetting(String key) {
    return (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }
}
