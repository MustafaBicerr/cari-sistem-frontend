import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/session.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<(User, AuthTokens)> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    final (userModel, tokensModel) = await _remote.login(
      identifier: identifier,
      password: password,
      deviceName: deviceName,
    );
    await _local.saveTokens(tokensModel);
    return (userModel, tokensModel);
  }

  @override
  Future<(User, AuthTokens)> register({
    required String clinicName,
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final (userModel, tokensModel) = await _remote.register(
      clinicName: clinicName,
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );
    await _local.saveTokens(tokensModel);
    return (userModel, tokensModel);
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final tokensModel = await _remote.refreshToken(refreshToken);
    await _local.saveTokens(tokensModel);
    return tokensModel;
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _remote.logout(refreshToken);
    await _local.clearTokens();
  }

  @override
  Future<List<Session>> getSessions() async {
    final sessions = await _remote.getSessions();
    return sessions.map<Session>((s) => s).toList();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _remote.revokeSession(sessionId);
  }

  @override
  Future<void> forgotPassword(String identifier) async {
    await _remote.forgotPassword(identifier);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _remote.resetPassword(token: token, newPassword: newPassword);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
