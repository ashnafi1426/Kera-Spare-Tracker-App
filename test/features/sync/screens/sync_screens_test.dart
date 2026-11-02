import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/sync/domain/models/sync_conflict_model.dart';
import 'package:kera_spare_tracker/features/sync/presentation/providers/sync_providers.dart';
import 'package:kera_spare_tracker/features/sync/presentation/screens/conflict_resolution_screen.dart';
import 'package:kera_spare_tracker/features/sync/presentation/screens/offline_dashboard_screen.dart';
import 'package:kera_spare_tracker/features/sync/presentation/screens/sync_center_screen.dart';
import 'package:kera_spare_tracker/features/sync/presentation/screens/sync_diagnostics_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class FakeConflictsNotifier extends ConflictsNotifier {
  final List<SyncConflictModel> initialConflicts;
  FakeConflictsNotifier([this.initialConflicts = const []]);

  @override
  List<SyncConflictModel> build() => initialConflicts;
}

Widget createTestApp({
  required Widget child,
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      syncQueueItemsStreamProvider.overrideWith((ref) => Stream.value([
            SyncQueueItem(
              id: 1,
              tableTarget: 'sales',
              recordId: 'sale_101',
              operation: SyncOperation.insert,
              payload:
                  '{"receipt_number":"KS-9821","total_amount":4200.0,"payment_method":"Cash"}',
              attempts: 0,
              lastError: null,
              createdAt: DateTime(2026, 11, 2, 10, 42),
            ),
            SyncQueueItem(
              id: 2,
              tableTarget: 'stock_movements',
              recordId: 'mov_202',
              operation: SyncOperation.insert,
              payload: '{"note":"Shelf D-2","quantity_change":-4}',
              attempts: 1,
              lastError: 'HTTP 422: Negative stock unpermitted',
              createdAt: DateTime(2026, 11, 2, 10, 15),
            ),
          ])),
      pendingSyncCountStreamProvider.overrideWith((ref) => Stream.value(2)),
      isOnlineStreamProvider.overrideWith((ref) => Stream.value(false)),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('Sync Module Screens', () {
    testWidgets('SyncCenterScreen renders header, hero banner and actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const SyncCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('የዳታ ማመሳከሪያ ማዕከል'), findsOneWidget);
      expect(find.text('2 የዳታ ለውጦች አልተላኩም'), findsOneWidget);
      expect(find.text('አሁን ሞክር / Sync Now'), findsOneWidget);
      expect(find.text('ያልተላኩ ሽያጮች (Offline Sales)'), findsOneWidget);
      expect(find.text('የክምችት ማስተካከያዎች (Stock Movements)'), findsOneWidget);
      expect(find.text('Addis Central Server • SQLite Cache Valid'), findsOneWidget);
    });

    testWidgets(
        'ConflictResolutionScreen renders discrepancy matrix and resolution actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testConflict = SyncConflictModel(
        id: 'c1',
        partId: 'p1',
        partName: 'Toyota Hilux የፊት ፍሬን (Brake Pads)',
        oemNumber: '04465-0K240',
        shelfLocation: 'Shelf A-4',
        localPrice: 4200.0,
        serverPrice: 4000.0,
        localStock: 12.0,
        serverStock: 15.0,
        localUpdatedBy: 'ይህ ስልክ (This Device)',
        serverUpdatedBy: 'ዋና ሰርቨር (HQ Server)',
        detectedAt: DateTime(2026, 11, 2, 10, 30),
      );

      await tester.pumpWidget(createTestApp(
        child: const ConflictResolutionScreen(),
        overrides: [
          activeConflictsProvider.overrideWith(
            () => FakeConflictsNotifier([testConflict]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('ማስጠንቀቂያ / Conflict Advisory'), findsOneWidget);
      expect(find.text('Toyota Hilux የፊት ፍሬን (Brake Pads)'), findsOneWidget);
      expect(find.text('የንጽጽር ዝርዝር / Comparison Matrix'), findsOneWidget);
      expect(find.text('የመሸጫ ዋጋ / Selling Price'), findsOneWidget);
      expect(find.textContaining('Smart Merge'), findsOneWidget);
      expect(find.textContaining('Keep Local'), findsOneWidget);
      expect(find.textContaining('Accept Server'), findsOneWidget);
      expect(find.text('ውሳኔውን አረጋግጥ / Confirm Resolution'), findsOneWidget);
    });

    testWidgets('SyncDiagnosticsScreen renders diagnostics and error inspection',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
          createTestApp(child: const SyncDiagnosticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('የማመሳከሪያ ውጤት እና ስህተት'), findsOneWidget);
      expect(find.text('የስህተት ዝርዝር እና መንስኤ'), findsOneWidget);
      expect(find.text('ዳግም ሞክር / Retry Now'), findsOneWidget);
      expect(find.text('የስርዓት እና ኔትወርክ ሁኔታ / System Diagnostics'),
          findsOneWidget);
    });

    testWidgets(
        'OfflineDashboardScreen renders offline alerts, local stats and queue feed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
          createTestApp(child: const OfflineDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ኬራ ስፔር / Kera Spare'), findsOneWidget);
      expect(find.text('ከመስመር ውጭ ይሰራል'), findsOneWidget);
      expect(find.text('የመጠባበቂያ ወረፋ'), findsOneWidget);
      expect(find.text('Queue #2'), findsOneWidget);
      expect(find.text('ፈጣን ሽያጭ'), findsOneWidget);
      expect(find.text('ደረሰኝ አትም'), findsOneWidget);
      expect(find.text('ዕቃ ፈልግ'), findsOneWidget);
      expect(find.text('የዳታ ደህንነት ማረጋገጫ (Offline Resilience)'), findsOneWidget);
    });
  });
}
