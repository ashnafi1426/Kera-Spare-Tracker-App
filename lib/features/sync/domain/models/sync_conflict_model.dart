/// Resolution strategy choice for data discrepancies between local device and remote server.
enum ConflictResolutionStrategy {
  smartMerge,
  clientWins,
  serverWins,
}

/// Represents a data discrepancy between offline local storage and cloud server.
///
/// Follows Google Stitch Screen 2 (Conflict Resolution — የዳታ ግጭት መፍቻ).
class SyncConflictModel {
  final String id;
  final String partId;
  final String partName;
  final String oemNumber;
  final String shelfLocation;
  final double localPrice;
  final double serverPrice;
  final double localStock;
  final double serverStock;
  final String localUpdatedBy;
  final String serverUpdatedBy;
  final DateTime detectedAt;

  const SyncConflictModel({
    required this.id,
    required this.partId,
    required this.partName,
    required this.oemNumber,
    required this.shelfLocation,
    required this.localPrice,
    required this.serverPrice,
    required this.localStock,
    required this.serverStock,
    required this.localUpdatedBy,
    required this.serverUpdatedBy,
    required this.detectedAt,
  });

  double get priceDiff => localPrice - serverPrice;
  double get stockDiff => localStock - serverStock;
}

