import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/validators.dart';

void main() {
  group('Validators - Ethiopian Phone', () {
    test('accepts valid 10-digit Ethio Telecom numbers starting with 09', () {
      expect(Validators.validateEthiopianPhone('0911223344'), isNull);
      expect(Validators.validateEthiopianPhone('0923456789'), isNull);
    });

    test('accepts valid 10-digit Safaricom numbers starting with 07', () {
      expect(Validators.validateEthiopianPhone('0711223344'), isNull);
    });

    test('accepts numbers with international prefix +251 and 251', () {
      expect(Validators.validateEthiopianPhone('+251911223344'), isNull);
      expect(Validators.validateEthiopianPhone('251711223344'), isNull);
    });

    test('rejects empty and null inputs', () {
      expect(Validators.validateEthiopianPhone(null), isNotNull);
      expect(Validators.validateEthiopianPhone('   '), isNotNull);
    });

    test('rejects invalid lengths or characters', () {
      expect(Validators.validateEthiopianPhone('09112233'), isNotNull); // too short
      expect(Validators.validateEthiopianPhone('091122334455'), isNotNull); // too long
      expect(Validators.validateEthiopianPhone('0811223344'), isNotNull); // not 7 or 9
      expect(Validators.validateEthiopianPhone('091122abcd'), isNotNull);
    });

    test('normalizes numbers to standard +251 format', () {
      expect(Validators.normalizeEthiopianPhone('0911223344'), '+251911223344');
      expect(Validators.normalizeEthiopianPhone('0711223344'), '+251711223344');
      expect(Validators.normalizeEthiopianPhone('+251911223344'), '+251911223344');
      expect(Validators.normalizeEthiopianPhone('251711223344'), '+251711223344');
    });
  });

  group('Validators - Quantity & Price', () {
    test('validates positive quantity', () {
      expect(Validators.validateQuantity('5'), isNull);
      expect(Validators.validateQuantity('0.5'), isNull);
      expect(Validators.validateQuantity('0'), isNotNull);
      expect(Validators.validateQuantity('-2'), isNotNull);
      expect(Validators.validateQuantity('abc'), isNotNull);
      expect(Validators.validateQuantity(''), isNotNull);
    });

    test('validates price allowing 0 or positive numbers', () {
      expect(Validators.validatePrice('0'), isNull);
      expect(Validators.validatePrice('250.75'), isNull);
      expect(Validators.validatePrice('-10'), isNotNull);
      expect(Validators.validatePrice(''), isNotNull);
    });
  });

  group('Validators - Required & Password', () {
    test('validates required fields', () {
      expect(Validators.validateRequired('CAT Cylinder'), isNull);
      expect(Validators.validateRequired(''), isNotNull);
      expect(Validators.validateRequired(null), isNotNull);
    });

    test('validates password length', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('securePass'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });
  });
}
