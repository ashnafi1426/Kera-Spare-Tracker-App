import '../../../../core/utils/result.dart';
import '../models/location_item.dart';

/// Abstract contract for storage locations and shelves.
abstract class LocationsRepository {
  /// Continuously watches storage locations (both default shelves and owner custom locations).
  Stream<List<LocationItem>> watchLocations(String ownerId);

  /// Retrieves one-shot snapshot of active storage locations.
  Future<Result<List<LocationItem>>> getLocations(String ownerId);

  /// Creates a new custom storage location and enqueues sync mutation.
  Future<Result<LocationItem>> createLocation({
    required String ownerId,
    required String name,
  });

  /// Updates an existing custom location and enqueues sync mutation.
  Future<Result<LocationItem>> updateLocation({
    required String ownerId,
    required String id,
    required String name,
  });

  /// Soft deletes an owner's custom location and enqueues sync delete mutation.
  Future<Result<void>> deactivateLocation({
    required String ownerId,
    required String id,
  });
}
