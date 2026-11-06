import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/core/design/widgets/ must NOT contain any hardcoded Amharic strings', () {
    final widgetsDir = Directory('lib/core/design/widgets');
    expect(widgetsDir.existsSync(), isTrue, reason: 'widgets directory must exist');

    final ethiopicRegex = RegExp(r'[\u1200-\u137F]');
    final violations = <String>[];

    for (final entity in widgetsDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (ethiopicRegex.hasMatch(line)) {
            violations.add('${entity.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} hardcoded Ethiopic/Amharic string(s) in lib/core/design/widgets/:\n'
        '${violations.join("\n")}\n'
        'Requirement: All component strings must come from l10n ARB files or localized parameters.',
      );
    }
  });
}

