import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/products/presentation/providers/product_controller.dart';
import '../services/barcode_service.dart';
import '../services/barcode_repository.dart';
import '../utils/image_utils.dart';
import '../../shared/widgets/barcode_not_found_dialog.dart';

/// Barkod sonucu - API'den gelen ham veri
class BarcodeProductResult {
  final Map<String, dynamic> data;
  final bool isTenantProduct;

  BarcodeProductResult({required this.data, required this.isTenantProduct});

  String get id => data['id']?.toString() ?? '';
  String get name => data['name']?.toString() ?? '';
  String? get barcode => data['barcode']?.toString();
  double get buyingPrice => _toDouble(data['buying_price'] ?? data['buy_price']);
  double get sellingPrice => _toDouble(data['selling_price'] ?? data['sell_price']);
  int get vatRate => _toInt(data['vat_rate'] ?? data['tax_rate'], fallback: 20);
  String? get imageUrl => ImageUtils.getImageUrl(
    data['image_path']?.toString(),
    data['full_image_url']?.toString(),
  );

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}

/// Barkod tarandığında yapılacak işlem
typedef OnBarcodeProductFound = void Function(BarcodeProductResult result);
typedef OnBarcodeNotFound = void Function(String barcode);

/// Barkod işleyici - API lookup + dialog yönetimi
class BarcodeHandler {
  final BarcodeService _barcodeService;
  final ProductController _productController;

  BarcodeHandler(this._barcodeService, this._productController);

  Future<void> handleBarcode(
    BuildContext context,
    String barcode, {
    required OnBarcodeProductFound onFound,
    OnBarcodeNotFound? onNotFound,
    bool autoCreateTenantProduct = true,
  }) async {
    if (barcode.trim().isEmpty) return;

    try {
      final result = await _barcodeService.lookupByBarcode(
        barcode,
        autoCreateTenantProduct: autoCreateTenantProduct,
      );

      if (!context.mounted) return;

      if (result.found && result.product != null) {
        final p = result.product!;
        onFound(BarcodeProductResult(
          data: p,
          isTenantProduct: p['is_tenant_product'] == true,
        ));
        return;
      }

      if (result.found == false) {
        if (onNotFound != null) {
          onNotFound(result.barcode ?? barcode);
        } else {
          BarcodeNotFoundDialog.show(
            context,
            barcode: result.barcode ?? barcode,
            onAddBarcodeSuccess: () {
              _productController.invalidateProductList();
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Barkod araması başarısız: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

final barcodeHandlerProvider = Provider<BarcodeHandler>((ref) {
  return BarcodeHandler(
    ref.read(barcodeServiceProvider),
    ref.read(productControllerProvider),
  );
});