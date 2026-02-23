import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/features/current_accounts/data/models/customer_model.dart';

class SaleState {
  final CustomerModel? selectedCustomer;
  final bool isAnonymous;
  final String paymentMethod;

  SaleState({
    this.selectedCustomer,
    this.isAnonymous = false,
    this.paymentMethod = 'CASH',
  });

  // 🔥 DÜZELTME BURADA: ?? this.property diyerek mevcudu koruyoruz
  SaleState copyWith({
    CustomerModel? selectedCustomer,
    bool? isAnonymous,
    String? paymentMethod,
    bool forceClearCustomer =
        false, // Müşteriyi silmek istersek bunu true yollarız
  }) {
    return SaleState(
      selectedCustomer:
          forceClearCustomer
              ? null
              : (selectedCustomer ?? this.selectedCustomer),
      isAnonymous: isAnonymous ?? this.isAnonymous,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class SaleStateNotifier extends StateNotifier<SaleState> {
  SaleStateNotifier() : super(SaleState());

  void selectCustomer(CustomerModel customer) {
    // Müşteri seçilince anonimlik kalkar
    state = state.copyWith(selectedCustomer: customer, isAnonymous: false);
  }

  void removeCustomer() {
    // Müşteriyi sil, ödeme yöntemini nakite çek
    state = state.copyWith(
      forceClearCustomer: true,
      isAnonymous: false,
      paymentMethod: 'CASH',
    );
  }

  void toggleAnonymous(bool value) {
    state = state.copyWith(
      forceClearCustomer: true, // Anonimse kayıtlı müşteriyi sil
      isAnonymous: value,
      paymentMethod:
          value && state.paymentMethod == 'DEBT' ? 'CASH' : state.paymentMethod,
    );
  }

  void setPaymentMethod(String method) {
    // Sadece ödeme yöntemini değiştir, diğerleri korunsun
    state = state.copyWith(paymentMethod: method);
  }
}

final saleStateProvider = StateNotifierProvider<SaleStateNotifier, SaleState>((
  ref,
) {
  return SaleStateNotifier();
});
