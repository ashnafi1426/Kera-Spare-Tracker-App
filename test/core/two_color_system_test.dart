import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_colors.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_theme_colors.dart';
import 'package:kera_spare_tracker/core/design/widgets/kera_button.dart';
import 'package:kera_spare_tracker/core/design/widgets/status_badge.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

void main() {
  group('Step 2 - Strict Two-Color System & Role of Colors', () {
    test('KeraThemeColors adheres strictly to sampled Navy and Orange values', () {
      const light = KeraThemeColors.light;
      const dark = KeraThemeColors.dark;

      // Navy scale
      expect(light.navy900, const Color(0xFF061B3F));
      expect(light.navy800, const Color(0xFF0B2A5B));
      expect(light.navy600, const Color(0xFF1D4A8A));
      expect(light.navy100, const Color(0xFFE6ECF7));
      expect(light.navy50, const Color(0xFFF3F5FA));

      // Orange scale
      expect(light.orange500, const Color(0xFFF7941D));
      expect(light.orange600, const Color(0xFFE07F00));
      expect(light.orange700, const Color(0xFFB35F00));
      expect(light.orange100, const Color(0xFFFFF1DC));

      // Neutrals
      expect(light.surfaceWhite, const Color(0xFFFFFFFF));
      expect(light.pageBackground, const Color(0xFFF3F5FA));
      expect(light.border, const Color(0xFFD3DAE8));
      expect(light.textMuted, const Color(0xFF4A5B78));
      expect(light.disabled, const Color(0xFF9AA7BD));

      // Dark canvas uses navy900
      expect(dark.pageBackground, const Color(0xFF061B3F));
    });

    testWidgets('StatusBadge renders without Red/Green/Yellow - always icon + label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  StatusBadge.inStock(quantity: 12, unit: 'pcs'),
                  StatusBadge.lowStock(quantity: 2),
                  StatusBadge.outOfStock(),
                  StatusBadge.synced(),
                  StatusBadge.syncing(),
                  StatusBadge.pending(count: 4),
                  StatusBadge.failed(label: 'Sync Failed'),
                  StatusBadge.conflict(label: 'Version Conflict'),
                  StatusBadge.offline(),
                  StatusBadge.active(label: 'Active Shop'),
                  StatusBadge.suspended(label: 'Suspended'),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify all text labels exist alongside their icons
      expect(find.text('12 pcs'), findsOneWidget);
      expect(find.text('አነስተኛ ክምችት: 2'), findsOneWidget);
      expect(find.text('አልቋል'), findsOneWidget);
      expect(find.text('የተገናኘ'), findsOneWidget);
      expect(find.text('በማመሳሰል ላይ...'), findsOneWidget);
      expect(find.text('ያልተላከ (4)'), findsOneWidget);
      expect(find.text('Sync Failed'), findsOneWidget);
      expect(find.text('Version Conflict'), findsOneWidget);
      expect(find.text('ከመስመር ውጭ'), findsOneWidget);
      expect(find.text('Active Shop'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);

      // Verify icons are properly paired (never color alone)
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);
      expect(find.byIcon(Icons.sync_rounded), findsWidgets);
      expect(find.byIcon(Icons.access_time_rounded), findsWidgets);
      expect(find.byIcon(Icons.cloud_off_rounded), findsWidgets);
      expect(find.byIcon(Icons.block_rounded), findsWidgets);
    });

    testWidgets('KeraButton primary uses solid Orange with bold Navy text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: KeraButton.primary(
                label: 'ሽያጭ መዝግብ (Sell)',
                onPressed: () {},
                isFullWidth: false,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      final elevatedButton = tester.widget<ElevatedButton>(buttonFinder);
      final buttonStyle = elevatedButton.style!;

      expect(buttonStyle.backgroundColor?.resolve({}), KeraColors.orange500);
      expect(buttonStyle.foregroundColor?.resolve({}), KeraColors.navy900);
    });

    testWidgets('KeraButton destructive uses Navy outline with trash icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: KeraButton.destructive(
                label: 'አጥፋ (Delete)',
                onPressed: () {},
                isFullWidth: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('አጥፋ (Delete)'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final buttonStyle = elevatedButton.style!;

      // Background is transparent
      expect(buttonStyle.backgroundColor?.resolve({}), Colors.transparent);
      // Foreground is Navy-800
      expect(buttonStyle.foregroundColor?.resolve({}), KeraColors.navy800);
    });
  });
}
