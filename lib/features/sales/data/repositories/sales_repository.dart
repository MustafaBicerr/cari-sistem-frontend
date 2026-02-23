import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';

class SalesRepository {
  final ApiClient _apiClient;

  SalesRepository(this._apiClient);

  Future<void> createSale(Map<String, dynamic> saleData) async {
    try {
      if (kDebugMode) {
        debugPrint("🚀 [REPO] Backend'e Giden Veri: $saleData");
      }

      final response = await _apiClient.dio.post('/sales', data: saleData);

      // Başarılı durum kontrolü (200 veya 201)
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Beklenmedik Durum Kodu: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🔴 [REPO] Satış Hatası: $e");
      rethrow; // Hatayı Controller'a fırlat
    }
  }
}
