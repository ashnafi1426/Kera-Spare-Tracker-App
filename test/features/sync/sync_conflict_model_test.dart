import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/sync/domain/models/sync_conflict_model.dart';

void main() {
  group('SyncConflictModel & ConflictResolutionStrategy', () {
    test('calculates price and stock differences correctly', () {
      final conflict = SyncConflictModel(
        id: 'conf_1',
        partId: 'part_99',
        partName: 'Brake Pads Hilux',
        oemNumber: '04465-0K240',
        shelfLocation: 'Shelf A-4',
        localPrice: 4200.0,
        serverPrice: 4000.0,
        localStock: 12.0,
        serverStock: 15.0,
        localUpdatedBy: 'ይህ ስልክ (This Device)',
        serverUpdatedBy: 'ዋና ሰርቨር (HQ Server)',
        detectedAt: DateTime.now(),
      );

      expect(conflict.priceDiff, equals(200.0));
      expect(conflict.stockDiff, equals(-3.0));
    });

    test('verifies enum values', () {
      expect(ConflictResolutionStrategy.values.length, equals(3));
      expect(
        ConflictResolutionStrategy.values,
        containsAll([
          ConflictResolutionStrategy.smartMerge,
          ConflictResolutionStrategy.clientWins,
          ConflictResolutionStrategy.serverWins,
        ]),
      );
    });
  });
}

