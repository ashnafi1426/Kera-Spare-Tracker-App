/// Domain model representing an authenticated user in Kera Spare Tracker.
class AuthUser {
  final String id;
  final String ownerId;
  final String phoneNumber;
  final String businessName;
  final String role;

  const AuthUser({
    required this.id,
    required this.ownerId,
    required this.phoneNumber,
    required this.businessName,
    this.role = 'owner',
  });

  bool get isAdmin => role == 'admin';

  AuthUser copyWith({
    String? id,
    String? ownerId,
    String? phoneNumber,
    String? businessName,
    String? role,
  }) {
    return AuthUser(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'phone_number': phoneNumber,
        'business_name': businessName,
        'role': role,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        phoneNumber: json['phone_number'] as String,
        businessName: json['business_name'] as String,
        role: json['role'] as String? ?? 'owner',
      );

  @override
  String toString() =>
      'AuthUser(id: $id, ownerId: $ownerId, phone: $phoneNumber, business: $businessName, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.phoneNumber == phoneNumber &&
        other.businessName == businessName &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, ownerId, phoneNumber, businessName, role);
}
