import 'package:dio/dio.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import 'models/dashboard_summary_model.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardSummaryModel> getSummary() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dashboardSummary);

      if (response.statusCode == 200) {
        return DashboardSummaryModel.fromJson(response.data);
      } else {
        throw Exception('Dashboard verileri alınamadı.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  // 📈 YENİ: Grafik Verileri
  Future<DashboardChartModel> getCharts() async {
    try {
      // Endpoint: /dashboard/charts
      final response = await _apiClient.dio.get('/dashboard/charts');

      if (response.statusCode == 200) {
        return DashboardChartModel.fromJson(response.data);
      } else {
        throw Exception('Grafik verileri alınamadı.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }
}
