import 'dart:io';

void main() {
  final file = File('lib/core/router/app_router.dart');
  var content = file.readAsStringSync();

  // Normalize line endings
  content = content.replaceAll('\r\n', '\n');

  // Remove the duplicate GoRoute for /admin/owners/add at the second location
  const duplicateBlock = '''          GoRoute(
            path: '/admin/owners/add',
            name: 'admin-owners-add',
            builder: (context, state) => const AdminAddOwnerScreen(),
          ),
''';

  // Find second index of duplicateBlock
  final firstIdx = content.indexOf(duplicateBlock);
  if (firstIdx != -1) {
    final secondIdx = content.indexOf(duplicateBlock, firstIdx + 1);
    if (secondIdx != -1) {
      content = content.replaceRange(secondIdx, secondIdx + duplicateBlock.length, '');
    }
  }

  // Remove duplicate builder line in admin-backup
  content = content.replaceAll(
    '''            builder: (context, state) => const AdminBackupScreen(),\n            builder: (context, state) => const AdminAccountScreen(),''',
    '''            builder: (context, state) => const AdminBackupScreen(),''',
  );

  file.writeAsStringSync(content);
  print('Successfully cleaned app_router.dart');
}

