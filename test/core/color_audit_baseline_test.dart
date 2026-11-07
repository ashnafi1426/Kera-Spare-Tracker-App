import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Strict Extended Color Audit Baseline Test', () {
    test('Ensures rogue color counts never increase and redesigned screens have 0 violations', () {
      final baselineFile = File('test/color_audit_baseline.json');
      expect(baselineFile.existsSync(), isTrue,
          reason: 'test/color_audit_baseline.json must exist');

      final baselineData = jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;
      final baselineFiles = (baselineData['files'] as List).cast<Map<String, dynamic>>();

      final baselineMap = <String, Map<String, dynamic>>{};
      for (final item in baselineFiles) {
        baselineMap[item['file'] as String] = item;
      }

      final colorRegex = RegExp(r'\bColors\.(?!white\b|black\b|transparent\b)[a-zA-Z0-9_]+');
      final hexRegex = RegExp(r'\bColor\(0x[0-9a-fA-F]+\)');
      final fromARGBRegex = RegExp(r'\bColor\.fromARGB\([^\)]+\)');
      final fromRGBORegex = RegExp(r'\bColor\.fromRGBO\([^\)]+\)');
      final materialColorRegex = RegExp(r'\bMaterialColor\b');
      final primariesRegex = RegExp(r'\bColors\.(primaries|accents)\b');

      final libDir = Directory('lib');
      final allDartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
        final rel = f.path.replaceAll(r'\', '/');
        return !rel.startsWith('lib/core/theme/') &&
            !rel.startsWith('lib/core/design/tokens/');
      }).toList();

      final currentViolations = <String, int>{};
      final violationsDetails = <String, String>{};

      for (final file in allDartFiles) {
        final relPath = file.path.replaceAll(r'\', '/');
        final content = file.readAsStringSync();
        final cMatches = colorRegex.allMatches(content).length;
        final hMatches = hexRegex.allMatches(content).length;
        final argbMatches = fromARGBRegex.allMatches(content).length;
        final rgboMatches = fromRGBORegex.allMatches(content).length;
        final mcMatches = materialColorRegex.allMatches(content).length;
        final primMatches = primariesRegex.allMatches(content).length;

        final count = cMatches + hMatches + argbMatches + rgboMatches + mcMatches + primMatches;

        if (count > 0) {
          currentViolations[relPath] = count;
          violationsDetails[relPath] =
              '$cMatches Colors.<hue>, $hMatches Color(0x...), ${argbMatches + rgboMatches} dynamic, ${mcMatches + primMatches} material/primaries';
        }
      }

      final regressions = <String>[];
      final unexpectedFiles = <String>[];

      for (final entry in currentViolations.entries) {
        final filePath = entry.key;
        final currentCount = entry.value;

        if (!baselineMap.containsKey(filePath)) {
          unexpectedFiles.add(
            '$filePath has $currentCount new unrecorded violations (${violationsDetails[filePath]}).',
          );
        } else {
          final baseline = baselineMap[filePath]!;
          final allowedCount = baseline['totalViolations'] as int;
          final isRedesigned = baseline['redesigned'] as bool? ?? false;

          if (isRedesigned && currentCount > 0) {
            regressions.add(
              '$filePath is marked REDESIGNED but has $currentCount violations (${violationsDetails[filePath]}). Must be 0.',
            );
          } else if (currentCount > allowedCount) {
            regressions.add(
              '$filePath regressed! Current violations: $currentCount > Baseline allowed: $allowedCount.',
            );
          }
        }
      }

      expect(unexpectedFiles, isEmpty,
          reason: 'Found new files with rogue color violations outside baseline:\n${unexpectedFiles.join('\n')}');

      expect(regressions, isEmpty,
          reason: 'Found color regressions against baseline:\n${regressions.join('\n')}');

      final redesignedScreens = {
        'lib/features/splash/presentation/splash_screen.dart',
        'lib/features/auth/presentation/screens/welcome_screen.dart',
        'lib/features/auth/presentation/screens/register_screen.dart',
        'lib/features/auth/presentation/screens/login_screen.dart',
      };
      for (final screen in redesignedScreens) {
        expect(currentViolations[screen] ?? 0, 0,
            reason: '$screen is completed in Step 2 and must strictly have 0 violations');
      }
    });
  });
}
