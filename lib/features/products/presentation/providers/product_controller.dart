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
    required double buyingPrice,
    required double sellingPrice,
    required String unitType,
    int vatRate = 0,
    double criticalStockLevel = 10,
    // 🔥 Değişiklik: UI artık ham verileri gönderiyor, JSON'ı biz kuruyoruz
    required Map<String, dynamic> detailsMap,
    required String userNotes,
    String? vetilacImagePath,
    XFile? image,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);

      // JSON Standartlaştırması (Clean Architecture: İş mantığı buradadır)
      final standardizedLocalDetails = {
        "details": detailsMap,
        "user_notes_on_product": userNotes,
      };

      final newProduct = {
        "name": name,
        "normalized_name": normalizedName,
        "barcode": barcode,
        "buying_price": buyingPrice,
        "selling_price": sellingPrice,
        "stock_quantity": 0,
        "unit_type": unitType,
        "vat_rate": vatRate,
        "critical_stock_level": criticalStockLevel,
        "currency": "TRY",
        "local_details": standardizedLocalDetails, // Standart veri
      };

      if (vetilacImagePath != null) {
        newProduct["custom_image_path"] = vetilacImagePath;
      }

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
    required String name,
    required String normalizedName,
    required double sellingPrice,
    required String unitType,
    required int vatRate,
    required double criticalStockLevel,
    required Map<String, dynamic> detailsMap,
    required String userNotes,
    XFile? image,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      final repo = _ref.read(productRepositoryProvider);

      final standardizedLocalDetails = {
        "details": detailsMap,
        "user_notes_on_product": userNotes,
      };

      final updates = {
        "name": name,
        "normalized_name": normalizedName,
        "selling_price": sellingPrice,
        "unit_type": unitType,
        "vat_rate": vatRate,
        "critical_stock_level": criticalStockLevel,
        "local_details": standardizedLocalDetails,
      };

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
