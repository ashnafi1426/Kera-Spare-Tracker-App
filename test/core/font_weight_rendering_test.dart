import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_typography.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

void main() {
  testWidgets('PlusJakartaSans weights 400, 600, and 800 render distinct text styles', (tester) async {
    const textW400 = 'Kera Spare Tracker 400 Regular';
    const textW600 = 'Kera Spare Tracker 600 SemiBold';
    const textW800 = 'Kera Spare Tracker 800 ExtraBold';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              Text(
                textW400,
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ),
              Text(
                textW600,
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              Text(
                textW800,
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final text400Widget = tester.widget<Text>(find.text(textW400));
    final text600Widget = tester.widget<Text>(find.text(textW600));
    final text800Widget = tester.widget<Text>(find.text(textW800));

    expect(text400Widget.style?.fontWeight, FontWeight.w400);
    expect(text600Widget.style?.fontWeight, FontWeight.w600);
    expect(text800Widget.style?.fontWeight, FontWeight.w800);

    expect(text400Widget.style?.fontWeight, isNot(equals(text600Widget.style?.fontWeight)));
    expect(text600Widget.style?.fontWeight, isNot(equals(text800Widget.style?.fontWeight)));
    expect(text400Widget.style?.fontWeight, isNot(equals(text800Widget.style?.fontWeight)));
  });

  testWidgets('fontFamilyFallback includes NotoSansEthiopic for Amharic script', (tester) async {
    expect(KeraTypography.fontFallbacks, contains('NotoSansEthiopic'));
    expect(KeraTypography.fontFallbacks, contains('PlusJakartaSans'));
    expect(AppTheme.lightTheme.appBarTheme.titleTextStyle?.fontFamilyFallback, contains('NotoSansEthiopic'));
    expect(AppTheme.darkTheme.appBarTheme.titleTextStyle?.fontFamilyFallback, contains('NotoSansEthiopic'));
  });
}
