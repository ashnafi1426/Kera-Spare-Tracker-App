import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';

void main() {
  group('Result Type', () {
    test('Success returns value and isSuccess is true', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, equals(42));
      expect(result.failureOrNull, isNull);

      final mapped = result.map((data) => data * 2);
      expect(mapped.valueOrNull, equals(84));

      final output = result.when(
        onSuccess: (val) => 'val: $val',
        onFailure: (err) => 'err: ${err.message}',
      );
      expect(output, equals('val: 42'));
    });

    test('Error returns failure and isFailure is true', () {
      const failure = DatabaseFailure(message: 'Record not found', code: '404');
      const result = Result<int>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final mapped = result.map((data) => data * 2);
      expect(mapped.isFailure, isTrue);

      final output = result.when(
        onSuccess: (val) => 'val: $val',
        onFailure: (err) => 'err: ${err.message}',
      );
      expect(output, equals('err: Record not found'));
    });
  });
}
