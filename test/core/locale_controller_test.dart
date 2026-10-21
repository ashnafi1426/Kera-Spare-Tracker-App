import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockStorage = MockLocalStorageService();
    when(() => mockStorage.saveLocaleCode(any()))
        .thenAnswer((_) async {});
    when(() => mockStorage.getSavedLocaleCode())
        .thenAnswer((_) async => null);
  });

  ProviderContainer createContainer({String? initialCode}) {
    return ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorage),
        if (initialCode != null)
          initialLocaleCodeProvider.overrideWithValue(initialCode),
      ],
    );
  }

  group('LocaleController', () {
    test('defaults to Amharic (am) when no initial code is stored', () {
      final container = createContainer();
      final locale = container.read(localeControllerProvider);

      expect(locale.languageCode, equals('am'));
    });

    test('initializes with stored locale if provided', () {
      final container = createContainer(initialCode: 'en');
      final locale = container.read(localeControllerProvider);

      expect(locale.languageCode, equals('en'));
    });

    test('switching to English updates state live and persists to storage', () async {
      final container = createContainer();
      final controller = container.read(localeControllerProvider.notifier);

      expect(container.read(localeControllerProvider).languageCode, equals('am'));

      await controller.setLocale(const Locale('en'));

      expect(container.read(localeControllerProvider).languageCode, equals('en'));
      verify(() => mockStorage.saveLocaleCode('en')).called(1);
    });

    test('toggleLocale switches back and forth between Amharic and English', () async {
      final container = createContainer();
      final controller = container.read(localeControllerProvider.notifier);

      expect(container.read(localeControllerProvider).languageCode, equals('am'));

      // Toggle to English
      await controller.toggleLocale();
      expect(container.read(localeControllerProvider).languageCode, equals('en'));
      verify(() => mockStorage.saveLocaleCode('en')).called(1);

      // Toggle back to Amharic
      await controller.toggleLocale();
      expect(container.read(localeControllerProvider).languageCode, equals('am'));
      verify(() => mockStorage.saveLocaleCode('am')).called(1);
    });
  });
}
