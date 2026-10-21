/// Domain representation of a persisted sale line item with snapshot pricing.
class SaleItemModel {
  final String id;
  final String saleId;
  final String partId;
  final String partNameSnapshot;
  final double quantity;
  final double unitCost;
  final double unitPrice;
  final double lineTotal;
  final double lineProfit;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.partId,
    required this.partNameSnapshot,
    required this.quantity,
    required this.unitCost,
    required this.unitPrice,
    required this.lineTotal,
    required this.lineProfit,
  });
}
