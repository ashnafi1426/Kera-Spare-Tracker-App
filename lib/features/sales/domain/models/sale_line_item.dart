import '../../../parts/domain/models/part_item.dart';

/// In-memory representation of a sale line item before persisting.
class SaleLineItem {
  final PartItem part;
  final double quantity;
  final double unitPrice;
  final double unitCost;

  const SaleLineItem({
    required this.part,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  /// Factory creating an initial line item from a selected [PartItem].
  factory SaleLineItem.fromPart(PartItem part, {double quantity = 1.0}) {
    return SaleLineItem(
      part: part,
      quantity: quantity,
      unitPrice: part.sellingPrice ?? 0.0,
      unitCost: part.purchasePrice ?? 0.0,
    );
  }

  /// Whether this part has no purchase price recorded, meaning profit may be overstated.
  bool get hasNoCostWarning => part.purchasePrice == null;

  /// Line total revenue.
  double get lineTotal => quantity * unitPrice;

  /// Line total cost.
  double get lineCost => quantity * unitCost;

  /// Line total profit.
  double get lineProfit => lineTotal - lineCost;

  SaleLineItem copyWith({
    PartItem? part,
    double? quantity,
    double? unitPrice,
    double? unitCost,
  }) {
    return SaleLineItem(
      part: part ?? this.part,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}
