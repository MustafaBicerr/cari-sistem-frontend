import 'package:equatable/equatable.dart';

class ManagedUser extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    phone,
    email,
    role,
    isActive,
    createdAt,
  ];
}
