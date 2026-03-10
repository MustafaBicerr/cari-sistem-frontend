import 'package:dio/dio.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import 'package:mobile/features/dashboard/data/models/supplier_debt_model.dart';
import 'package:mobile/features/dashboard/data/models/purchase_invoice_detail_model.dart';
import 'package:mobile/features/dashboard/data/models/transaction_master_model.dart';
import 'package:mobile/features/dashboard/data/models/turnover_detail_model.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import 'models/dashboard_summary_model.dart';
import 'package:flutter/material.dart';

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

  // 3. 🆕 Ciro Detayları (Eski Dialog için - Legacy)
  Future<List<TurnoverDetailModel>> getTurnoverDialogDetails(
    String? date,
  ) async {
    try {
      final path =
          date != null
              ? '/dashboard/turnover-dialog-details?date=$date'
              : '/dashboard/turnover-dialog-details';

      final response = await _apiClient.dio.get(path);

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TurnoverDetailModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Detaylar alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  // Kasa ekranı: Satış + Tahsilat + Masraf (tek liste, entry_type ile)
  Future<List<TransactionMasterModel>> getCashRegisterDaily(String? date) async {
    try {
      final path = date != null
          ? '/dashboard/cash-register-daily?date=$date'
          : '/dashboard/cash-register-daily';
      final response = await _apiClient.dio.get(path);
      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map((e) => TransactionMasterModel.fromJson(e)).toList();
      }
      throw Exception('Kasa günlük verisi alınamadı');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  // 4. 🚀 MASTER TRANSACTION EXPLORER (Yeni Master Dialog İçin)
  Future<List<TransactionMasterModel>> getTransactionMasterDetails(
    String? date,
  ) async {
    try {
      final path =
          date != null
              ? '/dashboard/transaction-master?date=$date'
              : '/dashboard/transaction-master';

      // 🔥 DEBUG 1: İstek atılıyor
      debugPrint("📡 [REPO] İstek Atılıyor: $path");

      final response = await _apiClient.dio.get(path);

      if (response.statusCode == 200) {
        final List data = response.data as List;

        // 🔥 DEBUG 2: Backend'den gelen HAM VERİ (İlk elemanı kontrol edelim)
        if (data.isNotEmpty) {
          debugPrint("📦 [REPO] Backend Cevabı (İlk Kayıt Örneği):");
          debugPrint("   -> ID: ${data[0]['id']}");
          debugPrint("   -> Customer: ${data[0]['customer_name']}");
          debugPrint("   -> Method: ${data[0]['payment_method']}");
          debugPrint("   -> Paid Amount: ${data[0]['paid_amount']}");
          debugPrint(
            "   -> Collected CASH: ${data[0]['collected_cash']} (⚠️ Burası null ise Backend göndermiyor)",
          );
          debugPrint(
            "   -> Collected CARD: ${data[0]['collected_card']} (⚠️ Burası null ise Backend göndermiyor)",
          );
        } else {
          debugPrint("⚠️ [REPO] Backend boş liste döndürdü!");
        }

        return data.map((e) => TransactionMasterModel.fromJson(e)).toList();
      } else {
        throw Exception('Master verisi alınamadı');
      }
    } on DioException catch (e) {
      debugPrint("🔴 [REPO] Hata: ${e.message}");
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  // 5. Müşteri Bazlı Tüm İşlemler (İşlem Gezgini - Müşteri Modu)
  Future<List<TransactionMasterModel>> getCustomerTransactions(
    String customerId,
  ) async {
    try {
      final response = await _apiClient.dio
          .get('/dashboard/customer-transactions/$customerId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final List list = data['data'] as List;
          return list.map((e) => TransactionMasterModel.fromJson(e)).toList();
        }
        if (data is List) {
          return data.map((e) => TransactionMasterModel.fromJson(e)).toList();
        }
      }
      throw Exception('Müşteri işlemleri alınamadı');
    } on DioException catch (e) {
      debugPrint("🔴 [REPO] Customer tx error: ${e.message}");
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  Future<SupplierDebtSummaryModel> getSupplierSummary() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/suppliers');

      if (response.statusCode == 200) {
        return SupplierDebtSummaryModel.fromJson(response.data);
      } else {
        throw Exception('Supplier summary alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  Future<List<SupplierDebtMasterModel>> getSupplierMaster() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/suppliers-master');

      if (response.statusCode == 200) {
        final List data = response.data['data'];

        return data.map((e) => SupplierDebtMasterModel.fromJson(e)).toList();
      } else {
        throw Exception('Supplier detayları alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Bağlantı hatası');
    }
  }

  Future<PurchaseInvoiceDetailModel?> getPurchaseInvoiceDetail(String invoiceId) async {
    try {
      final response = await _apiClient.dio.get('/dashboard/purchase-invoice/$invoiceId');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return PurchaseInvoiceDetailModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data['message'] ?? 'Fatura detayı alınamadı.');
    }
  }
}
