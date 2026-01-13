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
    required String normalizedName,
    required String barcode,
    required double buyingPrice,
    required double sellingPrice,
    required double initialStock,
    required String unitType, // YENİ: Zorunlu (PIECE, WEIGHT, VOLUME)
    int vatRate = 0, // İsteğin üzerine default 0
    double criticalStockLevel = 10,
    DateTime? expirationDate, // YENİ: SKT
    Map<String, dynamic>? localDetails, // YENİ: Detaylar ve Notlar
    String? vetilacImagePath, // YENİ: Vetilac'tan gelen resim yolu
    XFile? image,
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
        // "stock_quantity": stock, // Backend create endpoint'i bunu almıyor artık
        "unit_type": unitType,
        "vat_rate": vatRate,
        "critical_stock_level": criticalStockLevel,
        "currency": "TRY",
        "local_details": localDetails ?? {},
        if (vetilacImagePath != null) "custom_image_path": vetilacImagePath,
      };

      // 1. Ürünü oluştur
      final createdProduct = await repo.createProduct(
        newProduct,
        imageFile: image,
      );

      // 2. Eğer başlangıç stoğu girildiyse, stok hareketini ekle
      if (initialStock > 0) {
        await repo.addStock(
          productId: createdProduct.id,
          quantity: initialStock,
          expirationDate:
              expirationDate ?? DateTime.now().add(const Duration(days: 365)),
          batchNo: "INIT-${DateTime.now().year}",
        );
      }

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

  // --- YENİ METODLAR ---

  Future<List<Map<String, dynamic>>> searchVetilac(String query) {
    return _ref.read(productRepositoryProvider).searchVetilac(query);
  }

  Future<Map<String, dynamic>?> getVetilacDetails(String id) {
    return _ref.read(productRepositoryProvider).getVetilacDetails(id);
  }

  Future<List<dynamic>> getProductStocks(String productId) {
    return _ref.read(productRepositoryProvider).getProductStocks(productId);
  }

  Future<List<Product>> getProductSuggestions(String pattern) async {
    final productsState = _ref.read(productListProvider);
    final products = productsState.asData?.value ?? [];
    final normalizedPattern = normalizeText(pattern);

    return products.where((product) {
      final pName = product.normalizedName ?? normalizeText(product.name);
      final pBarcode = product.barcode ?? '';
      return pName.contains(normalizedPattern) ||
          pBarcode.contains(normalizedPattern);
    }).toList();
  }
}
