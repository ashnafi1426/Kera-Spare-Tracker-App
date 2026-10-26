import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';

void main() {
  group('AdminDashboardStats Parsing Tests', () {
    test('Correctly parses appVersionDistribution when returned as a List of objects', () {
      final backendJson = {
        'totalOwners': 184,
        'newOwnersThisWeek': 184,
        'activeOwners': 10,
        'suspendedOwners': 57,
        'inactiveOwners': 174,
        'ownersWithSyncProblems': 174,
        'totalParts': 1,
        'totalSales': 0,
        'appVersionDistribution': [
          {'version': 'unknown', 'count': 173},
          {'version': '2.4.1', 'count': 10},
          {'version': '1.0.0', 'count': 1},
        ],
      };

      final stats = AdminDashboardStats.fromJson(backendJson);

      expect(stats.totalOwners, 184);
      expect(stats.activeOwners, 10);
      expect(stats.suspendedOwners, 57);
      expect(stats.appVersionDistribution['unknown'], 173);
      expect(stats.appVersionDistribution['2.4.1'], 10);
      expect(stats.appVersionDistribution['1.0.0'], 1);
    });

    test('Correctly parses appVersionDistribution when returned as a Map', () {
      final mapJson = {
        'totalOwners': 20,
        'newOwnersThisWeek': 5,
        'activeOwners': 15,
        'suspendedOwners': 2,
        'inactiveOwners': 3,
        'totalParts': 50,
        'totalSales': 12,
        'ownersWithSyncProblems': 1,
        'appVersionDistribution': {
          '1.0.0': 15,
          '1.1.0': 5,
        },
      };

      final stats = AdminDashboardStats.fromJson(mapJson);

      expect(stats.totalOwners, 20);
      expect(stats.appVersionDistribution['1.0.0'], 15);
      expect(stats.appVersionDistribution['1.1.0'], 5);
    });

    test('Handles null or empty appVersionDistribution gracefully', () {
      final emptyJson = {
        'totalOwners': 0,
        'newOwnersThisWeek': 0,
        'activeOwners': 0,
        'suspendedOwners': 0,
        'inactiveOwners': 0,
        'totalParts': 0,
        'totalSales': 0,
        'ownersWithSyncProblems': 0,
        'appVersionDistribution': null,
      };

      final stats = AdminDashboardStats.fromJson(emptyJson);

      expect(stats.totalOwners, 0);
      expect(stats.appVersionDistribution, isEmpty);
    });
  });
}
