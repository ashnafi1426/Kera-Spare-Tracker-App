import '../../../../data/local/tables/enums.dart';

/// Domain representation of a stock movement ledger entry.
class StockMovementItem {
  final String id;
  final String ownerId;
  final String partId;
  final MovementType type;
  final double quantityChange;
  final double? unitCost;
  final String? referenceId;
  final String? note;
  final DateTime movedAt;
  final DateTime createdAt;
  final double? runningBalance;

  const StockMovementItem({
    required this.id,
    required this.ownerId,
    required this.partId,
    required this.type,
    required this.quantityChange,
    this.unitCost,
    this.referenceId,
    this.note,
    required this.movedAt,
    required this.createdAt,
    this.runningBalance,
  });

  StockMovementItem copyWith({
    String? id,
    String? ownerId,
    String? partId,
    MovementType? type,
    double? quantityChange,
    double? unitCost,
    String? referenceId,
    String? note,
    DateTime? movedAt,
    DateTime? createdAt,
    double? runningBalance,
  }) {
    return StockMovementItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      partId: partId ?? this.partId,
      type: type ?? this.type,
      quantityChange: quantityChange ?? this.quantityChange,
      unitCost: unitCost ?? this.unitCost,
      referenceId: referenceId ?? this.referenceId,
      note: note ?? this.note,
      movedAt: movedAt ?? this.movedAt,
      createdAt: createdAt ?? this.createdAt,
      runningBalance: runningBalance ?? this.runningBalance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
