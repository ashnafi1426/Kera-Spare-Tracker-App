import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/password_hasher.dart';

void main() {
  late PasswordHasher hasher;

  setUp(() {
    hasher = PasswordHasher(iterations: 1000); // lower iterations for fast testing
  });

  group('PasswordHasher', () {
    test('hashes password with random salt generating unique hashes for same password',
        () async {
      const password = 'mySecretPassword123';
      final hash1 = await hasher.hashPassword(password);
      final hash2 = await hasher.hashPassword(password);

      expect(hash1, isNotEmpty);
      expect(hash2, isNotEmpty);
      expect(hash1, contains('\$'));
      expect(hash1, isNot(equals(hash2))); // Different salts ensure different outputs
    });

    test('verifies correct password against generated hash', () async {
      const password = 'KeraSparePass2026';
      final hash = await hasher.hashPassword(password);

      final isValid = await hasher.verifyPassword(
        password: password,
        storedHash: hash,
      );
      expect(isValid, isTrue);
    });

    test('rejects incorrect password against generated hash', () async {
      const password = 'CorrectPassword';
      final hash = await hasher.hashPassword(password);

      final isValid = await hasher.verifyPassword(
        password: 'WrongPassword',
        storedHash: hash,
      );
      expect(isValid, isFalse);
    });

    test('gracefully rejects corrupted or invalid hash formats', () async {
      final isValid = await hasher.verifyPassword(
        password: 'Password',
        storedHash: 'invalid_format_without_dollar',
      );
      expect(isValid, isFalse);
    });
  });
}
