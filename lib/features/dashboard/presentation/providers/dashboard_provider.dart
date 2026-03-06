import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart'; // 👈 Import
import 'package:mobile/features/dashboard/data/models/supplier_debt_model.dart';
import 'package:mobile/features/dashboard/data/models/transaction_master_model.dart';
import 'package:mobile/features/dashboard/data/models/turnover_detail_model.dart';
import '../../data/dashboard_repository.dart';

// Repository Provider
final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

// 1. Özet Kartları Provider'ı (Hızlı)
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getSummary();
    });

// 2. Grafikler Provider'ı (Biraz daha ağır olabilir)
final dashboardChartsProvider = FutureProvider.autoDispose<DashboardChartModel>(
  (ref) async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.getCharts();
  },
);

// 3. Ciro Detayları Provider'ı (Legacy - Eski Dialog)
final turnoverDialogProvider = FutureProvider.autoDispose
    .family<List<TurnoverDetailModel>, String?>((ref, date) async {
      // 🧹 ARTIK TERTEMİZ: Sadece Repository çağırıyoruz
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getTurnoverDialogDetails(date);
    });

// 4. 🔥 YENİ MASTER PROVIDER (Transaction Explorer)
final transactionMasterProvider = FutureProvider.autoDispose
    .family<List<TransactionMasterModel>, String?>((ref, date) async {
      // 🧹 ARTIK TERTEMİZ: Logic Repository'de
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getTransactionMasterDetails(date);
    });

final supplierSummaryProvider =
    FutureProvider.autoDispose<SupplierDebtSummaryModel>((ref) async {
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getSupplierSummary();
    });

final supplierMasterProvider =
    FutureProvider.autoDispose<List<SupplierDebtMasterModel>>((ref) async {
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getSupplierMaster();
    });
