/// Domain models representing Admin API entities and statistics.
/// These models are ONLINE ONLY and represent system-level management.
library;

class AdminDashboardStats {
  final int totalOwners;
  final int newOwnersThisWeek;
  final int activeOwners;
  final int suspendedOwners;
  final int inactiveOwners;
  final int pendingOwners;
  final int totalParts;
  final int totalSales;
  final double totalRevenue;
  final double totalProfit;
  final int ownersWithSyncProblems;
  final Map<String, int> appVersionDistribution;

  const AdminDashboardStats({
    required this.totalOwners,
    required this.newOwnersThisWeek,
    required this.activeOwners,
    required this.suspendedOwners,
    required this.inactiveOwners,
    this.pendingOwners = 0,
    required this.totalParts,
    required this.totalSales,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
    required this.ownersWithSyncProblems,
    required this.appVersionDistribution,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final Map<String, int> dist = {};
    final rawDist = json['appVersionDistribution'];
    if (rawDist is List) {
      for (final item in rawDist) {
        if (item is Map) {
          final ver = item['version']?.toString() ?? 'unknown';
          final count = (item['count'] as num?)?.toInt() ?? 0;
          dist[ver] = count;
        }
      }
    } else if (rawDist is Map) {
      rawDist.forEach((k, v) {
        dist[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return AdminDashboardStats(
      totalOwners: (json['totalOwners'] as num?)?.toInt() ?? 0,
      newOwnersThisWeek: (json['newOwnersThisWeek'] as num?)?.toInt() ?? 0,
      activeOwners: (json['activeOwners'] as num?)?.toInt() ?? 0,
      suspendedOwners: (json['suspendedOwners'] as num?)?.toInt() ?? 0,
      inactiveOwners: (json['inactiveOwners'] as num?)?.toInt() ?? 0,
      pendingOwners: (json['pendingOwners'] as num?)?.toInt() ?? (json['suspendedOwners'] as num?)?.toInt() ?? 0,
      totalParts: (json['totalParts'] as num?)?.toInt() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
      ownersWithSyncProblems: (json['ownersWithSyncProblems'] as num?)?.toInt() ?? 0,
      appVersionDistribution: dist,
    );
  }
}

class AdminOwnerSummary {
  final String id;
  final String businessName;
  final String phoneNumber;
  final String? photoUrl;
  final String? thumbnailUrl;
  final int partsCount;
  final int salesCount;
  final String status;
  final DateTime? lastSyncAt;
  final int failedSyncCount;
  final String? appVersion;
  final String? suspendedReason;
  final DateTime createdAt;

  const AdminOwnerSummary({
    required this.id,
    required this.businessName,
    required this.phoneNumber,
    this.photoUrl,
    this.thumbnailUrl,
    this.partsCount = 0,
    this.salesCount = 0,
    required this.status,
    this.lastSyncAt,
    this.failedSyncCount = 0,
    this.appVersion,
    this.suspendedReason,
    required this.createdAt,
  });

  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';

  factory AdminOwnerSummary.fromJson(Map<String, dynamic> json) {
    return AdminOwnerSummary(
      id: json['id'] as String,
      businessName: json['businessName'] as String? ?? 'Unnamed Business',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      partsCount: (json['partsCount'] as num?)?.toInt() ?? 0,
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
      lastSyncAt: (json['lastSyncAt'] ?? json['last_sync_at'] ?? json['lastSync']) != null
          ? DateTime.tryParse((json['lastSyncAt'] ?? json['last_sync_at'] ?? json['lastSync']).toString())
          : null,
      failedSyncCount: (json['failedSyncCount'] as num?)?.toInt() ?? 0,
      appVersion: json['appVersion'] as String?,
      suspendedReason: json['suspendedReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminOwnerDetails {
  final AdminOwnerSummary owner;
  final int totalParts;
  final int totalSales;
  final double totalRevenue;
  final double totalProfit;
  final List<AdminAuditLogEntry> auditLogs;

  const AdminOwnerDetails({
    required this.owner,
    required this.totalParts,
    required this.totalSales,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
    required this.auditLogs,
  });

  factory AdminOwnerDetails.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final logsJson = json['recentAuditLogs'] as List<dynamic>? ?? [];

    return AdminOwnerDetails(
      owner: AdminOwnerSummary.fromJson(userJson),
      totalParts: (statsJson['partsCount'] as num?)?.toInt() ?? 0,
      totalSales: (statsJson['salesCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (statsJson['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (statsJson['totalProfit'] as num?)?.toDouble() ?? 0.0,
      auditLogs: logsJson
          .map((l) => AdminAuditLogEntry.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GlobalCatalogItem {
  final String id;
  final String name;
  final bool isGlobal;
  final bool isActive;
  final DateTime? createdAt;

  const GlobalCatalogItem({
    required this.id,
    required this.name,
    this.isGlobal = true,
    this.isActive = true,
    this.createdAt,
  });

  factory GlobalCatalogItem.fromJson(Map<String, dynamic> json) {
    return GlobalCatalogItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isGlobal: json['isGlobal'] == true,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class AdminAuditLogEntry {
  final String id;
  final String adminId;
  final String? targetUserId;
  final String action;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? reason;
  final String? ipAddress;
  final DateTime createdAt;
  final String? targetBusinessName;
  final String? targetPhone;
  final String? adminPhone;

  const AdminAuditLogEntry({
    required this.id,
    required this.adminId,
    this.targetUserId,
    required this.action,
    this.oldValue,
    this.newValue,
    this.reason,
    this.ipAddress,
    required this.createdAt,
    this.targetBusinessName,
    this.targetPhone,
    this.adminPhone,
  });

  factory AdminAuditLogEntry.fromJson(Map<String, dynamic> json) {
    final targetUser = json['targetUser'] as Map<String, dynamic>?;
    final adminUser = json['admin'] as Map<String, dynamic>?;

    return AdminAuditLogEntry(
      id: json['id'] as String,
      adminId: json['adminId'] as String? ?? '',
      targetUserId: json['targetUserId'] as String?,
      action: json['action'] as String? ?? 'ACTION',
      oldValue: json['oldValue'] is Map<String, dynamic>
          ? json['oldValue'] as Map<String, dynamic>
          : null,
      newValue: json['newValue'] is Map<String, dynamic>
          ? json['newValue'] as Map<String, dynamic>
          : null,
      reason: json['reason'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetBusinessName: targetUser?['businessName'] as String?,
      targetPhone: targetUser?['phoneNumber'] as String?,
      adminPhone: adminUser?['phoneNumber'] as String?,
    );
  }
}

class AdminMinAppVersion {
  final String version;
  final bool enforce;

  const AdminMinAppVersion({
    required this.version,
    required this.enforce,
  });

  factory AdminMinAppVersion.fromJson(Map<String, dynamic> json) {
    return AdminMinAppVersion(
      version: json['version'] as String? ?? '1.0.0',
      enforce: json['enforce'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'enforce': enforce,
  };
}

class AdminAnnouncement {
  final bool active;
  final String titleAm;
  final String titleEn;
  final String bodyAm;
  final String bodyEn;
  final String? startTime;
  final String? endTime;

  const AdminAnnouncement({
    required this.active,
    this.titleAm = '',
    this.titleEn = '',
    this.bodyAm = '',
    this.bodyEn = '',
    this.startTime,
    this.endTime,
  });

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) {
    return AdminAnnouncement(
      active: json['active'] == true,
      titleAm: json['titleAm'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      bodyAm: json['bodyAm'] as String? ?? '',
      bodyEn: json['bodyEn'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'active': active,
    'titleAm': titleAm,
    'titleEn': titleEn,
    'bodyAm': bodyAm,
    'bodyEn': bodyEn,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class AdminMaintenanceMode {
  final bool enabled;
  final String messageAm;
  final String messageEn;

  const AdminMaintenanceMode({
    required this.enabled,
    this.messageAm = '',
    this.messageEn = '',
  });

  factory AdminMaintenanceMode.fromJson(Map<String, dynamic> json) {
    return AdminMaintenanceMode(
      enabled: json['enabled'] == true,
      messageAm: json['messageAm'] as String? ?? '',
      messageEn: json['messageEn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'messageAm': messageAm,
    'messageEn': messageEn,
  };
}

class AdminReportPoint {
  final String label;
  final double revenue;
  final double profit;

  const AdminReportPoint({
    required this.label,
    required this.revenue,
    required this.profit,
  });

  factory AdminReportPoint.fromJson(Map<String, dynamic> json) {
    return AdminReportPoint(
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminTopSellingItem {
  final String partId;
  final String name;
  final int units;
  final double totalAmount;

  const AdminTopSellingItem({
    required this.partId,
    required this.name,
    required this.units,
    required this.totalAmount,
  });

  factory AdminTopSellingItem.fromJson(Map<String, dynamic> json) {
    return AdminTopSellingItem(
      partId: json['partId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Spare Part',
      units: (json['units'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminReportSummary {
  final String period;
  final double totalRevenue;
  final double totalProfit;
  final int transactionsCount;
  final int activeOwnersCount;
  final int totalPartsCount;
  final List<AdminReportPoint> points;
  final List<AdminTopSellingItem> topSellingItems;

  const AdminReportSummary({
    required this.period,
    required this.totalRevenue,
    required this.totalProfit,
    required this.transactionsCount,
    required this.activeOwnersCount,
    required this.totalPartsCount,
    required this.points,
    required this.topSellingItems,
  });

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    return AdminReportSummary(
      period: json['period']?.toString() ?? 'month',
      totalRevenue: ((json['totalRevenue'] ?? json['revenue'] ?? json['sales']) as num?)?.toDouble() ?? 0.0,
      totalProfit: ((json['totalProfit'] ?? json['profit'] ?? json['estProfit']) as num?)?.toDouble() ?? 0.0,
      transactionsCount: ((json['transactionsCount'] ?? json['totalTransactions'] ?? json['transactions']) as num?)?.toInt() ?? 0,
      activeOwnersCount: ((json['activeOwnersCount'] ?? json['activeOwners'] ?? json['ownersCount']) as num?)?.toInt() ?? 0,
      totalPartsCount: ((json['totalPartsCount'] ?? json['partsCount'] ?? json['totalParts']) as num?)?.toInt() ?? 0,
      points: (json['points'] as List?)
              ?.map((p) => AdminReportPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      topSellingItems: (json['topSellingItems'] as List?)
              ?.map((t) => AdminTopSellingItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
