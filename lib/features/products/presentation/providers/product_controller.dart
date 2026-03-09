import 'package:flutter/foundation.dart';
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

  Product? findProductById(String id) {
    final productsState = _ref.read(productListProvider);
    final products = productsState.asData?.value ?? [];
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void invalidateProductList() {
    _ref.invalidate(productListProvider);
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
    String? referenceImagePath,
    XFile? image,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] createProduct called\n'
        'Name: $name\n'
        'Barcode: $barcode\n'
        'Buying price: $buyingPrice\n'
        'Selling price: $sellingPrice',
      );

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

      if (referenceImagePath != null) {
        newProduct["custom_image_path"] = referenceImagePath;
      }

      await repo.createProduct(newProduct, imageFile: image);

      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] createProduct successful\n'
        'Product: $name',
      );

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
      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] deleteProduct called\n'
        'Product ID: $id',
      );

      final repo = _ref.read(productRepositoryProvider);
      await repo.deleteProduct(id);

      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] deleteProduct successful\n'
        'Deleted ID: $id',
      );

      _ref.invalidate(productListProvider);
      onSuccess();
    } catch (e) {
      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] deleteProduct ERROR\n'
        'Exception: $e',
      );
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
      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] updateProduct called\n'
        'Product ID: $id\n'
        'Name: $name\n'
        'Selling price: $sellingPrice',
      );

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

      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] updateProduct successful\n'
        'Updated ID: $id',
      );

      _ref.invalidate(productListProvider);
      onSuccess();
    } catch (e) {
      debugPrint(
        '[PRODUCT DEBUG][CONTROLLER] updateProduct ERROR\n'
        'Exception: $e',
      );
      onError(e.toString());
    }
  }

  // --- STOK ve REFERANS KATALOĞU API ---

  Future<List<Map<String, dynamic>>> searchMasterDrugs(String query) {
    return _ref.read(productRepositoryProvider).searchMasterDrugs(query);
  }

  Future<Map<String, dynamic>?> getMasterDrugDetails(String id) {
    return _ref.read(productRepositoryProvider).getMasterDrugDetails(id);
  }

  Future<List<dynamic>> getProductStocks(String productId) {
    return _ref.read(productRepositoryProvider).getProductStocks(productId);
  }
}
