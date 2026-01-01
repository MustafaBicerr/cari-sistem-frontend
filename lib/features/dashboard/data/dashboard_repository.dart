import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart'; // Sabitleri çağır

class DashboardRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await _dio.get(
        ApiConstants.dashboardSummary, // Endpoint buradan geliyor
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data;
    } catch (e) {
      throw Exception("Dashboard verisi çekilemedi: $e");
    }
  }
}
