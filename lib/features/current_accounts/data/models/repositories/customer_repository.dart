import 'package:flutter/foundation.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/current_accounts/data/models/customer_model.dart';
import 'dart:convert'; // 🔥 Bu importu ekle (JSON çıktısı için)

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  // 1. Tüm Müşterileri Getir
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final response = await _apiClient.dio.get('/customers');

      if (kDebugMode) {
        debugPrint('🟢 [CustomerRepo] getAllCustomers: ${response.statusCode}');
        debugPrint('📦 Data Count: ${(response.data as List).length}');
      }

      return (response.data as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('🔴 [CustomerRepo] Error: $e');
      throw Exception('Müşteriler yüklenemedi: $e');
    }
  }

  // 2. Müşteri Detayı (Full Profil)
  Future<CustomerDetailResponse> getCustomerDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/customers/$id');

      if (kDebugMode) {
        debugPrint('==================================================');
        debugPrint('🟢 [DEBUG] API Yanıtı Geldi (/customers/$id)');
        debugPrint('==================================================');

        // Gelen verinin ham halini (RAW JSON) görelim:
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final String prettyJson = encoder.convert(response.data);
        debugPrint(prettyJson);

        debugPrint('==================================================');

        // Özellikle Fatura Kalemlerine (Items) Odaklanalım:
        final transactions = response.data['transactions'] as List?;
        if (transactions != null && transactions.isNotEmpty) {
          debugPrint('🔍 DETAYLI İNCELEME (İlk Fatura Kalemleri):');
          final firstTx = transactions.first;
          final items = firstTx['items'] as List?;

          if (items != null) {
            for (var item in items) {
              debugPrint('--- Ürün: ${item['product_name']} ---');
              debugPrint(
                '   • unit_price (Birim Fiyat): ${item['unit_price']}',
              );
              debugPrint(
                '   • snapshot_price (Eski Fiyat?): ${item['snapshot_price']}',
              );
              debugPrint(
                '   • current_price (Güncel Fiyat?): ${item['current_price']}',
              );
              debugPrint(
                '   • selling_price (Satış Fiyatı?): ${item['selling_price']}',
              );
              debugPrint(
                '   • inflation (Enflasyon?): ${item['inflation_diff_total']}',
              );
              debugPrint('   • history (Geçmiş?): ${item['price_history']}');
            }
          }
        }
        debugPrint('==================================================');
      }

      return CustomerDetailResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('🔴 [CustomerRepo] Detail Error: $e');
      throw Exception('Müşteri detayı alınamadı');
    }
  }

  // 3. Yeni Müşteri Ekle
  Future<void> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/customers', data: data);
      if (kDebugMode) {
        debugPrint('🟢 [CustomerRepo] createCustomer: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 [CustomerRepo] Create Error: $e');
      rethrow;
    }
  }

  // 4. Müşteri Güncelle
  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put('/customers/$id', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // 5. Müşteri Sil
  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.dio.delete('/customers/$id');
    } catch (e) {
      rethrow;
    }
  }
}
