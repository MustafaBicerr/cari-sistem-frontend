import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/session_model.dart';
import 'package:dio/dio.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  Future<(UserModel, AuthTokensModel)> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'identifier': identifier,
          'password': password,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = UserModel.fromJson(data['user']);
        final tokens = AuthTokensModel.fromJson(data);
        return (user, tokens);
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<(UserModel, AuthTokensModel)> register({
    required String clinicName,
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'clinic_name': clinicName,
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = UserModel.fromJson(data['user']);
        final tokens = AuthTokensModel.fromJson(data);
        return (user, tokens);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        return AuthTokensModel.fromJson(response.data);
      } else {
        throw Exception('Token refresh failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode != 200) {
        throw Exception('Logout failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<List<SessionModel>> getSessions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.sessions);

      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map((e) => SessionModel.fromJson(e)).toList();
      } else {
        throw Exception('Could not fetch sessions');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.sessions}/$sessionId',
      );

      if (response.statusCode != 200) {
        throw Exception('Could not revoke session');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> forgotPassword(String identifier) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'identifier': identifier},
      );

      if (response.statusCode != 200) {
        throw Exception('Forgot password request failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Reset password failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Change password failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
