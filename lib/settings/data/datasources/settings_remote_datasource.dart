import 'package:dio/dio.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/constants/api_constants.dart';
import '../models/managed_user_model.dart';

class SettingsRemoteDatasource {
  final ApiClient _apiClient;

  SettingsRemoteDatasource(this._apiClient);

  Future<List<ManagedUserModel>> listUsers() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.users);
      if (response.statusCode != 200) {
        throw Exception('Kullanicilar alinamadi');
      }
      final data = response.data as List<dynamic>;
      return data
          .map(
            (e) =>
                ManagedUserModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ag hatasi');
    }
  }

  Future<ManagedUserModel> createUser({
    required String branchId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.users,
        data: {
          'branch_id': branchId,
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      if (response.statusCode != 201) {
        throw Exception('Kullanici olusturulamadi');
      }
      return ManagedUserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ag hatasi');
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiConstants.users}/$userId/deactivate',
      );
      if (response.statusCode != 200) {
        throw Exception('Kullanici dondurulamadi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ag hatasi');
    }
  }
}
