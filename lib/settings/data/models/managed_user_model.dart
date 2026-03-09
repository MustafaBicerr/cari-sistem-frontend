import '../../domain/entities/managed_user.dart';

class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
    required super.role,
    required super.isActive,
    super.createdAt,
  });

  factory ManagedUserModel.fromJson(Map<String, dynamic> json) {
    return ManagedUserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
