import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants/api_constants.dart';

class AuthRepository {
  // BaseUrl artık sabit dosyasından geliyor
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
    ),
  );

  final _storage = const FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    try {
      // Endpoint artık sabit dosyasından geliyor
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Login Hatası: ${e.response?.data ?? e.message}");
      throw e.response?.data['message'] ?? 'Bir hata oluştu';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
