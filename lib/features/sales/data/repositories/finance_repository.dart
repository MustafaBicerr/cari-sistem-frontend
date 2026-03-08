import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

/// Kasa & Tahsilat / Masraf API çağrıları (backend /api/finance ve /api/customers).
class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository(this._apiClient);

  /// Günlük masraf kaydı oluşturur.
  /// Body: amount (required), payment_method, category, description, transaction_date (optional).
  Future<Map<String, dynamic>> addExpense({
    required double amount,
    String paymentMethod = 'CASH',
    String category = 'DAILY_EXPENSE',
    String? description,
    String? transactionDate,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/finance/expenses',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'category': category,
        if (description != null && description.isNotEmpty) 'description': description,
        if (transactionDate != null) 'transaction_date': transactionDate,
      },
    );
    return response.data ?? {};
  }

  /// Müşteri borç özeti: Borcu olan satış başlıklarını döner (Tahsilat ekranı).
  Future<List<Map<String, dynamic>>> getCustomerDebtSummary(String customerId) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/finance/customers/$customerId/debt-summary',
    );
    return (response.data ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Tek satış detayı (kalemler + payment_status).
  Future<Map<String, dynamic>?> getTransactionDetail(String transactionId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/finance/transactions/$transactionId',
    );
    return response.data;
  }

  /// Tahsilat kaydı (fiş bazlı): Seçilen fişlerin borcu kapatılır.
  /// transaction_ids: Ödenecek fişlerin id listesi. payment_method CASH_CARD ise cash_amount + card_amount toplamı fiş toplamına eşit olmalı.
  Future<Map<String, dynamic>> submitCollection({
    required String customerId,
    required List<String> transactionIds,
    String paymentMethod = 'CASH',
    double? cashAmount,
    double? cardAmount,
    String? description,
    String? transactionDate,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/finance/collections',
      data: {
        'customer_id': customerId,
        'transaction_ids': transactionIds,
        'payment_method': paymentMethod,
        if (paymentMethod == 'CASH_CARD') ...{
          'cash_amount': cashAmount ?? 0,
          'card_amount': cardAmount ?? 0,
        },
        if (description != null && description.isNotEmpty) 'description': description,
        if (transactionDate != null) 'transaction_date': transactionDate,
      },
    );
    return response.data ?? {};
  }

  /// Müşteri arama (autocomplete). q boşsa tüm müşteriler.
  Future<List<Map<String, dynamic>>> searchCustomers([String? q]) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/customers',
        queryParameters: q != null && q.trim().isNotEmpty ? {'q': q.trim()} : null,
      );
      return (response.data ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (_) {
      return [];
    }
  }
}
