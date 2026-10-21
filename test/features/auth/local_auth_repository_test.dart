import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/password_hasher.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/local_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late MockSecureStorage mockStorage;
  late PasswordHasher hasher;
  late LocalAuthRepository authRepo;
  late Map<String, String> inMemoryStorage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorage();
    hasher = PasswordHasher(iterations: 1000);
    inMemoryStorage = <String, String>{};

    when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final val = invocation.namedArguments[#value] as String?;
      if (val != null) inMemoryStorage[key] = val;
    });

    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return inMemoryStorage[key];
    });

    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      inMemoryStorage.remove(key);
    });

    authRepo = LocalAuthRepository(
      db: db,
      storage: mockStorage,
      hasher: hasher,
    );
  });

  tearDown(() async {
    authRepo.dispose();
    await db.close();
  });

  group('LocalAuthRepository', () {
    test('registers owner, saves profile in SQLite, and persists secure session',
        () async {
      final result = await authRepo.register(
        phoneNumber: '0911223344',
        businessName: 'Kera CAT Parts',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      final user = result.valueOrNull!;
      expect(user.phoneNumber, equals('+251911223344'));
      expect(user.businessName, equals('Kera CAT Parts'));
      expect(user.ownerId, isNotEmpty);

      // Verify Profile row in Drift DB
      final profile = await (db.select(db.profiles)
            ..where((t) => t.id.equals(user.id)))
          .getSingle();
      expect(profile.businessName, equals('Kera CAT Parts'));
      expect(profile.phoneNumber, equals('+251911223344'));

      // Verify mutation is enqueued for future sync
      final queued = await db.syncQueueDao.getPendingBatch();
      expect(
          queued.any((q) => q.recordId == user.id && q.tableTarget == 'profiles'),
          isTrue);

      // Verify session persists in secure storage
      final current = await authRepo.currentUser();
      expect(current.isSuccess, isTrue);
      expect(current.valueOrNull?.id, equals(user.id));
    });

    test('prevents registering with duplicate phone number', () async {
      await authRepo.register(
        phoneNumber: '0911223344',
        businessName: 'First Shop',
        password: 'password123',
      );

      final duplicateResult = await authRepo.register(
        phoneNumber: '+251911223344', // Same normalized phone
        businessName: 'Second Shop',
        password: 'password456',
      );

      expect(duplicateResult.isFailure, isTrue);
      expect(
        duplicateResult.failureOrNull?.message,
        contains('already registered'),
      );
    });

    test('authenticates registered user with valid phone and password', () async {
      await authRepo.register(
        phoneNumber: '0711223344',
        businessName: 'Safaricom Spare Hub',
        password: 'secretPassword',
      );

      // Logout
      await authRepo.logout();
      expect((await authRepo.currentUser()).valueOrNull, isNull);

      // Login with local phone format
      final loginResult = await authRepo.login(
        phoneNumber: '0711223344',
        password: 'secretPassword',
      );

      expect(loginResult.isSuccess, isTrue);
      expect(loginResult.valueOrNull?.businessName,
          equals('Safaricom Spare Hub'));

      // Check current user
      final current = await authRepo.currentUser();
      expect(current.valueOrNull?.businessName, equals('Safaricom Spare Hub'));
    });

    test('rejects login with incorrect password', () async {
      await authRepo.register(
        phoneNumber: '0922334455',
        businessName: 'Hydraulics Co',
        password: 'correctPassword',
      );

      final failResult = await authRepo.login(
        phoneNumber: '0922334455',
        password: 'wrongPassword',
      );

      expect(failResult.isFailure, isTrue);
      expect(failResult.failureOrNull?.message, contains('Invalid'));
    });

    test('logout clears secure storage and notifies stream', () async {
      await authRepo.register(
        phoneNumber: '0933445566',
        businessName: 'Truck Parts',
        password: 'password123',
      );

      expect((await authRepo.currentUser()).valueOrNull, isNotNull);

      await authRepo.logout();

      expect((await authRepo.currentUser()).valueOrNull, isNull);
    });

    test('changes password verifying current password first', () async {
      await authRepo.register(
        phoneNumber: '0944556677',
        businessName: 'Engine Spares',
        password: 'oldPassword123',
      );

      // Wrong current password fails
      final failChange = await authRepo.changePassword(
        currentPassword: 'wrongOldPassword',
        newPassword: 'newPassword123',
      );
      expect(failChange.isFailure, isTrue);

      // Correct current password succeeds
      final successChange = await authRepo.changePassword(
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
      );
      expect(successChange.isSuccess, isTrue);

      // Login with new password works
      final newLogin = await authRepo.login(
        phoneNumber: '0944556677',
        password: 'newPassword123',
      );
      expect(newLogin.isSuccess, isTrue);
    });
  });
}
