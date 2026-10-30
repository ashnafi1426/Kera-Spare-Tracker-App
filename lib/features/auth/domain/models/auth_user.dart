/// Domain model representing an authenticated user in Kera Spare Tracker.
class AuthUser {
  final String id;
  final String ownerId;
  final String phoneNumber;
  final String businessName;
  final String role;
  final bool mustChangePassword;
  final String status;
  final String? suspendedReason;

  const AuthUser({
    required this.id,
    required this.ownerId,
    required this.phoneNumber,
    required this.businessName,
    this.role = 'owner',
    this.mustChangePassword = false,
    this.status = 'ACTIVE',
    this.suspendedReason,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';

  AuthUser copyWith({
    String? id,
    String? ownerId,
    String? phoneNumber,
    String? businessName,
    String? role,
    bool? mustChangePassword,
    String? status,
    String? suspendedReason,
  }) {
    return AuthUser(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      status: status ?? this.status,
      suspendedReason: suspendedReason ?? this.suspendedReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'phone_number': phoneNumber,
        'business_name': businessName,
        'role': role,
        'must_change_password': mustChangePassword,
        'status': status,
        'suspended_reason': suspendedReason,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] ?? json['owner_id'] ?? '') as String,
        ownerId: (json['owner_id'] ?? json['id'] ?? '') as String,
        phoneNumber: (json['phone_number'] ?? json['phoneNumber'] ?? '') as String,
        businessName: (json['business_name'] ?? json['businessName'] ?? '') as String,
        role: (json['role'] as String? ?? 'owner').toLowerCase(),
        mustChangePassword: json['must_change_password'] == true || json['mustChangePassword'] == true,
        status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
        suspendedReason: (json['suspended_reason'] ?? json['suspendedReason']) as String?,
      );

  @override
  String toString() =>
      'AuthUser(id: $id, ownerId: $ownerId, phone: $phoneNumber, business: $businessName, role: $role, mustChangePassword: $mustChangePassword, status: $status, suspendedReason: $suspendedReason)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.phoneNumber == phoneNumber &&
        other.businessName == businessName &&
        other.role == role &&
        other.mustChangePassword == mustChangePassword &&
        other.status == status &&
        other.suspendedReason == suspendedReason;
  }

  @override
  int get hashCode => Object.hash(
        id,
        ownerId,
        phoneNumber,
        businessName,
        role,
        mustChangePassword,
        status,
        suspendedReason,
      );
}
