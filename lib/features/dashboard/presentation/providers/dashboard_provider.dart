import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart'; // 👈 Import
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

// 3. Ciro Detayları Provider'ı (SADECE DIALOG İÇİN)
// Bu provider dashboard açılınca çalışmaz, sadece dialog açılınca çalışır.
final turnoverDialogProvider = FutureProvider.autoDispose.family<
  List<TurnoverDetailModel>,
  String?
>((ref, date) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    // 🔥 YENİ VE AYRI ENDPOINT'E GİDİYORUZ
    final path =
        date != null
            ? '/dashboard/turnover-dialog-details?date=$date'
            : '/dashboard/turnover-dialog-details';

    final response = await apiClient.dio.get(path);

    if (response.statusCode == 200) {
      // // 🔥🔥🔥 DEBUG 1: GELEN HAM JSON 🔥🔥🔥
      // debugPrint("\n🔵 FLUTTER - HAM JSON VERİSİ GELDİ:");
      // // Tüm veriyi basmak konsolu kilitler, o yüzden sadece ilk elemanın items kısmını basalım
      // if ((response.data as List).isNotEmpty) {
      //   final firstItem = (response.data as List)[0];
      //   debugPrint("Örnek İlk Fiş Items: ${firstItem['items']}");
      // }

      return (response.data as List)
          .map((e) => TurnoverDetailModel.fromJson(e))
          .toList();
    } else {
      throw Exception('Detaylar alınamadı');
    }
  } catch (e) {
    debugPrint("HATA: $e"); // Hatayı da görelim
    throw Exception('Bağlantı hatası: $e');
  }
});

// 🔥 YENİ MASTER PROVIDER (Transaction Explorer)
// date parametresi ile çalışır, verilmezse tümünü veya bugünü çeker (Backend mantığına göre)
final transactionMasterProvider = FutureProvider.autoDispose
    .family<List<TransactionMasterModel>, String?>((ref, date) async {
      final apiClient = ref.read(apiClientProvider);

      try {
        // Yeni Endpoint
        final path =
            date != null
                ? '/dashboard/transaction-master?date=$date'
                : '/dashboard/transaction-master';

        final response = await apiClient.dio.get(path);

        if (response.statusCode == 200) {
          return (response.data as List)
              .map((e) => TransactionMasterModel.fromJson(e))
              .toList();
        } else {
          throw Exception('Master verisi alınamadı');
        }
      } catch (e) {
        throw Exception('Bağlantı hatası: $e');
      }
    });
