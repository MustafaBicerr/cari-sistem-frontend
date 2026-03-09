import '../entities/managed_user.dart';

abstract class SettingsRepository {
  Future<List<ManagedUser>> listUsers();

  Future<ManagedUser> createUser({
    required String branchId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  });

  Future<void> deactivateUser(String userId);
}
