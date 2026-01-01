import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';

// Repository'nin kendisi
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

// UI'ın dinleyeceği asıl veri kaynağı
// Bu provider otomatik olarak Loading, Error ve Data durumlarını yönetir.
final dashboardSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.read(dashboardRepositoryProvider);
      return repo.getDashboardSummary();
    });
