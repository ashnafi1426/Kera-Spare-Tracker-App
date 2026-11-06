import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/design.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

void main() {
  group('Kera Design Tokens Test', () {
    test('KeraColors adheres to Google Stitch specifications', () {
      expect(KeraColors.primaryNavy, const Color(0xFF0B2A5B));
      expect(KeraColors.keraOrange, const Color(0xFFF7941D));
      expect(KeraColors.actionBlue, const Color(0xFF0B2A5B));
      expect(KeraColors.utilityTeal, const Color(0xFF0B2A5B));
      expect(KeraColors.surfaceCanvas, const Color(0xFFF3F5FA));
      expect(KeraColors.surfacePure, const Color(0xFFFFFFFF));
      expect(KeraColors.outlineBorder, const Color(0xFFD3DAE8));
      expect(KeraColors.stockInBg, const Color(0xFFE6ECF7));
      expect(KeraColors.stockInText, const Color(0xFF0B2A5B));
      expect(KeraColors.stockLowBg, const Color(0xFFFFF1DC));
      expect(KeraColors.stockLowText, const Color(0xFF9A5000));
      expect(KeraColors.stockOutBg, const Color(0xFFF7941D));
      expect(KeraColors.stockOutText, const Color(0xFF061B3F));
    });

    test('KeraTypography uses NotoSansEthiopic and proper scale', () {
      final h1 = KeraTypography.headlineLarge();
      expect(h1.fontFamily, 'NotoSansEthiopic');
      expect(h1.fontSize, 28);
      expect(h1.fontWeight, FontWeight.w700);

      final body = KeraTypography.bodyLarge();
      expect(body.fontSize, 16);
      expect(body.fontWeight, FontWeight.w400);

      final stat = KeraTypography.numericStat();
      expect(stat.fontSize, 24);
      expect(stat.fontWeight, FontWeight.w700);
      expect(stat.fontFeatures, isNotEmpty);
    });

    test('KeraSpacing and KeraRadii match specifications', () {
      expect(KeraSpacing.xs, 4.0);
      expect(KeraSpacing.sm, 8.0);
      expect(KeraSpacing.md, 12.0);
      expect(KeraSpacing.lg, 16.0);
      expect(KeraSpacing.minTouchTarget, 48.0);

      expect(KeraRadii.micro, 6.0);
      expect(KeraRadii.defaultRadius, 10.0);
      expect(KeraRadii.lg, 16.0);
      expect(KeraRadii.full, 9999.0);
    });

    test('AppTheme.lightTheme integrates Stitch design tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, KeraColors.surfaceCanvas);
      expect(theme.colorScheme.primary, KeraColors.primaryNavy);
      expect(theme.colorScheme.secondary, KeraColors.keraOrange);
      expect(theme.colorScheme.tertiary, KeraColors.navy600);
      expect(theme.appBarTheme.backgroundColor, KeraColors.primaryNavy);
      expect(theme.cardTheme.color, KeraColors.surfacePure);
    });
  });

  group('Kera Reusable Widgets Test', () {
    testWidgets('KeraButton renders with min touch target and handles press', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: KeraButton.primary(
                label: 'Save Part',
                onPressed: () => pressed = true,
                isFullWidth: false,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Save Part'), findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      expect(pressed, isTrue);
    });

    testWidgets('KeraButton shows loading spinner when isLoading = true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: KeraButton.primary(
                label: 'Submitting',
                isLoading: true,
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submitting'), findsNothing);
    });

    testWidgets('KeraStatusBadge renders In-Stock and Low-Stock accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                KeraStatusBadge.inStock(quantity: 15, unit: 'pcs'),
                KeraStatusBadge.lowStock(quantity: 2),
                KeraStatusBadge.outOfStock(),
                KeraStatusBadge.syncPending(count: 3),
              ],
            ),
          ),
        ),
      );

      expect(find.text('15 pcs'), findsOneWidget);
      expect(find.text('አነስተኛ ክምችት: 2'), findsOneWidget);
      expect(find.text('አልቋል'), findsOneWidget);
      expect(find.text('ያልተላከ (3)'), findsOneWidget);
    });

    testWidgets('KeraProductCard renders title, brand, shelf, price and stock', (tester) async {
      bool tapped = false;
      bool quickActionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: KeraProductCard(
              title: 'CAT 320D Oil Filter',
              partNumber: '1R-0716',
              brandName: 'CAT',
              shelfLocation: 'Shelf B-4',
              price: 3450,
              stockQuantity: 8,
              unit: 'pcs',
              onTap: () => tapped = true,
              onQuickAction: () => quickActionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('CAT 320D Oil Filter'), findsOneWidget);
      expect(find.text('#1R-0716'), findsOneWidget);
      expect(find.text('CAT'), findsOneWidget);
      expect(find.text('Shelf B-4'), findsOneWidget);
      expect(find.text('3450 ብር'), findsOneWidget);
      expect(find.text('8 pcs'), findsOneWidget);

      await tester.tap(find.text('CAT 320D Oil Filter'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(quickActionTapped, isTrue);
    });

    testWidgets('KeraTextField renders label and handles input', (tester) async {
      String typedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: KeraTextField(
                label: 'Part OEM Number',
                hintText: 'Enter OEM...',
                showClearButton: true,
                onChanged: (val) => typedValue = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Part OEM Number'), findsOneWidget);
      expect(find.text('Enter OEM...'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '1R-0716');
      expect(typedValue, '1R-0716');
    });

    testWidgets('KeraEmptyState renders icon, title, and action trigger', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: KeraEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Spare Parts Found',
              description: 'Add your first spare part to start tracking inventory.',
              actionLabel: '+ Add Part',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Spare Parts Found'), findsOneWidget);
      expect(find.text('Add your first spare part to start tracking inventory.'), findsOneWidget);
      expect(find.text('+ Add Part'), findsOneWidget);

      await tester.tap(find.text('+ Add Part'));
      expect(actionTriggered, isTrue);
    });
  });
}

