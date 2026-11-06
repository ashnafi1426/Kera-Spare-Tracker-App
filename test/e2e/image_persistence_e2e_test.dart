import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/widgets/kera_image_widget.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/parts/data/datasources/parts_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PartsLocalDataSource partsDataSource;

  setUp(() {
    // In-memory SQLite database for high-speed deterministic testing
    db = AppDatabase(NativeDatabase.memory());
    partsDataSource = PartsLocalDataSource(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('End-to-End Image Persistence & Database Integrity Tests', () {
    // =========================================================================
    // 1. ADMIN PROFILE PHOTO: SAVE AND LOAD IN DATABASE
    // =========================================================================
    test('1. Admin profile image properly saves and loads in database', () async {
      const adminId = 'admin-user-uuid-001';
      const adminPhone = '+251911000001';
      const initialAvatarUrl = 'https://kera-spares.et/uploads/profiles/admin_headshot.jpg';
      const localUpdatedAvatar = '/data/user/0/com.kera.spares/app_flutter/profile_photos/admin_local.jpg';

      // A. Insert Admin profile into Drift database
      await db.into(db.profiles).insertOnConflictUpdate(
            ProfilesCompanion.insert(
              id: const Value(adminId),
              ownerId: 'system_admin',
              phoneNumber: const Value(adminPhone),
              businessName: const Value('Kera Spares Admin HQ'),
              role: const Value(UserRole.admin),
              avatarUrl: const Value(initialAvatarUrl),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );

      // B. Load Admin profile from database and verify avatarUrl
      final loadedAdmin = await (db.select(db.profiles)..where((t) => t.id.equals(adminId))).getSingle();
      expect(loadedAdmin.id, equals(adminId));
      expect(loadedAdmin.role, equals(UserRole.admin));
      expect(loadedAdmin.avatarUrl, equals(initialAvatarUrl));

      // C. Verify AuthUser domain model conversion preserves admin avatarUrl
      final authAdmin = AuthUser(
        id: loadedAdmin.id,
        ownerId: loadedAdmin.ownerId,
        phoneNumber: loadedAdmin.phoneNumber ?? '',
        businessName: loadedAdmin.businessName ?? '',
        role: loadedAdmin.role.name,
        avatarUrl: loadedAdmin.avatarUrl,
      );
      expect(authAdmin.isAdmin, isTrue);
      expect(authAdmin.avatarUrl, equals(initialAvatarUrl));

      final adminJson = authAdmin.toJson();
      expect(adminJson['avatar_url'], equals(initialAvatarUrl));
      expect(adminJson['photoUrl'], equals(initialAvatarUrl));

      final restoredAdmin = AuthUser.fromJson(adminJson);
      expect(restoredAdmin.avatarUrl, equals(initialAvatarUrl));

      // D. Update Admin profile with a new local photo path
      await (db.update(db.profiles)..where((t) => t.id.equals(adminId))).write(
        const ProfilesCompanion(
          avatarUrl: Value(localUpdatedAvatar),
        ),
      );

      final reloadedAdmin = await (db.select(db.profiles)..where((t) => t.id.equals(adminId))).getSingle();
      expect(reloadedAdmin.avatarUrl, equals(localUpdatedAvatar));

      // E. Remove Admin profile photo (null)
      await (db.update(db.profiles)..where((t) => t.id.equals(adminId))).write(
        const ProfilesCompanion(
          avatarUrl: Value(null),
        ),
      );

      final clearedAdmin = await (db.select(db.profiles)..where((t) => t.id.equals(adminId))).getSingle();
      expect(clearedAdmin.avatarUrl, isNull);
    });

    // =========================================================================
    // 2. OWNER PROFILE PHOTO: SAVE AND LOAD IN DATABASE
    // =========================================================================
    test('2. Owner profile image properly saves and loads in database', () async {
      const ownerId = 'owner-merchant-uuid-100';
      const ownerPhone = '+251912345678';
      const ownerBusiness = 'Kera Gofa Sefer Spare Parts';
      const ownerLocalPhoto = '/storage/emulated/0/Android/data/com.kera.spares/files/profile_photos/owner.jpg';
      const ownerRemotePhoto = 'https://supabase.kera.et/storage/v1/object/public/profiles/owner_100.jpg';

      // A. Save Owner profile with local photo path
      await db.into(db.profiles).insertOnConflictUpdate(
            ProfilesCompanion.insert(
              id: const Value(ownerId),
              ownerId: ownerId,
              phoneNumber: const Value(ownerPhone),
              businessName: const Value(ownerBusiness),
              role: const Value(UserRole.owner),
              avatarUrl: const Value(ownerLocalPhoto),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );

      // B. Load Owner profile from Drift database
      final loadedOwner = await (db.select(db.profiles)..where((t) => t.id.equals(ownerId))).getSingle();
      expect(loadedOwner.id, equals(ownerId));
      expect(loadedOwner.ownerId, equals(ownerId));
      expect(loadedOwner.role, equals(UserRole.owner));
      expect(loadedOwner.avatarUrl, equals(ownerLocalPhoto));

      // C. Update with cloud remote photo on background sync
      await (db.update(db.profiles)..where((t) => t.id.equals(ownerId))).write(
        const ProfilesCompanion(
          avatarUrl: Value(ownerRemotePhoto),
          syncStatus: Value(SyncStatus.synced),
        ),
      );

      final syncedOwner = await (db.select(db.profiles)..where((t) => t.id.equals(ownerId))).getSingle();
      expect(syncedOwner.avatarUrl, equals(ownerRemotePhoto));

      // D. Verify AuthUser domain model serialization with avatar
      final authOwner = AuthUser(
        id: syncedOwner.id,
        ownerId: syncedOwner.ownerId,
        phoneNumber: syncedOwner.phoneNumber ?? '',
        businessName: syncedOwner.businessName ?? '',
        role: syncedOwner.role.name,
        avatarUrl: syncedOwner.avatarUrl,
      );
      expect(authOwner.isAdmin, isFalse);
      expect(authOwner.avatarUrl, equals(ownerRemotePhoto));

      final ownerJson = authOwner.toJson();
      final roundtripOwner = AuthUser.fromJson(ownerJson);
      expect(roundtripOwner.avatarUrl, equals(ownerRemotePhoto));
    });

    // =========================================================================
    // 3. INVENTORY PART PHOTOS: SAVE AND LOAD IN DATABASE
    // =========================================================================
    test('3. Inventory part local and remote images properly save and load in database', () async {
      const ownerId = 'owner-test-store-42';
      const partName = 'Toyota Hilux Brake Pad (ፊት ፍሬን ፓድ)';
      const partNumber = 'TY-04465-0K240';
      const localImagePath = '/data/user/0/com.kera.spares/app_flutter/part_photos/part_hilux_bp.jpg';
      const remoteImageUrl = 'https://supabase.kera.et/storage/v1/object/public/parts/hilux_bp_cloud.jpg';

      // A. Save Part through PartsLocalDataSource (Atomic outbox + SQLite insert)
      final createdPart = await partsDataSource.savePartWithOutbox(
        ownerId: ownerId,
        name: partName,
        partNumber: partNumber,
        photoLocalPath: localImagePath,
        photoUrl: remoteImageUrl,
        purchasePrice: 1800.0,
        sellingPrice: 2400.0,
        initialQuantity: 10.0,
        lowStockLevel: 3.0,
        unit: 'Set',
      );

      expect(createdPart.id, isNotEmpty);
      expect(createdPart.photoLocalPath, equals(localImagePath));
      expect(createdPart.photoUrl, equals(remoteImageUrl));

      // B. Query raw Drift SQLite spare_parts table directly to verify database columns
      final rawPartRow = await (db.select(db.spareParts)
            ..where((t) => t.id.equals(createdPart.id) & t.ownerId.equals(ownerId)))
          .getSingle();

      expect(rawPartRow.id, equals(createdPart.id));
      expect(rawPartRow.name, equals(partName));
      expect(rawPartRow.partNumber, equals(partNumber));
      // Verify both photo columns in SQLite
      expect(rawPartRow.photoLocalPath, equals(localImagePath));
      expect(rawPartRow.photoUrl, equals(remoteImageUrl));

      // C. Query via PartsLocalDataSource getPartById
      final loadedPart = await partsDataSource.getPartById(ownerId, createdPart.id);
      expect(loadedPart, isNotNull);
      expect(loadedPart!.photoLocalPath, equals(localImagePath));
      expect(loadedPart.photoUrl, equals(remoteImageUrl));

      // D. Query via PartsLocalDataSource getActiveParts
      final activePartsList = await partsDataSource.getActiveParts(ownerId);
      expect(activePartsList.any((p) => p.id == createdPart.id && p.photoLocalPath == localImagePath), isTrue);

      // E. Update part photo to a newly cropped / compressed local path
      const updatedLocalPath = '/data/user/0/com.kera.spares/app_flutter/part_photos/part_hilux_bp_v2.jpg';
      const updatedRemoteUrl = 'https://supabase.kera.et/storage/v1/object/public/parts/hilux_bp_cloud_v2.jpg';

      final updatedPart = await partsDataSource.updatePartWithOutbox(
        ownerId: ownerId,
        id: createdPart.id,
        name: partName,
        partNumber: partNumber,
        photoLocalPath: updatedLocalPath,
        photoUrl: updatedRemoteUrl,
        purchasePrice: 1850.0,
        sellingPrice: 2500.0,
      );

      expect(updatedPart.photoLocalPath, equals(updatedLocalPath));
      expect(updatedPart.photoUrl, equals(updatedRemoteUrl));

      // F. Re-query SQLite to ensure updated photo columns persisted
      final reloadedRawPart = await (db.select(db.spareParts)
            ..where((t) => t.id.equals(createdPart.id)))
          .getSingle();

      expect(reloadedRawPart.photoLocalPath, equals(updatedLocalPath));
      expect(reloadedRawPart.photoUrl, equals(updatedRemoteUrl));
    });

    // =========================================================================
    // 4. IMAGE URL RESOLVER & PATH INTEGRITY
    // =========================================================================
    test('4. resolveImageUrl correctly handles null, http, https, server relative and local paths', () {
      // Null / empty handling
      expect(resolveImageUrl(null), isNull);
      expect(resolveImageUrl('   '), isNull);

      // Absolute HTTP(S) URLs
      const httpsUrl = 'https://images.unsplash.com/photo-parts?w=400';
      expect(resolveImageUrl(httpsUrl), equals(httpsUrl));

      const httpUrl = 'http://api.kera.et/images/sample.jpg';
      expect(resolveImageUrl(httpUrl), equals(httpUrl));

      // Cache-busting support
      final cacheBusted = resolveImageUrl(httpsUrl, cacheBust: true);
      expect(cacheBusted, contains('t='));

      // Windows / Unix path sanitization
      expect(resolveImageUrl(r'uploads\profiles\photo.png'), contains('uploads/profiles/photo.png'));
    });
  });
}
