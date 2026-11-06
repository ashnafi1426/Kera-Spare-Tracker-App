import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/tokens/kera_theme_colors.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';

double _relativeLuminance(Color color) {
  double transform(double component) {
    return component <= 0.04045
        ? component / 12.92
        : pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Comprehensive Light & Dark WCAG AA Contrast Compliance Tests', () {
    test('Calculates and prints contrast ratio matrix for all theme elements', () {
      final light = AppTheme.lightTheme.extension<KeraThemeColors>()!;
      final dark = AppTheme.darkTheme.extension<KeraThemeColors>()!;

      final pairs = <Map<String, dynamic>>[
        // Light theme pairs
        {
          'theme': 'Light',
          'role': 'Primary Body Text on White',
          'fg': light.textPrimary,
          'bg': light.surfaceWhite,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Secondary Text on White',
          'fg': light.textSecondary,
          'bg': light.surfaceWhite,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Orange-700 on Orange-100 Chip',
          'fg': light.orange700,
          'bg': light.orange100,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Navy-800 on Navy-100 Chip',
          'fg': light.navy800,
          'bg': light.navy100,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Bold Navy-900 on Orange-500 Primary Button',
          'fg': light.navy900,
          'bg': light.orange500,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Out of Stock Solid Chip (Navy-900 on Orange-500)',
          'fg': light.navy900,
          'bg': light.orange500,
          'isLarge': false,
        },
        {
          'theme': 'Light',
          'role': 'Large Page Title (Navy-800 on Navy-50 Canvas)',
          'fg': light.navy800,
          'bg': light.pageBackground,
          'isLarge': true,
        },

        // Dark theme pairs
        {
          'theme': 'Dark',
          'role': 'Primary Text on Dark Card',
          'fg': dark.textPrimary,
          'bg': dark.cardBackground,
          'isLarge': false,
        },
        {
          'theme': 'Dark',
          'role': 'Secondary Text on Dark Card',
          'fg': dark.textSecondary,
          'bg': dark.cardBackground,
          'isLarge': false,
        },
        {
          'theme': 'Dark',
          'role': 'Orange-500 Accent Icon on Dark Canvas',
          'fg': dark.orange500,
          'bg': dark.pageBackground,
          'isLarge': true,
        },
        {
          'theme': 'Dark',
          'role': 'White Text on Navy-900 Background',
          'fg': Colors.white,
          'bg': dark.pageBackground,
          'isLarge': false,
        },
        {
          'theme': 'Dark',
          'role': 'Bold Navy-900 on Orange-500 Primary Button',
          'fg': dark.navy900,
          'bg': dark.orange500,
          'isLarge': false,
        },
      ];

      debugPrint('\n=================== WCAG AA CONTRAST RATIO TABLE ===================');
      debugPrint('| Theme | UI Role                                    | Ratio    | Target | Status |');
      debugPrint('|-------|--------------------------------------------|----------|--------|--------|');

      for (final p in pairs) {
        final ratio = _contrastRatio(p['fg'] as Color, p['bg'] as Color);
        final target = (p['isLarge'] as bool) ? 3.0 : 4.5;
        final pass = ratio >= target;
        final theme = (p['theme'] as String).padRight(5);
        final role = (p['role'] as String).padRight(42);
        final ratioStr = '${ratio.toStringAsFixed(2)}:1'.padRight(8);
        final targetStr = '${target.toStringAsFixed(1)}:1'.padRight(6);
        final status = pass ? 'PASS' : 'FAIL';

        debugPrint('| $theme | $role | $ratioStr | $targetStr | $status   |');
        expect(pass, isTrue,
            reason: '${p['theme']} ${p['role']} failed contrast: $ratioStr < $targetStr');
      }
      debugPrint('====================================================================\n');
    });
  });
}
