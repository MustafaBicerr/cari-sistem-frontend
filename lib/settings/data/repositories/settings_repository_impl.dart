import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDatasource _remote;

  SettingsRepositoryImpl(this._remote);

  @override
  Future<List<ManagedUser>> listUsers() async {
    final users = await _remote.listUsers();
    return users.map<ManagedUser>((user) => user).toList();
  }

  @override
  Future<ManagedUser> createUser({
    required String branchId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    return _remote.createUser(
      branchId: branchId,
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<void> deactivateUser(String userId) {
    return _remote.deactivateUser(userId);
  }
}
