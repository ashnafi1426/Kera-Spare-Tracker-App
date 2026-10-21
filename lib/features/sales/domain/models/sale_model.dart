import 'sale_item_model.dart';

/// Domain representation of a recorded sale header with its line items.
class SaleModel {
  final String id;
  final String ownerId;
  final String? receiptNumber;
  final DateTime soldAt;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double totalProfit;
  final String? paymentMethod;
  final String? notes;
  final List<SaleItemModel> items;

  const SaleModel({
    required this.id,
    required this.ownerId,
    this.receiptNumber,
    required this.soldAt,
    required this.subtotal,
    this.discount = 0.0,
    required this.totalAmount,
    required this.totalProfit,
    this.paymentMethod,
    this.notes,
    this.items = const [],
  });

  /// Total count of parts sold across all line items.
  double get totalUnitsCount => items.fold(0.0, (sum, i) => sum + i.quantity);
}
