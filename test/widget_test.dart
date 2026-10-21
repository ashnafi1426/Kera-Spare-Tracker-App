import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:kera_spare_tracker/core/widgets/language_selector_widget.dart';
import 'package:kera_spare_tracker/features/splash/presentation/splash_screen.dart';
import 'package:kera_spare_tracker/main.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockStorage = MockLocalStorageService();
    when(() => mockStorage.saveLocaleCode(any())).thenAnswer((_) async {});
    when(() => mockStorage.getSavedLocaleCode()).thenAnswer((_) async => null);
  });

  testWidgets('App opens in Amharic by default, switch changes whole UI to English and back',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify app opens in Amharic by default
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LanguageSegmentedSwitch), findsOneWidget);
    expect(find.text('የቄራ መለዋወጫ መከታተያ'), findsOneWidget);
    expect(find.text('የመለዋወጫ ዕቃዎች እና የሽያጭ አስተዳደር'), findsOneWidget);
    expect(find.text('ዕቃዎችን በመጫን ላይ...'), findsOneWidget);
    expect(find.textContaining('ኦፍላይን ይሰራል'), findsOneWidget);

    // 2. Tap "English" on the language switch widget
    final englishButton = find.text('English');
    expect(englishButton, findsOneWidget);
    await tester.tap(englishButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // 3. Verify the entire UI switched to English live without restarting
    expect(find.text('Kera Spare Tracker'), findsOneWidget);
    expect(find.text('Spare Parts & Sales Management'), findsOneWidget);
    expect(find.text('Loading your inventory...'), findsOneWidget);
    expect(find.textContaining('Offline-First'), findsOneWidget);
    verify(() => mockStorage.saveLocaleCode('en')).called(1);

    // 4. Tap "አማርኛ" to switch back to Amharic
    final amharicButton = find.text('አማርኛ');
    expect(amharicButton, findsOneWidget);
    await tester.tap(amharicButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // 5. Verify the entire UI switched back to Amharic
    expect(find.text('የቄራ መለዋወጫ መከታተያ'), findsOneWidget);
    expect(find.text('የመለዋወጫ ዕቃዎች እና የሽያጭ አስተዳደር'), findsOneWidget);
    expect(find.text('ዕቃዎችን በመጫን ላይ...'), findsOneWidget);
    verify(() => mockStorage.saveLocaleCode('am')).called(1);
  });

  testWidgets('App restores remembered English locale on restart',
      (WidgetTester tester) async {
    // Simulating app reboot with previously stored English locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          initialLocaleCodeProvider.overrideWithValue('en'),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify app opens directly in English based on saved preference
    expect(find.text('Kera Spare Tracker'), findsOneWidget);
    expect(find.text('Spare Parts & Sales Management'), findsOneWidget);
  });
}
