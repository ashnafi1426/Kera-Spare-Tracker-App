enum NotificationType {
  outOfStock,
  lowStock,
  saleCompleted,
  syncFailed,
  syncComplete,
  securityAlert,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String titleAm;
  final String description;
  final String descriptionAm;
  final DateTime timestamp;
  final bool isRead;
  final String? partNumber;
  final String? shelfLocation;
  final int? remainingQuantity;
  final double? amount;
  final String? receiptNumber;
  final int? pendingSyncCount;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAm,
    required this.description,
    required this.descriptionAm,
    required this.timestamp,
    this.isRead = false,
    this.partNumber,
    this.shelfLocation,
    this.remainingQuantity,
    this.amount,
    this.receiptNumber,
    this.pendingSyncCount,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? titleAm,
    String? description,
    String? descriptionAm,
    DateTime? timestamp,
    bool? isRead,
    String? partNumber,
    String? shelfLocation,
    int? remainingQuantity,
    double? amount,
    String? receiptNumber,
    int? pendingSyncCount,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleAm: titleAm ?? this.titleAm,
      description: description ?? this.description,
      descriptionAm: descriptionAm ?? this.descriptionAm,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      partNumber: partNumber ?? this.partNumber,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      amount: amount ?? this.amount,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

