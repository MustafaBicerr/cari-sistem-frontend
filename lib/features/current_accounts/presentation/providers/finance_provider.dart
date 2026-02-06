import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/current_accounts/data/models/repositories/finance_repository.dart';
import 'account_provider.dart'; // Listeleri yenilemek için
import 'account_detail_provider.dart'; // Detayları yenilemek için

// Repo Provider
final financeRepositoryProvider = Provider(
  (ref) => FinanceRepository(ref.read(apiClientProvider)),
);

// State: İşlem Durumu (Loading, Success, Error)
class FinanceState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  FinanceState({this.isLoading = false, this.error, this.isSuccess = false});
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  final Ref _ref;

  FinanceNotifier(this._repository, this._ref) : super(FinanceState());

  // 1. Müşteriden Tahsilat Yap
  Future<void> collectDebt({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? description,
    DateTime? date,
  }) async {
    state = FinanceState(isLoading: true);
    try {
      await _repository.collectDebt(
        customerId: customerId,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
        date: date,
      );

      state = FinanceState(isSuccess: true, isLoading: false);

      // 🔥 BAŞARILI OLUNCA VERİLERİ TAZELE
      // 1. Müşteri Listesindeki bakiyeyi güncelle
      _ref.invalidate(customerListProvider);
      // 2. Eğer o an detay sayfası açıksa, onu da güncelle
      _ref.invalidate(customerDetailProvider(customerId));
    } catch (e) {
      state = FinanceState(isLoading: false, error: e.toString());
    }
  }

  // 2. Tedarikçiye Ödeme Yap
  Future<void> paySupplier({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? description,
    DateTime? date,
  }) async {
    state = FinanceState(isLoading: true);
    try {
      await _repository.paySupplier(
        supplierId: supplierId,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
        date: date,
      );

      state = FinanceState(isSuccess: true, isLoading: false);

      // 🔥 VERİLERİ TAZELE
      _ref.invalidate(supplierListProvider);
      _ref.invalidate(supplierDetailProvider(supplierId));
    } catch (e) {
      state = FinanceState(isLoading: false, error: e.toString());
    }
  }
}

// Controller Provider
final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((
  ref,
) {
  final repo = ref.read(financeRepositoryProvider);
  return FinanceNotifier(repo, ref);
});
