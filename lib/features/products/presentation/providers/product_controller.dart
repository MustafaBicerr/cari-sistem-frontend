import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/text_utils.dart';
import '../../domain/models/product.dart';
import 'product_provider.dart';

// Arama sorgusunu tutan state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtrelenmiş ürün listesini hesaplayan computed provider
final filteredProductListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final query = ref.watch(searchQueryProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;

    final normalizedQuery = normalizeText(query);

    return products.where((product) {
      // Backend'den normalizedName gelmezse (eski kayıtlar için) client tarafında üret
      final pName = product.normalizedName ?? normalizeText(product.name);
      final pBarcode = product.barcode ?? '';

      return pName.contains(normalizedQuery) ||
          pBarcode.contains(normalizedQuery);
    }).toList();
  });
});

final productControllerProvider = Provider((ref) => ProductController(ref));

class ProductController {
  final Ref _ref;

  ProductController(this._ref);

  Product? findProductByBarcode(String barcode) {
    final productsState = _ref.read(productListProvider);
    // AsyncValue içindeki veriye erişiyoruz (Data varsa)
    final products = productsState.asData?.value ?? [];
    try {
      return products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  void searchProducts(String query) {
    _ref.read(searchQueryProvider.notifier).state = query;
  }

  Future<void> addProduct({
    required String name,
    required String barcode,
    required double buyPrice,
    required double sellPrice,
    required double stock,
    required String unitType, // YENİ: Zorunlu (PIECE, WEIGHT, VOLUME)
    int taxRate = 0, // YENİ: Opsiyonel (Varsayılan 0)
    int lowStockLimit = 10, // Varsayılan 10 (VS Code bunu sevecek)
    XFile? image,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);

      final newProduct = {
        "name": name,
        "barcode": barcode,
        "buy_price": buyPrice,
        "sell_price": sellPrice,
        "current_stock": stock,
        "unit_type": unitType, // DB'ye gönderiyoruz
        "tax_rate": taxRate, // DB'ye gönderiyoruz
        "low_stock_limit": lowStockLimit,
      };

      await repo.createProduct(newProduct, imageFile: image);

      _ref.invalidate(productListProvider);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> deleteProduct({
    required String id,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.deleteProduct(id);
      _ref.invalidate(productListProvider);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
    XFile? image,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);
      await repo.updateProduct(id: id, updates: updates, imageFile: image);
      _ref.invalidate(productListProvider);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }
}
