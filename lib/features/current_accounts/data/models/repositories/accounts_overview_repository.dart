import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/api/api_client.dart';

class CustomerOverviewModel {
  final double totalReceivable;
  final int totalCustomers;
  final int debtorCustomers;
  final double todayTotalCollection;
  final double todayCash;
  final double todayCard;

  CustomerOverviewModel({
    required this.totalReceivable,
    required this.totalCustomers,
    required this.debtorCustomers,
    required this.todayTotalCollection,
    required this.todayCash,
    required this.todayCard,
  });

  factory CustomerOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final today = data['today_collection'] as Map<String, dynamic>? ?? {};
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

    return CustomerOverviewModel(
      totalReceivable: _d(data['total_receivable']),
      totalCustomers: int.tryParse('${data['total_customers']}') ?? 0,
      debtorCustomers: int.tryParse('${data['debtor_customers']}') ?? 0,
      todayTotalCollection: _d(today['total']),
      todayCash: _d(today['cash']),
      todayCard: _d(today['card']),
    );
  }
}

class SupplierOverviewModel {
  final double totalSupplierDebt;
  final int supplierCount;
  final int openInvoiceCount;
  final DateTime? nearestDueDate;

  SupplierOverviewModel({
    required this.totalSupplierDebt,
    required this.supplierCount,
    required this.openInvoiceCount,
    required this.nearestDueDate,
  });

  factory SupplierOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse('$v');
    }

    return SupplierOverviewModel(
      totalSupplierDebt: _d(data['total_supplier_debt']),
      supplierCount: int.tryParse('${data['supplier_count']}') ?? 0,
      openInvoiceCount: int.tryParse('${data['open_invoice_count']}') ?? 0,
      nearestDueDate: _dt(data['nearest_due_date']),
    );
  }
}

class AccountsOverviewRepository {
  final ApiClient _apiClient;

  AccountsOverviewRepository(this._apiClient);

  Future<CustomerOverviewModel> getCustomerOverview() async {
    try {
      final response =
          await _apiClient.dio.get('/accounts/customers/overview');
      return CustomerOverviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('CustomerOverview error: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Müşteri özeti alınamadı.',
      );
    }
  }

  Future<SupplierOverviewModel> getSupplierOverview() async {
    try {
      final response =
          await _apiClient.dio.get('/accounts/suppliers/overview');
      return SupplierOverviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('SupplierOverview error: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Tedarikçi özeti alınamadı.',
      );
    }
  }
}

