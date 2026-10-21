import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/splash/presentation/splash_screen.dart';
import 'package:kera_spare_tracker/main.dart';

void main() {
  testWidgets('App renders SplashScreen with localized content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KeraSpareTrackerApp(),
      ),
    );

    // Initial frame pump (SplashScreen has an indeterminate CircularProgressIndicator,
    // so pump() is used instead of pumpAndSettle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify SplashScreen is loaded
    expect(find.byType(SplashScreen), findsOneWidget);

    // Default locale is Amharic: verify Amharic app title and subtitle are displayed
    expect(find.text('የቄራ መለዋወጫ መከታተያ'), findsOneWidget);
    expect(find.text('የመለዋወጫ ዕቃዎች እና የሽያጭ አስተዳደር'), findsOneWidget);
  });
}
