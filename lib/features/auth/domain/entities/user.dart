import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String tenantId;
  final String branchId;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final bool mustChangePassword;

  const User({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
  });

  @override
  List<Object?> get props => [
        id,
        tenantId,
        branchId,
        fullName,
        phone,
        email,
        role,
        isActive,
        mustChangePassword,
      ];
}
