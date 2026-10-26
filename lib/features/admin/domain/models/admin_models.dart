/// Domain models representing Admin API entities and statistics.
/// These models are ONLINE ONLY and represent system-level management.
library;

class AdminDashboardStats {
  final int totalOwners;
  final int newOwnersThisWeek;
  final int activeOwners;
  final int suspendedOwners;
  final int inactiveOwners;
  final int totalParts;
  final int totalSales;
  final int ownersWithSyncProblems;
  final Map<String, int> appVersionDistribution;

  const AdminDashboardStats({
    required this.totalOwners,
    required this.newOwnersThisWeek,
    required this.activeOwners,
    required this.suspendedOwners,
    required this.inactiveOwners,
    required this.totalParts,
    required this.totalSales,
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
      totalParts: (json['totalParts'] as num?)?.toInt() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toInt() ?? 0,
      ownersWithSyncProblems: (json['ownersWithSyncProblems'] as num?)?.toInt() ?? 0,
      appVersionDistribution: dist,
    );
  }
}

class AdminOwnerSummary {
  final String id;
  final String businessName;
  final String phoneNumber;
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
      status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'].toString())
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
  final List<AdminAuditLogEntry> auditLogs;

  const AdminOwnerDetails({
    required this.owner,
    required this.totalParts,
    required this.totalSales,
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
