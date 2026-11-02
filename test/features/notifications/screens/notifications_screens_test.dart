import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/notifications/presentation/providers/notification_settings_provider.dart';
import 'package:kera_spare_tracker/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:kera_spare_tracker/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:kera_spare_tracker/features/sync/data/services/sync_push_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncPushService extends Mock implements SyncPushService {}

void main() {
  late MockSyncPushService mockSyncPushService;

  setUp(() {
    mockSyncPushService = MockSyncPushService();
  });

  group('NotificationCenterScreen Tests', () {
    testWidgets('renders top bar, mark all read, filter chips, and alert cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncPushServiceProvider.overrideWithValue(mockSyncPushService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const NotificationCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ኬራ ስፔር / Kera Spare'), findsOneWidget);
      expect(find.text('የማሳወቂያ ማዕከል'), findsOneWidget);
      expect(find.text('ሁሉንም አንብብ'), findsOneWidget);

      // Verify filter chips
      expect(find.textContaining('ሁሉም (All'), findsOneWidget);
      expect(find.textContaining('ያልተነበቡ (Unread'), findsOneWidget);
      expect(find.textContaining('የክምችት (Stock'), findsOneWidget);
      expect(find.textContaining('ሽያጭና ሲንክ (Sales'), findsOneWidget);

      // Verify alert cards
      expect(find.text('CTP D6R Track Roller'), findsOneWidget);
      expect(find.text('CAT 320D Oil Filter (ኦሪጅናል)'), findsOneWidget);
      expect(find.text('ደረሰኝ / Receipt #KS-POS-9844'), findsOneWidget);
      expect(find.text('የኔትወርክ መቋረጥ (Network Timeout)'), findsOneWidget);
    });

    testWidgets('filtering by Stock shows only out of stock and low stock items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncPushServiceProvider.overrideWithValue(mockSyncPushService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const NotificationCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Stock chip
      final stockChip = find.textContaining('የክምችት (Stock');
      await tester.ensureVisible(stockChip);
      await tester.tap(stockChip);
      await tester.pumpAndSettle();

      expect(find.text('CTP D6R Track Roller'), findsOneWidget);
      expect(find.text('CAT 320D Oil Filter (ኦሪጅናል)'), findsOneWidget);
      expect(find.text('ደረሰኝ / Receipt #KS-POS-9844'), findsNothing);
      expect(find.text('የኔትወርክ መቋረጥ (Network Timeout)'), findsNothing);
    });

    testWidgets('mark all read updates unread counter', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncPushServiceProvider.overrideWithValue(mockSyncPushService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const NotificationCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('4 አዲስ'), findsOneWidget);

      await tester.tap(find.text('ሁሉንም አንብብ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('4 አዲስ'), findsNothing);
      expect(find.textContaining('ያልተነበቡ (Unread 0)'), findsOneWidget);
    });
  });

  group('NotificationSettingsScreen Tests', () {
    testWidgets('renders push toggle hero, stock alert toggles, sales alert toggles, and channels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationSettingsProvider.overrideWith(() => _MockNotificationSettingsNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const NotificationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('የማሳወቂያ ቅንብሮች'), findsOneWidget);
      expect(find.text('የስራ ማንቂያዎች'), findsOneWidget);
      expect(find.text('የክምችት እና ዕቃዎች ማንቂያ'), findsOneWidget);
      expect(find.text('አነስተኛ ክምችት ሲደርስ'), findsOneWidget);
      expect(find.text('የሽያጭ ማንቂያዎች'), findsOneWidget);
      expect(find.text('የዳታ ማመሳሰል እና መስመር ውጭ'), findsOneWidget);
      expect(find.text('በቴሌግራም ቦት (Telegram Bot)'), findsOneWidget);
      expect(find.text('ቅንብሮቹን አስቀምጥ (Save Notification Settings)'), findsOneWidget);
    });
  });
}

class _MockNotificationSettingsNotifier extends NotificationSettingsNotifier {
  @override
  Future<NotificationSettings> build() async {
    return const NotificationSettings();
  }

  @override
  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = AsyncValue.data(newSettings);
  }
}

