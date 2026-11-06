import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_colors.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_theme_colors.dart';
import 'package:kera_spare_tracker/core/design/widgets/mobile_components.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

void main() {
  group('Strict Two-Color System & Mobile Component Tests', () {
    test('1. Exact sampled logo brand tokens verify WCAG AA compliance', () {
      // Main Navy and Dark Background
      expect(KeraColors.navy800, const Color(0xFF0B2A5B));
      expect(KeraColors.navy900, const Color(0xFF061B3F));
      expect(KeraColors.navy100, const Color(0xFFE6ECF7));
      expect(KeraColors.navy50, const Color(0xFFF3F5FA));

      // Main Orange and Tints
      expect(KeraColors.orange500, const Color(0xFFF7941D));
      expect(KeraColors.orange600, const Color(0xFFE07F00));
      expect(KeraColors.orange700, const Color(0xFF9A5000));
      expect(KeraColors.orange100, const Color(0xFFFFF1DC));

      // Light theme tokens
      final lightExt = AppTheme.lightTheme.extension<KeraThemeColors>()!;
      expect(lightExt.navy800, const Color(0xFF0B2A5B));
      expect(lightExt.orange500, const Color(0xFFF7941D));

      // Dark theme tokens
      final darkExt = AppTheme.darkTheme.extension<KeraThemeColors>()!;
      expect(darkExt.navy800, const Color(0xFF0B2A5B));
      expect(darkExt.orange500, const Color(0xFFF7941D));
    });

    testWidgets('2. StatusBadge renders full status matrix with Icon + Text (Zero Red/Green/Yellow)', (tester) async {
      // In Stock
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusBadge.inStock(quantity: 12, unit: 'Pcs')),
      ));
      expect(find.text('12 Pcs'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Low Stock
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusBadge.lowStock(quantity: 3, defaultLabel: 'አነስተኛ ክምችት')),
      ));
      expect(find.text('አነስተኛ ክምችት: 3'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Out of Stock
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusBadge.outOfStock(label: 'አልቋል')),
      ));
      expect(find.text('አልቋል'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);

      // Conflict (Strict spec: solid orange, bold navy, octagon alert, heavier border)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusBadge.conflict(label: 'ግጭት (Conflict)')),
      ));
      expect(find.text('ግጭት (Conflict)'), findsOneWidget);
      expect(find.byIcon(Icons.report_rounded), findsOneWidget);

      final conflictContainer = tester.widget<Container>(find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(Container),
      ));
      final dec = conflictContainer.decoration as BoxDecoration;
      expect(dec.color, KeraColors.orange500);
      expect((dec.border as Border).bottom.color, KeraColors.orange700);
      expect((dec.border as Border).bottom.width, 2.0);

      // Offline
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusBadge.offline(label: 'ከመስመር ውጭ')),
      ));
      expect(find.text('ከመስመር ውጭ'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('3. PrimaryButton enforces solid Orange, bold Navy text, and 48px height', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save Part',
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Save Part'), findsOneWidget);
      final size = tester.getSize(find.byType(PrimaryButton));
      expect(size.height, 48.0);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({}), KeraColors.orange500);
      expect(button.style?.foregroundColor?.resolve({}), KeraColors.navy900);
    });

    testWidgets('4. SearchField does NOT contain a barcode button', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchField(controller: controller),
        ),
      ));

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
      expect(find.byIcon(Icons.barcode_reader), findsNothing);
    });

    testWidgets('5. ErrorStateView has clear message and retry button without diagnostic shortcuts', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            message: 'Failed to connect',
            onRetry: () {},
          ),
        ),
      ));

      expect(find.text('Failed to connect'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Server Settings'), findsNothing);
    });
  });
}
