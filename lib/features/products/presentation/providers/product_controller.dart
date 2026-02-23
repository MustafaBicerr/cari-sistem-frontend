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

  // 🔥 YENİLENMİŞ VE SADELEŞTİRİLMİŞ CREATE METODU
  Future<void> createProduct({
    required String name,
    required String normalizedName,
    required String barcode,
    required double
    buyingPrice, // Sadece bilgi amaçlı kaydedilir, stok maliyetini etkilemez
    required double sellingPrice,
    // initialStock kaldırıldı! Stok artık 0 başlar.
    required String unitType,
    int vatRate = 0,
    double criticalStockLevel = 10,
    Map<String, dynamic>? localDetails,
    String? vetilacImagePath,
    XFile? image,
    // SKT parametresi kaldırıldı çünkü stok girmiyoruz.
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);

      final newProduct = {
        "name": name,
        "normalized_name": normalizedName,
        "barcode": barcode,
        "buying_price": buyingPrice,
        "selling_price": sellingPrice,
        "stock_quantity": 0, // 🔥 Başlangıç stoğu her zaman 0
        "unit_type": unitType,
        "vat_rate": vatRate,
        "critical_stock_level": criticalStockLevel,
        "currency": "TRY",
        "local_details": localDetails ?? {},
      };

      // Eğer vetilac'tan gelen resim varsa ekle
      if (vetilacImagePath != null) {
        newProduct["custom_image_path"] = vetilacImagePath;
      }

      // Repo'ya gönder
      await repo.createProduct(newProduct, imageFile: image);

      // Listeyi yenile
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

  // --- STOK ve DIŞ API METODLARI ---

  Future<List<Map<String, dynamic>>> searchVetilac(String query) {
    return _ref.read(productRepositoryProvider).searchVetilac(query);
  }

  Future<Map<String, dynamic>?> getVetilacDetails(String id) {
    return _ref.read(productRepositoryProvider).getVetilacDetails(id);
  }

  Future<List<dynamic>> getProductStocks(String productId) {
    return _ref.read(productRepositoryProvider).getProductStocks(productId);
  }
}
