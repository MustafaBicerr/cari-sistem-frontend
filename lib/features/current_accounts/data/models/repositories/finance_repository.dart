import 'package:flutter/foundation.dart';
import 'package:mobile/core/api/api_client.dart';

class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository(this._apiClient);

  // 1. Müşteriden Tahsilat Al (Collection)
  Future<void> collectDebt({
    required String customerId,
    required double amount,
    required String paymentMethod, // 'CASH', 'CREDIT_CARD', 'IBAN'
    String? description,
    DateTime? date,
  }) async {
    try {
      await _apiClient.dio.post(
        '/finance/collections',
        data: {
          'customer_id': customerId,
          'amount': amount,
          'payment_method': paymentMethod,
          'description': description,
          'transaction_date': date?.toIso8601String(),
        },
      );

      if (kDebugMode) debugPrint('🟢 [FinanceRepo] Tahsilat Başarılı');
    } catch (e) {
      debugPrint('🔴 [FinanceRepo] Collection Error: $e');
      rethrow;
    }
  }

  // 2. Tedarikçiye Ödeme Yap (Payment)
  Future<void> paySupplier({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? description,
    DateTime? date,
  }) async {
    try {
      await _apiClient.dio.post(
        '/finance/payments',
        data: {
          'supplier_id': supplierId,
          'amount': amount,
          'payment_method': paymentMethod,
          'description': description,
          'transaction_date': date?.toIso8601String(),
        },
      );

      if (kDebugMode) debugPrint('🟢 [FinanceRepo] Ödeme Başarılı');
    } catch (e) {
      debugPrint('🔴 [FinanceRepo] Payment Error: $e');
      rethrow;
    }
  }

  // 3. Tedarikçiye Ödeme Yap (Fatura Bazlı - Seçili Satın Alma Faturalarını Tamamen Kapat)
  Future<void> paySupplierInvoices({
    required String supplierId,
    required List<String> invoiceIds,
    String paymentMethod = 'CASH',
    String? description,
    DateTime? date,
  }) async {
    try {
      await _apiClient.dio.post(
        '/finance/supplier-invoice-payments',
        data: {
          'supplier_id': supplierId,
          'invoice_ids': invoiceIds,
          'payment_method': paymentMethod,
          if (description != null) 'description': description,
          if (date != null) 'transaction_date': date.toIso8601String(),
        },
      );

      if (kDebugMode) {
        debugPrint('🟢 [FinanceRepo] Fatura Bazlı Ödeme Başarılı');
      }
    } catch (e) {
      debugPrint('🔴 [FinanceRepo] Invoice Payment Error: $e');
      rethrow;
    }
  }
}
