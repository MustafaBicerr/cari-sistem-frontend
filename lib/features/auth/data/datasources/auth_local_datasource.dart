import '../../../../core/services/secure_storage_service.dart';
import '../models/auth_tokens_model.dart';

class AuthLocalDatasource {
  final SecureStorageService _storage;

  AuthLocalDatasource(this._storage);

  Future<void> saveTokens(AuthTokensModel tokens) async {
    await _storage.write('access_token', tokens.accessToken);
    await _storage.write('refresh_token', tokens.refreshToken);
  }

  Future<AuthTokensModel?> getTokens() async {
    final access = await _storage.read('access_token');
    final refresh = await _storage.read('refresh_token');
    if (access != null && refresh != null) {
      return AuthTokensModel(accessToken: access, refreshToken: refresh);
    }
    return null;
  }

  Future<void> clearTokens() async {
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
  }
}
