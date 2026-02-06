import 'package:flutter/foundation.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/current_accounts/data/models/supplier_model.dart';
import 'package:mobile/features/current_accounts/data/models/warehouse_model.dart';

class SupplierRepository {
  final ApiClient _apiClient;

  SupplierRepository(this._apiClient);

  // 1. Tüm Tedarikçileri Getir
  Future<List<SupplierModel>> getAllSuppliers() async {
    try {
      final response = await _apiClient.dio.get('/suppliers');

      if (kDebugMode) {
        debugPrint('🟢 [SupplierRepo] getAllSuppliers: ${response.statusCode}');
      }

      return (response.data as List)
          .map((e) => SupplierModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('🔴 [SupplierRepo] Error: $e');
      throw Exception('Tedarikçiler yüklenemedi: $e');
    }
  }

  // 2. Tedarikçi Detayı
  Future<SupplierDetailResponse> getSupplierDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/suppliers/$id');

      if (kDebugMode) {
        debugPrint('🟢 [SupplierRepo] getSupplierDetail($id):Success');
      }

      return SupplierDetailResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('🔴 [SupplierRepo] Detail Error: $e');
      throw Exception('Tedarikçi detayı alınamadı');
    }
  }

  // 3. Yeni Tedarikçi Ekle
  Future<void> createSupplier(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/suppliers', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // 4. Güncelle
  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put('/suppliers/$id', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // 5. Sil
  Future<void> deleteSupplier(String id) async {
    try {
      await _apiClient.dio.delete('/suppliers/$id');
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 6. AUTOCOMPLETE ARAMASI (Resmi Depolar)
  Future<List<WarehouseModel>> searchOfficialWarehouses(String query) async {
    try {
      if (query.length < 2) return [];

      final response = await _apiClient.dio.get(
        '/suppliers/search-official',
        queryParameters: {'q': query},
      );

      if (kDebugMode) {
        debugPrint(
          '🔍 [SupplierRepo] Search "$query": ${(response.data as List).length} sonuç',
        );
      }

      return (response.data as List)
          .map((e) => WarehouseModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('🔴 [SupplierRepo] Search Error: $e');
      return []; // Hata durumunda boş liste dön, uygulamayı kırma
    }
  }
}
