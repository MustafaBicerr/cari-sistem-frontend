import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart'; // 👈 Import
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
