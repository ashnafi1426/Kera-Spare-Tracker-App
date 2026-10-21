import 'package:drift/drift.dart';
import 'base_table.dart';
import 'enums.dart';

/// Profiles table storing owner and tenant metadata.
@DataClassName('Profile')
class Profiles extends Table with SyncedTableMixin {
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get businessName => text().nullable()();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(Constant(UserRole.owner.name))();
  TextColumn get avatarUrl => text().nullable()();
}
