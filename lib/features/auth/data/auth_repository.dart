import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants/api_constants.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // Artık dışarıdan (ApiClient'tan) gelen Dio ve Storage'ı kullanıyor
  AuthRepository({required Dio dio, required FlutterSecureStorage storage})
    : _dio = dio,
      _storage = storage;

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        // Backend'den 'tenant_id' geliyorsa onu da kaydedebiliriz burada
        await _storage.write(key: 'auth_token', value: token);
        return true;
      }
      return false;
    } on DioException catch (e) {
      // Hata yönetimi güzel, aynen kalsın
      print("Login Hatası: ${e.response?.data ?? e.message}");
      throw e.response?.data['message'] ?? 'Bir hata oluştu';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
