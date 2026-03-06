import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/api/api_client.dart';
import '../../data/repositories/sales_repository.dart';
import '../../../products/presentation/providers/product_provider.dart';

// Repository Provider
final salesRepositoryProvider = Provider((ref) {
  return SalesRepository(ref.read(apiClientProvider));
});

// Controller State (AsyncValue kullanıyoruz: Loading, Error, Data durumlarını otomatik yönetir)
final salesControllerProvider =
    StateNotifierProvider<SalesController, AsyncValue<void>>((ref) {
      return SalesController(ref.read(salesRepositoryProvider), ref);
    });

class SalesController extends StateNotifier<AsyncValue<void>> {
  final SalesRepository _repository;
  final Ref _ref;

  SalesController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> submitSale(Map<String, dynamic> saleData) async {
    // 1. Loading durumuna geç
    state = const AsyncValue.loading();

    try {
      // 2. Repo'yu çağır (Yapay gecikme ekleyebiliriz istersen, şimdilik gerek yok)
      await _repository.createSale(saleData);

      // 3. Başarılı
      state = const AsyncValue.data(null);
      // _ref.invalidate(salesControllerProvider);
      _ref.invalidate(productListProvider); // Invalidate product list cache
    } catch (e, stack) {
      // 4. Hata
      state = AsyncValue.error(e, stack);
    }
  }
}
