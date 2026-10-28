import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/services/session_store.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/database_provider.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/inventory_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/screens/inventory_screen.dart';
import 'package:kera_spare_tracker/main.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeInventoryListNotifier extends InventoryListNotifier {
  @override
  InventoryListState build() => const InventoryListState();
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadNextPage() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockSecureStorage mockStorage;
  late Map<String, String> inMemoryStorage;
  late SessionStore sessionStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorage();
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

    sessionStore = SessionStore(storage: mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'Airplane mode startup: launches app with stored session and immediately shows inventory screen without network calls (Rule 3)',
      (WidgetTester tester) async {
    const user = AuthUser(
      id: 'owner-airplane-1',
      ownerId: 'owner-airplane-1',
      phoneNumber: '+251911998877',
      businessName: 'Airplane Mode Auto Parts',
      role: 'owner',
    );

    // 1. Seed secure storage with valid session tokens & profile
    await sessionStore.saveSession(
      accessToken: 'offline-access-token',
      refreshToken: 'offline-refresh-token',
      ownerId: user.ownerId,
      ownerPhone: user.phoneNumber,
      ownerBusinessName: user.businessName,
      userProfile: user.toJson(),
    );

    // 2. Seed local Drift database profile
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: const Value('owner-airplane-1'),
            ownerId: 'owner-airplane-1',
            phoneNumber: const Value('+251911998877'),
            businessName: const Value('Airplane Mode Auto Parts'),
            role: const Value(UserRole.owner),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );

    // 3. Seed some initial parts in local SQLite database
    await db.into(db.spareParts).insert(
          SparePartsCompanion.insert(
            id: const Value('part-1'),
            ownerId: 'owner-airplane-1',
            name: const Value('Toyota Spark Plug'),
            cachedQuantity: const Value(24.0),
            sellingPrice: const Value(450.0),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );

    // 4. Strict Airplane Mode Dio client: throws if ANY network call is attempted
    final airplaneModeDio = Dio(
      BaseOptions(
        baseUrl: 'http://unreachable-offline.local',
        connectTimeout: const Duration(milliseconds: 1),
      ),
    );
    airplaneModeDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        throw StateError('CRITICAL: Network call attempted in airplane mode! Route: ${options.path}');
      },
    ));

    final testRepo = ApiAuthRepository(
      db: db,
      dioClient: airplaneModeDio,
      storage: mockStorage,
      sessionStore: sessionStore,
    );

    // 5. Pump application
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(sessionStore),
          apiAuthRepositoryProvider.overrideWithValue(testRepo),
          inventoryListProvider.overrideWith(_FakeInventoryListNotifier.new),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    // Initial pump shows splash or builds router
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // 6. Verify that HomeScreen and InventoryScreen are displayed immediately!
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(InventoryScreen), findsOneWidget);

    // 7. Cleanly unmount widget tree and flush any stream query close timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
