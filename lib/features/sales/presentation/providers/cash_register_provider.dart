import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_client.dart';
import '../../../dashboard/data/dashboard_repository.dart';
import '../../../dashboard/data/models/transaction_master_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/repositories/finance_repository.dart';

// --- STATE (Ekran Durumu) ---
class CashRegisterState {
  final DateTime selectedDate;
  final String filterType; // 'ALL', 'INCOME', 'EXPENSE'
  final String customerSearchQuery; // Müşteri arama (autocomplete filtre)
  final bool isLoading;

  final List<TransactionMasterModel> transactions;

  final double dailyCashBalance;
  final double dailyCardBalance;
  final double dailyExpense;

  CashRegisterState({
    required this.selectedDate,
    this.filterType = 'ALL',
    this.customerSearchQuery = '',
    this.isLoading = false,
    this.transactions = const [],
    this.dailyCashBalance = 0,
    this.dailyCardBalance = 0,
    this.dailyExpense = 0,
  });

  CashRegisterState copyWith({
    DateTime? selectedDate,
    String? filterType,
    String? customerSearchQuery,
    bool? isLoading,
    List<TransactionMasterModel>? transactions,
    double? dailyCashBalance,
    double? dailyCardBalance,
    double? dailyExpense,
  }) {
    return CashRegisterState(
      selectedDate: selectedDate ?? this.selectedDate,
      filterType: filterType ?? this.filterType,
      customerSearchQuery: customerSearchQuery ?? this.customerSearchQuery,
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      dailyCashBalance: dailyCashBalance ?? this.dailyCashBalance,
      dailyCardBalance: dailyCardBalance ?? this.dailyCardBalance,
      dailyExpense: dailyExpense ?? this.dailyExpense,
    );
  }
}

// --- NOTIFIER (Mantık) ---
class CashRegisterNotifier extends StateNotifier<CashRegisterState> {
  final DashboardRepository _repo;

  CashRegisterNotifier(this._repo)
    : super(CashRegisterState(selectedDate: DateTime.now())) {
    loadDailyData(); // Başlangıçta veriyi çek
  }

  Future<void> loadDailyData() async {
    state = state.copyWith(isLoading: true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      final rawTransactions = await _repo.getCashRegisterDaily(dateStr);

      double totalCash = 0;
      double totalCard = 0;
      double totalExpense = 0;

      for (var item in rawTransactions) {
        totalCash += item.collectedCash;
        totalCard += item.collectedCard;
        if (item.isExpense) totalExpense += item.finalAmount;
      }

      state = state.copyWith(
        isLoading: false,
        transactions: rawTransactions,
        dailyCashBalance: totalCash,
        dailyCardBalance: totalCard,
        dailyExpense: totalExpense,
      );
    } catch (e) {
      debugPrint("🔴 [PROVIDER] Hata: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void changeDate(DateTime newDate) {
    state = state.copyWith(selectedDate: newDate);
    loadDailyData();
  }

  void setFilter(String filter) {
    state = state.copyWith(filterType: filter);
  }

  void setCustomerSearchQuery(String query) {
    state = state.copyWith(customerSearchQuery: query.trim());
  }

  static String _normalizeForSearch(String text) {
    if (text.isEmpty) return '';
    // Türkçe İ/ı ve diğer karakterler; boşlukları tekileştir
    String s =
        text
            .replaceAll('İ', 'i')
            .replaceAll('ı', 'i')
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return s
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  List<TransactionMasterModel> get filteredTransactions {
    var list = state.transactions;

    if (state.filterType == 'INCOME') {
      list = list.where((e) => e.isIncome).toList();
    } else if (state.filterType == 'EXPENSE') {
      list = list.where((e) => e.isExpense).toList();
    }

    final q = state.customerSearchQuery.trim();
    if (q.isEmpty) return list;

    final normalizedQuery = _normalizeForSearch(q);
    return list.where((e) {
      final name = _normalizeForSearch(e.customerName);
      final normName = _normalizeForSearch(e.customerNormalizedName);
      return name.contains(normalizedQuery) ||
          normName.contains(normalizedQuery);
    }).toList();
  }
}

// --- PROVIDER TANIMLARI ---
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.read(apiClientProvider));
});

final cashRegisterProvider =
    StateNotifierProvider.autoDispose<CashRegisterNotifier, CashRegisterState>((
      ref,
    ) {
      final repo = ref.read(dashboardRepositoryProvider);
      return CashRegisterNotifier(repo);
    });
