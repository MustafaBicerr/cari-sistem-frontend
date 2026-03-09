import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';

/// Barkod arama sonucu (master_drugs veya products)
class BarcodeLookupResult {
  final bool found;
  final String? source; // 'master' | 'product'
  final Map<String, dynamic>? product;
  final String? barcode;
  final String? message;

  BarcodeLookupResult({
    required this.found,
    this.source,
    this.product,
    this.barcode,
    this.message,
  });

  factory BarcodeLookupResult.fromJson(Map<String, dynamic> json) {
    return BarcodeLookupResult(
      found: json['found'] == true,
      source: json['source']?.toString(),
      product: json['product'] != null
          ? Map<String, dynamic>.from(json['product'] as Map)
          : null,
      barcode: json['barcode']?.toString(),
      message: json['message']?.toString(),
    );
  }

  bool get isTenantProduct => product?['is_tenant_product'] == true;
}

/// Barkod API servisi
class BarcodeService {
  final ApiClient _apiClient;

  BarcodeService(this._apiClient);

  Future<BarcodeLookupResult> lookupByBarcode(
    String barcode, {
    bool autoCreateTenantProduct = true,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.barcodeLookup,
        queryParameters: {
          'barcode': barcode.trim(),
          'auto_create': autoCreateTenantProduct,
        },
      );
      return BarcodeLookupResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      debugPrint('[BarcodeService] lookup error: $e');
      rethrow;
    }
  }
}
