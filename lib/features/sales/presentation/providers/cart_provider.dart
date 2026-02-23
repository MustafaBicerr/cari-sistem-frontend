import 'package:flutter_riverpod/legacy.dart';
import '../widgets/sale_cart_list.dart'; // CartItem modelini buradan alıyoruz (veya domain'e taşı)

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Ürün Ekle (Varsa miktar artır, yoksa yeni ekle)
  void addItem(CartItem item) {
    final index = state.indexWhere(
      (element) => element.productId == item.productId,
    );
    if (index != -1) {
      // Ürün zaten var, miktarı güncelle (state immutable olduğu için yeni liste oluştur)
      final oldItem = state[index];
      final newItem = CartItem(
        productId: oldItem.productId,
        name: oldItem.name,
        unitPrice: oldItem.unitPrice,
        quantity: oldItem.quantity + item.quantity,
        unitType: oldItem.unitType,
      );
      final newState = [...state];
      newState[index] = newItem;
      state = newState;
    } else {
      // Yeni ürün
      state = [...state, item];
    }
  }

  void updateQuantity(int index, double newQty) {
    if (newQty <= 0) {
      removeItem(index);
      return;
    }
    final oldItem = state[index];
    final newItem = CartItem(
      productId: oldItem.productId,
      name: oldItem.name,
      unitPrice: oldItem.unitPrice,
      quantity: newQty,
      unitType: oldItem.unitType,
    );
    final newState = [...state];
    newState[index] = newItem;
    state = newState;
  }

  void removeItem(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void clearCart() {
    state = [];
  }

  double get subTotal => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
