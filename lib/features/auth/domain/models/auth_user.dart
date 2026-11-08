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
  final String? avatarUrl;
  final String? photoLocalPath;

  const AuthUser({
    required this.id,
    required this.ownerId,
    required this.phoneNumber,
    required this.businessName,
    this.role = 'owner',
    this.mustChangePassword = false,
    this.status = 'ACTIVE',
    this.suspendedReason,
    this.avatarUrl,
    this.photoLocalPath,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';

  String get name => businessName;

  String? get photoUrl => photoLocalPath ?? avatarUrl;

  AuthUser copyWith({
    String? id,
    String? ownerId,
    String? phoneNumber,
    String? businessName,
    String? role,
    bool? mustChangePassword,
    String? status,
    String? suspendedReason,
    String? avatarUrl,
    String? photoLocalPath,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoLocalPath: photoLocalPath ?? this.photoLocalPath,
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
        'avatar_url': avatarUrl,
        'photoUrl': avatarUrl,
        'photoLocalPath': photoLocalPath,
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
        avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['photoUrl'] ?? json['photo_url']) as String?,
        photoLocalPath: (json['photo_local_path'] ?? json['photoLocalPath']) as String?,
      );

  @override
  String toString() =>
      'AuthUser(id: $id, ownerId: $ownerId, phone: $phoneNumber, business: $businessName, role: $role, mustChangePassword: $mustChangePassword, status: $status, suspendedReason: $suspendedReason, avatarUrl: $avatarUrl)';

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
        other.suspendedReason == suspendedReason &&
        other.avatarUrl == avatarUrl;
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
        avatarUrl,
      );
}
