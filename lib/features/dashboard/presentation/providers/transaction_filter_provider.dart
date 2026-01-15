import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/transaction_master_model.dart';
import 'dashboard_provider.dart';

// --- FİLTRE DURUMU (GELİŞMİŞ) ---
class TransactionFilterState {
  final String searchQuery;
  final String sortOption;
  final Set<String> selectedPaymentStatuses; // PAID, UNPAID, PARTIAL
  final Set<String> selectedPaymentMethods; // CASH, CREDIT_CARD

  // 🔥 YENİ EKLENEN GELİŞMİŞ FİLTRELER
  final Set<String> selectedTimeRanges; // "08-10", "10-12" vb.
  final String amountFilterType; // 'TOTAL', 'PAID', 'DEBT'
  final double? minAmount;
  final double? maxAmount;
  final bool onlyInflation; // Sadece zam farkı olanlar
  final bool onlyWithNote; // Sadece notu olanlar

  TransactionFilterState({
    this.searchQuery = '',
    this.sortOption = 'date_desc',
    this.selectedPaymentStatuses = const {},
    this.selectedPaymentMethods = const {},
    this.selectedTimeRanges = const {},
    this.amountFilterType = 'TOTAL',
    this.minAmount,
    this.maxAmount,
    this.onlyInflation = false,
    this.onlyWithNote = false,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    String? sortOption,
    Set<String>? selectedPaymentStatuses,
    Set<String>? selectedPaymentMethods,
    Set<String>? selectedTimeRanges,
    String? amountFilterType,
    double? minAmount,
    double? maxAmount,
    bool? onlyInflation,
    bool? onlyWithNote,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      selectedPaymentStatuses:
          selectedPaymentStatuses ?? this.selectedPaymentStatuses,
      selectedPaymentMethods:
          selectedPaymentMethods ?? this.selectedPaymentMethods,
      selectedTimeRanges: selectedTimeRanges ?? this.selectedTimeRanges,
      amountFilterType: amountFilterType ?? this.amountFilterType,
      minAmount: minAmount ?? this.minAmount, // Null geçilebilmeli
      maxAmount: maxAmount ?? this.maxAmount,
      onlyInflation: onlyInflation ?? this.onlyInflation,
      onlyWithNote: onlyWithNote ?? this.onlyWithNote,
    );
  }
}

// --- CONTROLLER (MANTIK) ---
class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(TransactionFilterState());

  // Basit Setters
  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
  void setSortOption(String option) =>
      state = state.copyWith(sortOption: option);
  void setAmountFilterType(String type) =>
      state = state.copyWith(amountFilterType: type);
  void setMinAmount(String val) =>
      state = state.copyWith(minAmount: double.tryParse(val));
  void setMaxAmount(String val) =>
      state = state.copyWith(maxAmount: double.tryParse(val));
  void toggleInflation(bool val) => state = state.copyWith(onlyInflation: val);
  void toggleWithNote(bool val) => state = state.copyWith(onlyWithNote: val);

  // Toggle Metodları (Set yönetimi)
  void toggleStatus(String val) => _toggleSetItem(
    val,
    (s) => state.selectedPaymentStatuses,
    (n) => state = state.copyWith(selectedPaymentStatuses: n),
  );
  void toggleMethod(String val) => _toggleSetItem(
    val,
    (s) => state.selectedPaymentMethods,
    (n) => state = state.copyWith(selectedPaymentMethods: n),
  );
  void toggleTimeRange(String val) => _toggleSetItem(
    val,
    (s) => state.selectedTimeRanges,
    (n) => state = state.copyWith(selectedTimeRanges: n),
  );

  void _toggleSetItem(
    String item,
    Set<String> Function(TransactionFilterState) getSet,
    Function(Set<String>) updateState,
  ) {
    final current = Set<String>.from(getSet(state));
    if (current.contains(item))
      current.remove(item);
    else
      current.add(item);
    updateState(current);
  }

  void clearFilters() {
    state = TransactionFilterState(); // Fabrika ayarlarına dön
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>((
      ref,
    ) {
      return TransactionFilterNotifier();
    });

// --- 🔥 FİLTRELEME MOTORU ---
final filteredTransactionsProvider = Provider.autoDispose<
  List<TransactionMasterModel>
>((ref) {
  final allTransactionsAsync = ref.watch(transactionMasterProvider(null));
  final filterState = ref.watch(transactionFilterProvider);

  return allTransactionsAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (allTransactions) {
      // 1. FİLTRELEME ADIMI
      var filtered =
          allTransactions.where((t) {
            // A) Search Bar
            if (filterState.searchQuery.isNotEmpty) {
              final q = filterState.searchQuery.toLowerCase();
              final matchesCustomer = t.customerName.toLowerCase().contains(q);
              final matchesCashier = t.cashierName.toLowerCase().contains(q);
              final matchesProduct = t.items.any(
                (i) => i.productName.toLowerCase().contains(q),
              );
              if (!matchesCustomer && !matchesCashier && !matchesProduct)
                return false;
            }

            // B) Basit Filtreler (Statü & Yöntem)
            if (filterState.selectedPaymentStatuses.isNotEmpty &&
                !filterState.selectedPaymentStatuses.contains(
                  t.transactionStatus,
                ))
              return false;
            if (filterState.selectedPaymentMethods.isNotEmpty &&
                !filterState.selectedPaymentMethods.contains(t.paymentMethod))
              return false;

            // C) Saat Aralığı Filtresi ("08-10" formatında stringler)
            if (filterState.selectedTimeRanges.isNotEmpty) {
              final hour = int.tryParse(t.timeStr.split(':')[0]) ?? 0;
              bool matchesTime = false;
              for (var range in filterState.selectedTimeRanges) {
                final parts = range.split('-');
                final start = int.parse(parts[0]);
                final end = int.parse(parts[1]);
                if (hour >= start && hour < end) {
                  matchesTime = true;
                  break;
                }
              }
              if (!matchesTime) return false;
            }

            // D) Tutar Filtresi (Min - Max)
            double targetAmount = 0;
            if (filterState.amountFilterType == 'TOTAL')
              targetAmount = t.finalAmount;
            else if (filterState.amountFilterType == 'PAID')
              targetAmount = t.paidAmount;
            else if (filterState.amountFilterType == 'DEBT')
              targetAmount = t.remainingAmount;

            if (filterState.minAmount != null &&
                targetAmount < filterState.minAmount!)
              return false;
            if (filterState.maxAmount != null &&
                targetAmount > filterState.maxAmount!)
              return false;

            // E) Özel Filtreler (Inflation & Note)
            if (filterState.onlyWithNote && (t.description.isEmpty))
              return false;

            if (filterState.onlyInflation) {
              // En az bir üründe zam farkı var mı?
              final hasInflation = t.items.any(
                (i) =>
                    i.paymentStatus == 'UNPAID' &&
                    i.currentPrice > i.snapshotPrice,
              );
              if (!hasInflation) return false;
            }

            return true;
          }).toList();

      // 2. SIRALAMA ADIMI
      switch (filterState.sortOption) {
        case 'date_asc':
          filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'amount_desc':
          filtered.sort((a, b) => b.finalAmount.compareTo(a.finalAmount));
          break;
        case 'amount_asc':
          filtered.sort((a, b) => a.finalAmount.compareTo(b.finalAmount));
          break;
        case 'debt_desc':
          filtered.sort(
            (a, b) => b.remainingAmount.compareTo(a.remainingAmount),
          );
          break;
        case 'date_desc':
        default:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return filtered;
    },
  );
});
