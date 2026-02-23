import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

// 1. GEREKLİ MODELLER VE REPO (Doğru dizinlerden import edildi)
import '../../../dashboard/data/dashboard_repository.dart';
import '../../../dashboard/data/models/transaction_master_model.dart';
// Eğer repo provider'ı dashboard_provider içindeyse orayı,
// değilse sales_controller içinde tanımladığımız repoyu da kullanabilirsin.
// Burada Dashboard altyapısını kullandığımız için DashboardRepo'yu çekiyoruz.
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

// --- STATE (Ekran Durumu) ---
class CashRegisterState {
  final DateTime selectedDate;
  final String filterType; // 'ALL', 'INCOME', 'EXPENSE'
  final bool isLoading;

  // 🔥 ARTIK DOĞRU MODELİ KULLANIYORUZ
  final List<TransactionMasterModel> transactions;

  // Hesaplanan Totaller
  final double dailyCashBalance; // Nakit Kasa
  final double dailyCardBalance; // Pos Kasa
  final double dailyExpense; // Toplam Gider

  CashRegisterState({
    required this.selectedDate,
    this.filterType = 'ALL',
    this.isLoading = false,
    this.transactions = const [],
    this.dailyCashBalance = 0,
    this.dailyCardBalance = 0,
    this.dailyExpense = 0,
  });

  CashRegisterState copyWith({
    DateTime? selectedDate,
    String? filterType,
    bool? isLoading,
    List<TransactionMasterModel>? transactions,
    double? dailyCashBalance,
    double? dailyCardBalance,
    double? dailyExpense,
  }) {
    return CashRegisterState(
      selectedDate: selectedDate ?? this.selectedDate,
      filterType: filterType ?? this.filterType,
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
      debugPrint("🗓️ [PROVIDER] Tarih Sorgulanıyor: $dateStr");

      final rawTransactions = await _repo.getTransactionMasterDetails(dateStr);
      debugPrint("📥 [PROVIDER] ${rawTransactions.length} adet işlem çekildi.");

      // 2. Hesaplamalar
      double totalCash = 0;
      double totalCard = 0;
      double totalExpense = 0;

      for (var item in rawTransactions) {
        // 🔥 DEBUG 4: Döngü içinde her satırı kontrol et
        if (item.collectedCash > 0 || item.collectedCard > 0) {
          debugPrint(
            "   💰 İşlem: ${item.customerName} | Yöntem: ${item.paymentMethod}",
          );
          debugPrint("      -> Eklenecek Nakit: ${item.collectedCash}");
          debugPrint("      -> Eklenecek Kart : ${item.collectedCard}");
        }

        // Backend zaten hesaplayıp gönderdiği için direkt topluyoruz
        totalCash += item.collectedCash;
        totalCard += item.collectedCard;

        // Gelecek için not: Giderler eklendiğinde buraya bakacağız
        // if (item.transactionStatus == 'EXPENSE') totalExpense += item.amount;
      }

      debugPrint("✅ [PROVIDER] SONUÇ -> Nakit: $totalCash, Kart: $totalCard");

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

  // Listeyi Filtreli Döndür (UI bu getter'ı kullanacak)
  List<TransactionMasterModel> get filteredTransactions {
    if (state.filterType == 'ALL') {
      return state.transactions;
    }

    if (state.filterType == 'INCOME') {
      // Şimdilik hepsi gelir kabul edildiği için hepsi dönüyor.
      // İleride: return state.transactions.where((e) => e.amount > 0).toList();
      return state.transactions;
    }

    if (state.filterType == 'EXPENSE') {
      // Backend gider gönderirse burası çalışacak
      // return state.transactions.where((e) => e.amount < 0 || e.type == 'EXPENSE').toList();
      return [];
    }

    return state.transactions;
  }
}

// --- PROVIDER TANIMI ---
final cashRegisterProvider =
    StateNotifierProvider.autoDispose<CashRegisterNotifier, CashRegisterState>((
      ref,
    ) {
      // Dashboard modülündeki Repository'yi yeniden kullanıyoruz (DRY Prensibi)
      final repo = ref.read(dashboardRepositoryProvider);
      return CashRegisterNotifier(repo);
    });
