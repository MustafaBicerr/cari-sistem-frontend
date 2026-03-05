import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String tenantId,
    required String branchId,
    required String fullName,
    required String phone,
    required String email,
    required String role,
    required bool isActive,
    required bool mustChangePassword,
  }) : super(
          id: id,
          tenantId: tenantId,
          branchId: branchId,
          fullName: fullName,
          phone: phone,
          email: email,
          role: role,
          isActive: isActive,
          mustChangePassword: mustChangePassword,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      mustChangePassword:
          json['must_change_password'] == 1 || json['must_change_password'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
    };
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      tenantId: entity.tenantId,
      branchId: entity.branchId,
      fullName: entity.fullName,
      phone: entity.phone,
      email: entity.email,
      role: entity.role,
      isActive: entity.isActive,
      mustChangePassword: entity.mustChangePassword,
    );
  }
}
